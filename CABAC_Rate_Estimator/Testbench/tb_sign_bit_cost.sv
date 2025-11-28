`timescale 1ns/1ps

module tb_sign_bit_cost;

    // Parameters
    localparam IEP_RATE_TB = 16'h8000; // 32768 decimal

    // Signals
    logic clk;
    logic rst_n;
    logic start;
    logic [31:0] sign_bit_cost;
    logic done;

    // DUT
    sign_bit_cost #(
        .IEP_RATE(IEP_RATE_TB)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .sign_bit_cost(sign_bit_cost),
        .done(done)
    );

    // Clock: 10ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;

        #20 rst_n = 1; // release reset
        #10;

        // =============================
        // TEST 1: RESET
        // =============================
        start = 0;
        #10;
        $display("After reset: sign_bit_cost=%0d, done=%b (Expected 0,0)", sign_bit_cost, done);

        // =============================
        // TEST 2: SINGLE START PULSE
        // =============================
        start = 0;
        #10;
        start = 1; // clean rising edge
        #10;
        start = 0;
        #5;
        $display("Single start: sign_bit_cost=%0d, done=%b (Expected %0d,1)", sign_bit_cost, done, IEP_RATE_TB);

        // =============================
        // TEST 3: IDLE AFTER START
        // =============================
        #10;
        $display("Idle after start: sign_bit_cost=%0d, done=%b (Expected %0d,0)", sign_bit_cost, done, IEP_RATE_TB);

        // =============================
        // TEST 4: BACK-TO-BACK START PULSES
        // =============================
        // Pulse 1
        start = 0;
        #10;
        start = 1;
        #10;
        start = 0;
        #5;
        $display("Back-to-back start 1st pulse: sign_bit_cost=%0d, done=%b (Expected %0d,1)", sign_bit_cost, done, IEP_RATE_TB);

        // Pulse 2
        #10;
        start = 0;
        #5;
        start = 1;
        #10;
        start = 0;
        #5;
        $display("Back-to-back start 2nd pulse: sign_bit_cost=%0d, done=%b (Expected %0d,1)", sign_bit_cost, done, IEP_RATE_TB);

        // =============================
        // TEST 5: START HELD HIGH MULTIPLE CYCLES
        // =============================
        #10;
        start = 0;
        #5;
        start = 1; // rising edge triggers done
        #30;
        start = 0;
        #5;
        $display("Start held high multiple cycles: sign_bit_cost=%0d, done=%b (Expected %0d,1)", sign_bit_cost, done, IEP_RATE_TB);

        // =============================
        // TEST 6: RESET DURING ACTIVE
        // =============================
        #10;
        start = 0;
        #5;
        start = 1;
        #5 rst_n = 0; // async reset
        #10 rst_n = 1;
        start = 0;
        #5;
        $display("Reset during active: sign_bit_cost=%0d, done=%b (Expected 0,0)", sign_bit_cost, done);

        // =============================
        #20;
        $display("---- ALL TESTS COMPLETED ----");
        $stop;
    end

endmodule
