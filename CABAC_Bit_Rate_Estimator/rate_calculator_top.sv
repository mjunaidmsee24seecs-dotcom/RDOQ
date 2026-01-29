module rate_calculator_top #(
    parameter COEF_REMAIN_BIN_REDUCTION = 3,
    parameter ENABLE_CONTEXT_UPDATE = 0  // 0: static, 1: adaptive
) (
    // Global signals
    input  logic        clk,
    input  logic        rst_n,
    
    // Control signals
    input  logic        start_calc,
    output logic        calc_done,
    
    // Input data
    input  logic [15:0] uiAbsLevel,
    input  logic [15:0] ui16AbsGoRice,
    input  logic        useLimitedPrefixLength,
    input  logic [4:0]  maxLog2TrDynamicRange,
    input  logic [7:0]  c1Idx,
    input  logic [7:0]  c2Idx,
    
    // Context read addresses
    input  logic [4:0]  greaterOne_ctx_addr,
    input  logic [4:0]  levelAbs_ctx_addr,
    input  logic        read_bin_sel,
    
    // Context update interface (only used if ENABLE_CONTEXT_UPDATE=1)
    input  logic        ctx_update_en,
    input  logic [4:0]  ctx_update_addr,
    input  logic        ctx_update_type,  // 0: greaterOne, 1: levelAbs
    input  logic        ctx_update_bin,
    input  logic [2:0]  ctx_current_state,
    input  logic        ctx_current_mps,
    
    // Output
    output logic [31:0] iRate,
    
    // Debug outputs
    output logic [15:0] debug_greater_one_cost,
    output logic [15:0] debug_level_abs_cost
);

    // Internal signals
    logic sign_bit_start;
    logic sign_bit_done;
    logic [31:0] sign_bit_cost;
    
    logic level_class_start;
    logic level_class_done;
    logic [1:0] level_case;
    logic [15:0] symbol;
    logic [7:0] baseLevel;
    
    logic base_calc_start;
    logic base_calc_done;
    
    logic golomb_start;
    logic golomb_done;
    logic [7:0] suffix_length;
    logic [15:0] total_bits;
    
    logic ctx_lookup_start;
    logic ctx_lookup_done;
    logic [31:0] context_bits;
    
    logic rate_acc_start;
    logic rate_acc_done;
    
    // Context memory signals
    logic [15:0] greater_one_cost;
    logic [15:0] level_abs_cost;
    logic [15:0] greater_one_cost0, greater_one_cost1;
    logic [15:0] level_abs_cost0, level_abs_cost1;
    
    // Context update signals
    logic [2:0]  ctx_next_state;
    logic        ctx_next_mps;
    logic [15:0] ctx_updated_cost;
    logic        ctx_update_done;
    
    // Context memory write signals
    logic        greater_one_we;
    logic [7:0]  greater_one_waddr;
    logic        greater_one_wbin;
    logic [15:0] greater_one_wdata;
    
    logic        level_abs_we;
    logic [7:0]  level_abs_waddr;
    logic        level_abs_wbin;
    logic [15:0] level_abs_wdata;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE,
        CALC_SIGN_BIT,
        CALC_BASE_LEVEL,
        CLASSIFY_LEVEL,
        CALC_GOLOMB_RICE,
        LOOKUP_CONTEXT,
        ACCUMULATE_RATE,
        DONE
    } state_t;
    
    state_t current_state, next_state;
    
    // Debug assignments
    assign debug_greater_one_cost = greater_one_cost;
    assign debug_level_abs_cost = level_abs_cost;
    
    // Context memory instances
    context_bit_regfile #(
        .NUM_CTX(24),
        .CTX_TYPE(0)
    ) greater_one_mem (
        .clk(clk),
        .rst_n(rst_n),
        .we(greater_one_we),
        .ctx_addr(greater_one_waddr),
        .bin_val(greater_one_wbin),
        .bit_cost_in(greater_one_wdata),
        .read_ctx_addr(greaterOne_ctx_addr),
        .read_bin_sel(read_bin_sel),
        .bit_cost_out(greater_one_cost),
        .bit_cost_out0(greater_one_cost0),
        .bit_cost_out1(greater_one_cost1)
    );
    
    context_bit_regfile #(
        .NUM_CTX(24),
        .CTX_TYPE(1)
    ) level_abs_mem (
        .clk(clk),
        .rst_n(rst_n),
        .we(level_abs_we),
        .ctx_addr(level_abs_waddr),
        .bin_val(level_abs_wbin),
        .bit_cost_in(level_abs_wdata),
        .read_ctx_addr(levelAbs_ctx_addr),
        .read_bin_sel(read_bin_sel),
        .bit_cost_out(level_abs_cost),
        .bit_cost_out0(level_abs_cost0),
        .bit_cost_out1(level_abs_cost1)
    );
    
    // Context update instance (only generated if enabled)
    generate
    if (ENABLE_CONTEXT_UPDATE == 1) begin : GEN_CONTEXT_UPDATE
        context_update_calc ctx_update_inst (
            .clk(clk),
            .rst_n(rst_n),
            .update_start(ctx_update_en),
            .current_state(ctx_current_state),
            .current_mps(ctx_current_mps),
            .coded_bin(ctx_update_bin),
            .current_cost((ctx_update_type == 0) ? greater_one_cost : level_abs_cost),
            .next_state(ctx_next_state),
            .next_mps(ctx_next_mps),
            .updated_cost(ctx_updated_cost),
            .update_done(ctx_update_done)
        );
        
// Context update write logic - FIXED
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        greater_one_we <= 1'b0;
        level_abs_we   <= 1'b0;
        greater_one_waddr <= 8'd0;
        level_abs_waddr <= 8'd0;
        greater_one_wdata <= 16'd0;
        level_abs_wdata <= 16'd0;
        greater_one_wbin <= 1'b0;
        level_abs_wbin <= 1'b0;
    end else if (ctx_update_done) begin
        if (ctx_update_type == 0) begin
            greater_one_we     <= 1'b1;
            greater_one_waddr  <= {3'b0, ctx_update_addr};
            greater_one_wbin   <= ctx_next_mps;  // Use NEXT_MPS
            greater_one_wdata  <= ctx_updated_cost;
            level_abs_we       <= 1'b0;
        end else begin
            level_abs_we       <= 1'b1;
            level_abs_waddr    <= {3'b0, ctx_update_addr};
            level_abs_wbin     <= ctx_next_mps;  // Use NEXT_MPS
            level_abs_wdata    <= ctx_updated_cost;
            greater_one_we     <= 1'b0;
        end
    end else begin
        greater_one_we <= 1'b0;
        level_abs_we   <= 1'b0;
    end
end
    end else begin : NO_CONTEXT_UPDATE
        // Static mode - no updates
        assign ctx_update_done = 1'b0;
        assign greater_one_we = 1'b0;
        assign level_abs_we = 1'b0;
        assign greater_one_waddr = 8'd0;
        assign greater_one_wdata = 16'd0;
        assign greater_one_wbin = 1'b0;
        assign level_abs_waddr = 8'd0;
        assign level_abs_wdata = 16'd0;
        assign level_abs_wbin = 1'b0;
    end
    endgenerate
    
    // Module instances (always present)
    sign_bit_cost sign_bit_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(sign_bit_start),
        .sign_bit_cost(sign_bit_cost),
        .done(sign_bit_done)
    );
    
    base_level_calc base_level_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(base_calc_start),
        .c1Idx(c1Idx),
        .c2Idx(c2Idx),
        .baseLevel(baseLevel),
        .done(base_calc_done)
    );
    
    level_classifier level_class_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(level_class_start),
        .uiAbsLevel(uiAbsLevel),
        .baseLevel(baseLevel),
        .level_case(level_case),
        .symbol(symbol),
        .done(level_class_done)
    );
    
    golomb_rice_calc #(
        .COEF_REMAIN_BIN_REDUCTION(COEF_REMAIN_BIN_REDUCTION)
    ) golomb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(golomb_start),
        .symbol(symbol),
        .ui16AbsGoRice(ui16AbsGoRice),
        .useLimitedPrefixLength(useLimitedPrefixLength),
        .maxLog2TrDynamicRange(maxLog2TrDynamicRange),
        .suffix_length(suffix_length),
        .total_bits(total_bits),
        .done(golomb_done)
    );
    
    context_bit_lookup ctx_lookup_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(ctx_lookup_start),
        .level_case(level_case),
        .c1Idx(c1Idx),
        .c2Idx(c2Idx),
        .greater_one_cost(greater_one_cost),
        .level_abs_cost(level_abs_cost),
        .context_bits(context_bits),
        .done(ctx_lookup_done)
    );
    
    rate_accumulator rate_acc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(rate_acc_start),
        .sign_bit_cost(sign_bit_cost),
        .suffix_bits({16'd0, total_bits}),
        .context_bits(context_bits),
        .level_case(level_case),
        .iRate(iRate),
        .done(rate_acc_done)
    );
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        sign_bit_start = 1'b0;
        base_calc_start = 1'b0;
        level_class_start = 1'b0;
        golomb_start = 1'b0;
        ctx_lookup_start = 1'b0;
        rate_acc_start = 1'b0;
        calc_done = 1'b0;
        
        case (current_state)
            IDLE: begin
                if (start_calc) begin
                    next_state = CALC_SIGN_BIT;
                end
            end
            
            CALC_SIGN_BIT: begin
                sign_bit_start = 1'b1;
                if (sign_bit_done) begin
                    next_state = CALC_BASE_LEVEL;
                end
            end
            
            CALC_BASE_LEVEL: begin
                base_calc_start = 1'b1;
                if (base_calc_done) begin
                    next_state = CLASSIFY_LEVEL;
                end
            end
            
            CLASSIFY_LEVEL: begin
                level_class_start = 1'b1;
                if (level_class_done) begin
                    if (level_case == 2'd0) begin
                        next_state = ACCUMULATE_RATE;
                    end else begin
                        next_state = CALC_GOLOMB_RICE;
                    end
                end
            end
            
            CALC_GOLOMB_RICE: begin
                golomb_start = 1'b1;
                if (golomb_done) begin
                    next_state = LOOKUP_CONTEXT;
                end
            end
            
            LOOKUP_CONTEXT: begin
                ctx_lookup_start = 1'b1;
                if (ctx_lookup_done) begin
                    next_state = ACCUMULATE_RATE;
                end
            end
            
            ACCUMULATE_RATE: begin
                rate_acc_start = 1'b1;
                if (rate_acc_done) begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                calc_done = 1'b1;
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule