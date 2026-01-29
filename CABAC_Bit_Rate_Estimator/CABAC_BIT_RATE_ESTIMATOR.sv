// ============================================================================
// CABAC Bit Rate Estimator - DEBUG Top Module
// ============================================================================
module cabac_bit_estimator_top_debug (
    // Global Signals
    input  logic        clk,
    input  logic        rst_n,
    
    // Estimation Inputs
    input  logic        est_start,
    input  logic [15:0] uiAbsLevel,
    input  logic [15:0] ui16CtxNumOne,
    input  logic [15:0] ui16CtxNumAbs,
    input  logic [15:0] ui16AbsGoRice,
    input  logic [7:0]  c1Idx,
    input  logic [7:0]  c2Idx,
    input  logic        useLimitedPrefixLength,
    input  logic [4:0]  maxLog2TrDynamicRange,
    
    // Outputs
    output logic [31:0] iRate,
    output logic        est_done,
    
    // Debug outputs
    output logic [7:0]  dbg_baseLevel,
    output logic [1:0]  dbg_level_case,
    output logic [15:0] dbg_symbol,
    output logic        dbg_m1_done,
    output logic        dbg_m2_done,
    output logic        dbg_m3_done,
    output logic        dbg_m4_done,
    output logic        dbg_m5_done,
    output logic        dbg_m6_done,
    output logic        dbg_all_done
);

    // ============================================
    // Internal Signals
    // ============================================
    logic [7:0]  baseLevel;
    logic [1:0]  level_case;
    logic [15:0] symbol;
    logic [15:0] total_bits;
    logic [31:0] context_bits;
    logic [31:0] sign_bit_cost;
    
    logic [15:0] greater_one_cost, level_abs_cost;
    
    // Module done signals
    logic m1_done, m2_done, m3_done, m4_done, m5_done, m6_done;
    
    // ============================================
    // Module 1: Base Level Calculator
    // ============================================
    base_level_calc m1 (
        .clk(clk),
        .rst_n(rst_n),
        .start(est_start),
        .c1Idx(c1Idx),
        .c2Idx(c2Idx),
        .baseLevel(baseLevel),
        .done(m1_done)
    );
    
    assign dbg_baseLevel = baseLevel;
    assign dbg_m1_done = m1_done;
    
    // ============================================
    // Module 2: Level Classifier
    // ============================================
    level_classifier m2 (
        .clk(clk),
        .rst_n(rst_n),
        .start(m1_done),
        .uiAbsLevel(uiAbsLevel),
        .baseLevel(baseLevel),
        .level_case(level_case),
        .symbol(symbol),
        .done(m2_done)
    );
    
    assign dbg_level_case = level_case;
    assign dbg_symbol = symbol;
    assign dbg_m2_done = m2_done;
    
    // ============================================
    // Module 3: Golomb-Rice Calculator
    // ============================================
    golomb_rice_calc m3 (
        .clk(clk),
        .rst_n(rst_n),
        .start(m2_done && (level_case == 2'd3)),
        .symbol(symbol),
        .ui16AbsGoRice(ui16AbsGoRice),
        .useLimitedPrefixLength(useLimitedPrefixLength),
        .maxLog2TrDynamicRange(maxLog2TrDynamicRange),
        .suffix_length(),
        .total_bits(total_bits),
        .done(m3_done)
    );
    
    assign dbg_m3_done = m3_done;
    
    // ============================================
    // Module 4: Context Bit Lookup
    // ============================================
    context_bit_lookup m4 (
        .clk(clk),
        .rst_n(rst_n),
        .start(m2_done),
        .level_case(level_case),
        .c1Idx(c1Idx),
        .c2Idx(c2Idx),
        .greater_one_cost(greater_one_cost),
        .level_abs_cost(level_abs_cost),
        .context_bits(context_bits),
        .done(m4_done)
    );
    
    assign dbg_m4_done = m4_done;
    
    // ============================================
    // Module 5: Sign Bit Cost
    // ============================================
    sign_bit_cost m5 (
        .clk(clk),
        .rst_n(rst_n),
        .start(est_start),
        .sign_bit_cost(sign_bit_cost),
        .done(m5_done)
    );
    
    assign dbg_m5_done = m5_done;
    
    // ============================================
    // Simplified Context RF for debug
    // ============================================
    // Use fixed values for debugging
    assign greater_one_cost = 16'h2000;  // Fixed value for debug
    assign level_abs_cost = 16'h2500;    // Fixed value for debug
    
    // ============================================
    // Wait for all parallel modules to complete
    // ============================================
    logic all_modules_done;
    
    // Handle case when m3 is not needed (not BASEPLUS)
    logic m3_needed_done;
    assign m3_needed_done = (level_case == 2'd3) ? m3_done : 1'b1;
    
    assign all_modules_done = m3_needed_done && m4_done && m5_done;
    assign dbg_all_done = all_modules_done;
    
    // ============================================
    // Module 6: Rate Accumulator
    // ============================================
    rate_accumulator m6 (
        .clk(clk),
        .rst_n(rst_n),
        .start(all_modules_done),
        .sign_bit_cost(sign_bit_cost),
        .suffix_bits({total_bits, 15'b0}),
        .context_bits(context_bits),
        .level_case(level_case),
        .iRate(iRate),
        .done(m6_done)
    );
    
    assign dbg_m6_done = m6_done;
    assign est_done = m6_done;

endmodule