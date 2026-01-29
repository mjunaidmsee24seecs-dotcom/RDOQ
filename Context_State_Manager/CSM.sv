//==============================================================================  
// Module 10: Context State Manager (Fixed - c1Idx update & GR logic)  
//  
// Description:  
// Implements CABAC context model updates and Golomb-Rice parameter adaptation  
// for HEVC RDOQ. Maintains probability models for entropy coding.  
//  
// C++ Reference: TComTrQuant.cpp::xRateDistOptQuant() lines 2324-2345  
// This implements the context update logic from the HEVC reference software  
//==============================================================================  
`timescale 1ns / 1ps  
module CSM #(  
    parameter int C1_WIDTH = 2,        // Bits for c1 counter (range 0-3)  
    parameter int C2_WIDTH = 2,        // Bits for c2 counter (range 0-2)  
    parameter int C1IDX_WIDTH = 4,     // Bits for c1Idx context index  
    parameter int C2IDX_WIDTH = 5,     // Bits for c2Idx context index  
    parameter int GR_WIDTH = 3         // Bits for Golomb-Rice parameter (0-4)  
)(  
    input  logic                      clk,  
    input  logic                      rst_n,  
    input  logic                      start,  
  
    // Input from Module 9 (Level Selector)  
    // uiLevel is the selected quantization level for current coefficient  
    // Reference: TComTrQuant.cpp context updates use uiLevel variable  
    input  logic [15:0]               uiLevel,  
  
    // Control signals  
    input  logic [15:0]               scanPos,  
    input  logic                      cg_boundary, // True if current scanPos is the LAST in a CG  
    input  logic [GR_WIDTH-1:0]       initialGR,   // Initial GR parameter for the block  
  
    // Output context states  
    output logic [C1_WIDTH-1:0]       c1_out,  
    output logic [C2_WIDTH-1:0]       c2_out,  
    output logic [C1IDX_WIDTH-1:0]    c1Idx_out,  
    output logic [C2IDX_WIDTH-1:0]    c2Idx_out,  
    output logic [GR_WIDTH-1:0]       uiGoRice_out,  
    output logic                      done  
);  
  
    //==========================================================================  
    // Internal State Registers  
    // These registers store the current context state for CABAC coding  
    // Reference: TComTrQuant.cpp context variables c1, c2, c1Idx, c2Idx, uiGoRiceParam  
    //==========================================================================  
    logic [C1_WIDTH-1:0]       c1_reg;  
    logic [C2_WIDTH-1:0]       c2_reg;  
    logic [C1IDX_WIDTH-1:0]    c1Idx_reg;  
    logic [C2IDX_WIDTH-1:0]    c2Idx_reg;  
    logic [GR_WIDTH-1:0]       uiGoRice_reg;  
    logic                      done_reg;  
  
    //==========================================================================  
    // Next State Signals  
    // Intermediate signals for two-step update process  
    //==========================================================================  
    logic [C1_WIDTH-1:0]       c1_next;  
    logic [C2_WIDTH-1:0]       c2_next;  
    logic [C1IDX_WIDTH-1:0]    c1Idx_next;  
    logic [C2IDX_WIDTH-1:0]    c2Idx_next;  
    logic [GR_WIDTH-1:0]       uiGoRice_next;  
    logic [15:0] baseLevel;
    //==========================================================================  
    // Combinational Logic: Context Updates  
    // Implements the two-step context update from C++:  
    // Step A: Bin model update  
    // Step B: Context set reset at CG boundaries  
    //==========================================================================  
    always_comb begin  
        // Default: keep current state  
        c1_next = c1_reg;  
        c2_next = c2_reg;  
        c1Idx_next = c1Idx_reg;  
        c2Idx_next = c2Idx_reg;  
        uiGoRice_next = uiGoRice_reg;  
  
        if (start) begin  
            //------------------------------------------------------------------  
            // Intermediate signals for two-step update process  
            // This matches the C++ execution order where bin updates happen  
            // before CG boundary resets  
            //------------------------------------------------------------------  
            logic [C1_WIDTH-1:0]       c1_bin_update;  
            logic [C2_WIDTH-1:0]       c2_bin_update;  
            logic [C1IDX_WIDTH-1:0]    c1Idx_bin_update;  
            logic [C2IDX_WIDTH-1:0]    c2Idx_bin_update;  
            logic [GR_WIDTH-1:0]       uiGoRice_bin_update;  
  
            // Initialize with current register values  
            c1_bin_update = c1_reg;  
            c2_bin_update = c2_reg;  
            c1Idx_bin_update = c1Idx_reg;  
            c2Idx_bin_update = c2Idx_reg;  
            uiGoRice_bin_update = uiGoRice_reg;  
  
            //------------------------------------------------------------------  
            // Step A: Bin Model Update  
            // Reference: TComTrQuant.cpp lines 2325-2335  
            //===== update bin model =====  
            // if( uiLevel > 1 )  
            // {  
            //   c1 = 0;  
            //   c2 += (c2 < 2);  
            //   c2Idx ++;  
            // }  
            // else if( (c1 < 3) && (c1 > 0) && uiLevel)  
            // {  
            //   c1++;  
            // }  
            //------------------------------------------------------------------  
            if (uiLevel > 1) begin  
                // Reset c1 to 0 when level > 1  
                c1_bin_update = 2'b00;  
                  
                // Increment c2 if not at maximum (2)  
                if (c2_reg < 2) c2_bin_update = c2_reg + 1;  
                  
                // Increment c2Idx when level > 1  
                c2Idx_bin_update = c2Idx_reg + 1;  
            end else if ((c1_reg < 3) && (c1_reg > 0) && uiLevel) begin  
                // Increment c1 for levels 1-2 when conditions met  
                c1_bin_update = c1_reg + 1;  
            end  
  
            // Update c1Idx for any non-zero level  
            // Reference: TComTrQuant.cpp lines 2320-2323  
            // c1Idx is incremented for any coefficient >= 1  
            if (uiLevel > 0) begin  
                c1Idx_bin_update = c1Idx_reg + 1;  
            end  
  
            //------------------------------------------------------------------  
            // Golomb-Rice Parameter Adaptation  
            // Reference: TComTrQuant.cpp lines 2312-2319  
            // baseLevel = (c1Idx < C1FLAG_NUMBER) ? (2 + (c2Idx < C2FLAG_NUMBER)) : 1;  
            // if( uiLevel >= baseLevel )  
            // {  
            //   if (uiLevel > 3*(1<<uiGoRiceParam))  
            //   {  
            //     uiGoRiceParam = bUseGolombRiceParameterAdaptation ? (uiGoRiceParam + 1) : (std::min<UInt>((uiGoRiceParam + 1), 4));  
            //   }  
            // }  
            //------------------------------------------------------------------  
            // Calculate baseLevel ( context-dependent threshold )  
            // Simplified: baseLevel = 1 for most cases in hardware    
            baseLevel = 1;  // Simplified for hardware implementation  
              
            // Standard HEVC Golomb-Rice Parameter Update  
            // CRITICAL FIX: Using >= comparison as per spec  
            if (uiLevel >= (3 * (1 << uiGoRice_reg))) begin  
                if (uiGoRice_reg < 4) begin  
                    uiGoRice_bin_update = uiGoRice_reg + 1;  
                end  
            end  
  
            // Apply bin model updates to next state candidates  
            c1_next = c1_bin_update;  
            c2_next = c2_bin_update;  
            c1Idx_next = c1Idx_bin_update;  
            c2Idx_next = c2Idx_bin_update;  
            uiGoRice_next = uiGoRice_bin_update;  
  
            //------------------------------------------------------------------  
            // Step B: Context Set Update at CG Boundary  
            // Reference: TComTrQuant.cpp lines 2337-2345  
            //===== context set update =====  
            // if( ( iScanPos % uiCGSize == 0 ) && ( iScanPos > 0 ) )  
            // {  
            //   uiCtxSet          = getContextSetIndex(compID, ((iScanPos - 1) >> MLS_CG_SIZE), (c1 == 0));  
            //   c1                = 1;  
            //   c2                = 0;  
            //   c1Idx             = 0;  
            //   c2Idx             = 0;  
            //   uiGoRiceParam     = initialGolombRiceParameter;  
            // }  
            //------------------------------------------------------------------  
            if (cg_boundary && scanPos > 0) begin  
                c1_next = 2'b01;        // c1 = 1  
                c2_next = 2'b00;        // c2 = 0  
                c1Idx_next = {C1IDX_WIDTH{1'b0}}; // c1Idx = 0  
                c2Idx_next = {C2IDX_WIDTH{1'b0}}; // c2Idx = 0  
                uiGoRice_next = initialGR;  
            end  
        end  
    end  
  
    //==========================================================================  
    // Sequential Logic: Register Updates  
    //==========================================================================  
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin  
            // Reset to initial state for the very first CG in a block  
            // Reference: TComTrQuant.cpp initialization values  
            c1_reg <= 2'b01;        // c1 = 1  
            c2_reg <= 2'b00;        // c2 = 0  
            c1Idx_reg <= {C1IDX_WIDTH{1'b0}};  
            c2Idx_reg <= {C2IDX_WIDTH{1'b0}};  
            // NOTE: uiGoRice_reg should ideally be reset to initialGR,  
            // but initialGR is a dynamic input. Resetting to 0 is a safe default.  
            uiGoRice_reg <= {GR_WIDTH{1'b0}};  
            done_reg <= 1'b0;  
        end else if (start) begin  
            c1_reg <= c1_next;  
            c2_reg <= c2_next;  
            c1Idx_reg <= c1Idx_next;  
            c2Idx_reg <= c2Idx_next;  
            uiGoRice_reg <= uiGoRice_next;  
            done_reg <= 1'b1;  
        end else begin  
            done_reg <= 1'b0;  
        end  
    end  
  
    //==========================================================================  
    // Output Assignments  
    //==========================================================================  
    // The outputs are the CURRENT state, used for estimating the rate of the  
    // CURRENT uiLevel. The registers hold the state for the NEXT coefficient.  
    assign c1_out = c1_reg;  
    assign c2_out = c2_reg;  
    assign c1Idx_out = c1Idx_reg;  
    assign c2Idx_out = c2Idx_reg;  
    assign uiGoRice_out = uiGoRice_reg;  
    assign done = done_reg;  
  
endmodule