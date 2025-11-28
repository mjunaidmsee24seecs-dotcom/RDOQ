`timescale 1ns / 1ps
module tb_Dist_Cal;
// Parameters
    localparam int LEVEL_WIDTH     = 64;
    localparam int ABS_LEVEL_WIDTH = 32;
    localparam int QBITS_WIDTH     = 6;
    localparam int SCALE_WIDTH     = 32;
    localparam int OUT_WIDTH       = 162;

    // Signals
    logic                        clk;
    logic                        rst_n;
    logic                        data_valid_in;
    logic [LEVEL_WIDTH-1:0]      l_level_double;
    logic [ABS_LEVEL_WIDTH-1:0]  ui_abs_level;
    logic [QBITS_WIDTH-1:0]      i_q_bits;
    logic [SCALE_WIDTH-1:0]      error_scale;
    
    logic                        data_valid_out;
    logic [OUT_WIDTH-1:0]        distortion_out;

    // DUT Instance
    // Note: Ensure your DUT module name matches 'Dist_Cal' or 'rdoq_distortion_calc'
    Dist_Cal #(
        .LEVEL_WIDTH(LEVEL_WIDTH),
        .ABS_LEVEL_WIDTH(ABS_LEVEL_WIDTH),
        .QBITS_WIDTH(QBITS_WIDTH),
        .SCALE_WIDTH(SCALE_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(data_valid_in),
        .l_level_double(l_level_double),
        .ui_abs_level(ui_abs_level),
        .i_q_bits(i_q_bits),
        .error_scale(error_scale),
        .data_valid_out(data_valid_out),
        .distortion_out(distortion_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // Test Procedure
    initial begin
        // Initialize
        rst_n = 0;
        data_valid_in = 0;
        l_level_double = 0;
        ui_abs_level = 0;
        i_q_bits = 0;
        error_scale = 0;

        // Reset
        #20;
        rst_n = 1;
        #10;

        // ------------------------------------------------------------
        // Test Case 1: Simple Calculation
        // Result: 2,381,440
        // ------------------------------------------------------------
        @(posedge clk);
        data_valid_in  <= 1;
        l_level_double <= 64'd1000;
        ui_abs_level   <= 32'd2;
        i_q_bits       <= 6'd8;
        error_scale    <= 32'd10;

        // ------------------------------------------------------------
        // Test Case 2: Negative Difference (Intermediate)
        // Result: 12,544
        // ------------------------------------------------------------
        @(posedge clk);
        l_level_double <= 64'd400;
        ui_abs_level   <= 32'd2;
        i_q_bits       <= 6'd8;
        error_scale    <= 32'd1;

        // ------------------------------------------------------------
        // Test Case 3: Max Shift (Boundary Condition)
        // Reconstructed = 1 << 63. This is 2^63.
        // This fits in a 64-bit unsigned number (MSB is 1).
        // It does NOT trigger the >64-bit clamp.
        // Result should be approx (1000 - 2^63)^2.
        // ------------------------------------------------------------
        @(posedge clk);
        l_level_double <= 64'd1000;
        ui_abs_level   <= 32'd1;
        i_q_bits       <= 6'd63;
        error_scale    <= 32'd1;

        // ------------------------------------------------------------
        // NEW Test Case 4: Forced Overflow & Clamping
        // We want the shifted value to exceed 64 bits.
        // ui_abs_level = 4 (binary 100)
        // i_q_bits = 62
        // Shift: (100) << 62.
        // The '1' bit will end up at position 62 + 2 = 64.
        // Since bit 64 is outside the [63:0] range, clamping MUST trigger.
        // Reconstructed should become MAX_VAL (all 1s).
        // l_level = 0.
        // Diff = 0 - MAX_VAL = -MAX_VAL.
        // Dist = (-MAX_VAL)^2 * 1 = MAX_VAL^2.
        // ------------------------------------------------------------
        @(posedge clk);
        l_level_double <= 64'd0;    // Use 0 to maximize the difference
        ui_abs_level   <= 32'd4;    // Binary ...100
        i_q_bits       <= 6'd62;    // Shift so the '1' lands at bit 64
        error_scale    <= 32'd1;
        
        // End Input
        @(posedge clk);
        data_valid_in <= 0;

        // Wait for pipeline to drain (3 cycles latency)
        #50;
        
        $finish;
    end

    // Monitor
    always @(posedge clk) begin
        if (data_valid_out) begin
            $display("Time: %0t | Output Distortion: %0d", $time, distortion_out);
        end
    end

endmodule