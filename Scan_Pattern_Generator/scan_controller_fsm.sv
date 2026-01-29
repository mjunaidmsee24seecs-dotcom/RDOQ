//==============================================================================
// Module: scan_controller_fsm
// Description: Main FSM controller for scan pattern generation
//==============================================================================

module scan_controller_fsm (
    // Global signals
    input  logic        clk,
    input  logic        rst_n,

    // Control inputs
    input  logic        start,
    input  logic [2:0]  log2BlockWidth,
    input  logic [2:0]  log2BlockHeight,
    input  logic [1:0]  scanType,

    // Outputs
    output logic        scan_valid,
    output logic        done,
    output logic [9:0]  scan_position,
    output logic        update_position
);

    // State definitions
    typedef enum logic [2:0] {
        IDLE,
        INIT,
        OUTPUT_SCAN,
        DONE
    } state_t;

    state_t current_state, next_state;

    // Internal registers
    logic [9:0] scan_pos_reg;
    logic [9:0] block_size_reg;
    logic [2:0] log2width_reg;
    logic [2:0] log2height_reg;
    logic [1:0] scan_type_reg;

    // Internal signal for scan completion
    logic scan_complete;

    // Block size calculation
    always_comb begin
        block_size_reg = (1 << log2width_reg) * (1 << log2height_reg);
    end

    // State register and counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            scan_pos_reg <= '0;
            log2width_reg <= '0;
            log2height_reg <= '0;
            scan_type_reg <= '0;
        end else begin
            current_state <= next_state;

            // Update position counter
            if (update_position) begin
                if (scan_pos_reg < block_size_reg - 1) begin
                    scan_pos_reg <= scan_pos_reg + 1;
                end
            end

            // Capture parameters on start
            if (start && current_state == IDLE) begin
                log2width_reg <= log2BlockWidth;
                log2height_reg <= log2BlockHeight;
                scan_type_reg <= scanType;
                scan_pos_reg <= '0;
            end

            // Reset position when entering INIT
            if (current_state == INIT) begin
                scan_pos_reg <= '0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = INIT;
                end
            end

            INIT: begin
                next_state = OUTPUT_SCAN;
            end

            OUTPUT_SCAN: begin
                if (scan_complete) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                if (!start) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // Output logic
    assign scan_valid     = (current_state == OUTPUT_SCAN);
    assign done           = (current_state == DONE);
    assign scan_position  = scan_pos_reg;
    assign update_position = (current_state == OUTPUT_SCAN);
    assign scan_complete  = (scan_pos_reg >= block_size_reg - 1);

endmodule
