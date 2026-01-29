//==============================================================================    
// Module: RD_COST  
//    
// Description:    
// Implements a 3-stage pipelined calculation of Rate-Distortion (RD) cost with    
// robust ready/valid backpressure handshaking and optimized minimum finding logic.    
//    
// C++ Reference: TComTrQuant.cpp::xGetCodedLevel() function    
// This hardware module implements the core RD cost calculation from HEVC RDOQ    
//    
// Formula: rdCost = distortion + lambda * rate    
// Reference: TComTrQuant.cpp:2855-2856    
//   Double dCurrCost = dErr * dErr * errorScale + xGetICost( xGetICRate(...) );    
//    
// Features:  
// - 3-Stage Pipeline for high throughput.  
// - Ready/Valid Handshake protocols for robust backpressure handling.  
// - Combinatorial minimum finding for improved timing.  
// - Overflow saturation protection in Stage 2.  
// - All outputs correctly aligned to Stage 3 latency.  
//    
// Latency: 3 Cycles (when downstream is ready)    
//=============================================================================  
`timescale 1ns / 1ps  
module RD_COST#(  
    parameter int NUM_CANDIDATES = 3,          // Number of quantization level candidates  
                                                                             // Limited to 2-3 as recommended in C++  
                                                                             // Reference: TComTrQuant.cpp:2852-2853  
    parameter int DISTORTION_WIDTH = 32,     // Bit-width of distortion inputs  
    parameter int RATE_WIDTH = 16,                  // Bit-width of rate inputs  
    parameter int LAMBDA_WIDTH = 32,           // Bit-width of lambda multiplier  
    parameter int COST_WIDTH = 32,                  // Bit-width of final RD cost output  
    parameter bit ENABLE_SATURATION = 1,   // 1 = Enable overflow clamping at Stage 2  
  
    // Local parameter for safe level index bit-width  
    localparam int LEVEL_WIDTH = (NUM_CANDIDATES > 1) ? $clog2(NUM_CANDIDATES) : 1,  
  
    // Internal full-precision widths  
    localparam int MULT_WIDTH = LAMBDA_WIDTH + RATE_WIDTH,  
    localparam int SUM_WIDTH = (MULT_WIDTH > DISTORTION_WIDTH ? MULT_WIDTH : DISTORTION_WIDTH) + 1  
)(  
    input  logic                      clk,  
    input  logic                      rst_n,  
  
    // Input Interface (Ready/Valid)  
    input  logic                      i_valid,           // Input data valid  
    output logic                      o_ready,       // Module ready to accept new data  
      
    // distortion[] comes from Module 6 (Distortion Calculator)  
    // Reference: TComTrQuant.cpp:2259-2260  
    //   const Double dErr = Double( lLevelDouble - ( Intermediate_Int(uiAbsLevel) << iQBits ) );  
    //   pdCostCoeff0[ iScanPos ] = dErr * dErr * errorScale;  
    input  logic [DISTORTION_WIDTH-1:0] distortion[NUM_CANDIDATES],  
      
    // rate[] comes from Module 7 (CABAC Rate Estimator)  
    // Reference: TComTrQuant.cpp:2880-2954 xGetICRate() function  
    // Estimates CABAC bits for each quantization level  
    input  logic [RATE_WIDTH-1:0]       rate[NUM_CANDIDATES],  
      
    // lambda is the RD weight parameter  
    // Reference: TComTrQuant.cpp:3002-3004 xGetICost()  
    //   return m_dLambda * dRate;  
    input  logic [LAMBDA_WIDTH-1:0]     lambda,  
  
    // Output Interface (Ready/Valid)  
    output logic                      o_valid,                                                           // Output data valid  
    input  logic                      i_ready,                                                           // Downstream ready to accept output  
    output logic [COST_WIDTH-1:0]     rd_cost[NUM_CANDIDATES],     // Individual costs  
    output logic [LEVEL_WIDTH-1:0]    best_level,                                     // Index of best candidate  
    output logic [COST_WIDTH-1:0]     best_cost                                        // Minimum cost  
);  
  
    //==========================================================================  
    // Internal Signals & Types  
    //==========================================================================  
    // Pipeline stage valid/ready signals  
    logic valid_s1, valid_s2, valid_s3;  
    logic ready_s1, ready_s2, ready_s3;  
  
    // Pipeline stage data registers  
    logic [MULT_WIDTH-1:0]       lambda_rate_s1[NUM_CANDIDATES];  
    logic [DISTORTION_WIDTH-1:0] distortion_s1[NUM_CANDIDATES];  
    logic [COST_WIDTH-1:0]       rd_cost_s2[NUM_CANDIDATES];  
  
    // Stage 3 registers (for final output alignment)  
    logic [COST_WIDTH-1:0]       rd_cost_s3[NUM_CANDIDATES];  
    logic [LEVEL_WIDTH-1:0]      best_level_s3;  
    logic [COST_WIDTH-1:0]       best_cost_s3;  
  
    // Struct for combinatorial min-finder  
    typedef struct packed {  
        logic [COST_WIDTH-1:0]  cost;  
        logic [LEVEL_WIDTH-1:0] level;  
    } candidate_t;  
  
    //==========================================================================  
    // Handshake / Pipeline Control Logic  
    //==========================================================================  
    // Standard backpressure logic: a stage is ready if the next stage is ready  
    // OR if the current stage holds invalid data.  
    assign ready_s3 = i_ready  || !valid_s3;  
    assign ready_s2 = ready_s3 || !valid_s2;  
    assign ready_s1 = ready_s2 || !valid_s1;  
  
    // Input ready status depends on Stage 1 availability  
    assign o_ready = ready_s1;  
  
    //==========================================================================  
    // Stage 1: Multiply Lambda*Rate & Delay Distortion  
    //  
    // This stage implements the lambda * rate part of the RD cost formula  
    // Reference: TComTrQuant.cpp:3002-3004 xGetICost() multiplies rate by lambda  
    // The distortion is delayed by one cycle to align with the multiplication result  
    //==========================================================================  
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin  
            valid_s1 <= 1'b0;  
            for (int i = 0; i < NUM_CANDIDATES; i++) begin  
               lambda_rate_s1[i] <= '0;  
               distortion_s1[i]  <= '0;  
            end  
        end else if (ready_s1) begin  
            // Update stage if ready. Valid propagates based on input valid.  
            valid_s1 <= i_valid;  
            if (i_valid) begin  
                for (int i = 0; i < NUM_CANDIDATES; i++) begin  
                    // 1a. Calculate rate cost component  
                    // This implements the rate weighting from xGetICost()  
                    lambda_rate_s1[i] <= lambda * rate[i];  
                      
                    // 1b. Register distortion to maintain alignment  
                    // distortion comes from Module 6 (pre-computed)  
                    distortion_s1[i]  <= distortion[i];  
                end  
            end  
        end  
    end  
  
    //==========================================================================  
    // Stage 2: Add Distortion + RateCost (with Saturation)  
    //  
    // This stage completes the RD cost calculation  
    // Reference: TComTrQuant.cpp:2855-2856  
    // Double dCurrCost = dErr * dErr * errorScale + xGetICost( xGetICRate(...) );  
    // Where xGetICost() = lambda * rate  
    //==========================================================================  
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin  
            valid_s2 <= 1'b0;  
            for (int i = 0; i < NUM_CANDIDATES; i++) rd_cost_s2[i] <= '0;  
        end else if (ready_s2) begin  
            // Update stage if ready. Valid propagates from Stage 1.  
            valid_s2 <= valid_s1;  
            if (valid_s1) begin  
                for (int i = 0; i < NUM_CANDIDATES; i++) begin  
                    logic [SUM_WIDTH-1:0] temp_sum;  
                    // Calculate full RD cost  
                    // This implements the complete RD cost formula  
                    temp_sum = distortion_s1[i] + lambda_rate_s1[i];  
  
                    // Apply saturation logic to prevent wrap-around overflow  
                    if (ENABLE_SATURATION && (temp_sum > {COST_WIDTH{1'b1}})) begin  
                        rd_cost_s2[i] <= {COST_WIDTH{1'b1}}; // Clamp to Max  
                    end else begin  
                        rd_cost_s2[i] <= temp_sum[COST_WIDTH-1:0]; // Safe truncate  
                    end  
                end  
            end  
        end  
    end  
  
    //==========================================================================  
    // Stage 3: Find Minimum Cost (Combinational + Register)  
    //  
    // This stage finds the level with minimum RD cost  
    // Reference: TComTrQuant.cpp:2851-2866 level selection loop  
    // The loop evaluates RD costs for different levels and selects minimum  
    //==========================================================================  
    candidate_t best_candidate_comb;  
  
    // --- Combinational Minimum Finder ---  
    // Uses Stage 2 results to determine the best candidate combinationally.  
    // By separating this logic into an always_comb block, synthesis tools can  
    // flatten the loop into a parallel comparator tree structure, improving  
    // timing compared to a sequential daisy-chain in the flip-flop block.  
    // This implements the level selection from xGetCodedLevel()  
    always_comb begin  
        // Initialize with the first candidate  
        best_candidate_comb.cost  = rd_cost_s2[0];  
        best_candidate_comb.level = {LEVEL_WIDTH{1'b0}};  
  
        // Iterate to find minimum (equivalent to C++ loop)  
        // Reference: TComTrQuant.cpp:2851-2866  
        for (int i = 1; i < NUM_CANDIDATES; i++) begin  
            if (rd_cost_s2[i] < best_candidate_comb.cost) begin  
                best_candidate_comb.cost  = rd_cost_s2[i];  
                best_candidate_comb.level = i[LEVEL_WIDTH-1:0];  
            end  
        end  
    end  
  
    // --- Stage 3 Register Update ---  
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin  
            valid_s3      <= 1'b0;  
            best_cost_s3  <= '0;  
            best_level_s3 <= '0;  
            for (int i = 0; i < NUM_CANDIDATES; i++) rd_cost_s3[i] <= '0;  
        end else if (ready_s3) begin  
            // Update stage if downstream is ready. Valid propagates from Stage 2.  
            valid_s3 <= valid_s2;  
            if (valid_s2) begin  
                // Latch the result of the combinational min-finder  
                best_cost_s3  <= best_candidate_comb.cost;  
                best_level_s3 <= best_candidate_comb.level;  
  
                // Explicitly register individual costs to align timing  
                for (int k = 0; k < NUM_CANDIDATES; k++) begin  
                    rd_cost_s3[k] <= rd_cost_s2[k];  
                end  
            end  
        end  
    end  
  
    //==========================================================================  
    // Output Assignments  
    //==========================================================================  
    genvar j;  
    generate  
        for (j = 0; j < NUM_CANDIDATES; j++) begin : gen_out_assign  
            // All outputs are taken from Stage 3 registers for correct timing  
            assign rd_cost[j] = rd_cost_s3[j];  
        end  
    endgenerate  
  
    // Final output valid and best candidate results from Stage 3  
    assign o_valid    = valid_s3;  
    assign best_level = best_level_s3;  
    assign best_cost  = best_cost_s3;  
endmodule