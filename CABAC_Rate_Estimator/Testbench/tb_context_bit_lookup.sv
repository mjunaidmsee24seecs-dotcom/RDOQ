`timescale 1ns/1ps

module tb_context_bit_lookup;

    logic        clk;
    logic        rst_n;
    logic        start;
    logic [1:0]  level_case;
    logic [7:0]  c1Idx;
    logic [7:0]  c2Idx;
    logic [15:0] greater_one_cost;
    logic [15:0] level_abs_cost;
    logic [31:0] context_bits;
    logic        done;

    // DUT
    context_bit_lookup dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .level_case(level_case),
        .c1Idx(c1Idx),
        .c2Idx(c2Idx),
        .greater_one_cost(greater_one_cost),
        .level_abs_cost(level_abs_cost),
        .context_bits(context_bits),
        .done(done)
    );

    // 10ns clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        level_case = 0;
        c1Idx = 0;
        c2Idx = 0;
        greater_one_cost = 0;
        level_abs_cost = 0;

        // =============================
        // RESET
        // =============================
        #20 rst_n = 1;

        // =============================
        // NORMAL FUNCTIONAL TESTS
        // =============================

        // TEST 1: LEVEL = 1
        #10;
        start = 1;
        level_case = 2'd1;
        greater_one_cost = 16'd100;
        #10 start = 0;
        #10 $display("ONE: context_bits = %0d (Expected 100)", context_bits);

        // TEST 2: LEVEL = 2
        #10;
        start = 1;
        level_case = 2'd2;
        greater_one_cost = 16'd120;
        level_abs_cost = 16'd80;
        #10 start = 0;
        #10 $display("TWO: context_bits = %0d (Expected 200)", context_bits);

        // TEST 3: BASEPLUS (both active)
        #10;
        start = 1;
        level_case = 2'd3;
        c1Idx = 5;
        c2Idx = 0;
        greater_one_cost = 16'd50;
        level_abs_cost = 16'd30;
        #10 start = 0;
        #10 $display("BASEPLUS (both): context_bits = %0d (Expected 80)", context_bits);

        // TEST 4: ZERO
        #10;
        start = 1;
        level_case = 2'd0;
        #10 start = 0;
        #10 $display("ZERO: context_bits = %0d (Expected 0)", context_bits);

        // =============================
        // ? CORNER CASE TESTS
        // =============================

        // TEST 5: BASEPLUS but c1Idx >= 8 (should be ZERO)
        #10;
        start = 1;
        level_case = 2'd3;
        c1Idx = 8;     // BLOCK greaterOne
        c2Idx = 0;
        greater_one_cost = 16'd60;
        level_abs_cost   = 16'd40;
        #10 start = 0;
        #10 $display("BASEPLUS c1Idx>=8: context_bits = %0d (Expected 0)", context_bits);

        // TEST 6: BASEPLUS but c2Idx >= 1 (only greaterOne should apply)
        #10;
        start = 1;
        level_case = 2'd3;
        c1Idx = 4;
        c2Idx = 2;     // BLOCK levelAbs
        greater_one_cost = 16'd90;
        level_abs_cost   = 16'd50;
        #10 start = 0;
        #10 $display("BASEPLUS c2Idx>=1: context_bits = %0d (Expected 90)", context_bits);

        // TEST 7: MAX VALUE OVERFLOW CHECK
        #10;
        start = 1;
        level_case = 2'd2;
        greater_one_cost = 16'hFFFF;
        level_abs_cost   = 16'h0001;
        #10 start = 0;
        #10 $display("MAX VALUE SUM: context_bits = %h (Expected 1_0000)", context_bits);

        // TEST 8: BACK-TO-BACK START PULSES
        #10;
        start = 1;
        level_case = 2'd1;
        greater_one_cost = 16'd25;
        #10;

        start = 1;
        greater_one_cost = 16'd35;
        #10 start = 0;

        #10 $display("BACK-TO-BACK START: context_bits = %0d (Expected 35)", context_bits);

        // TEST 9: START HELD HIGH MULTIPLE CYCLES
        #10;
        start = 1;
        level_case = 2'd2;
        greater_one_cost = 16'd40;
        level_abs_cost = 16'd60;
        #30 start = 0;
        #10 $display("START HELD HIGH: context_bits = %0d (Expected 100)", context_bits);

        // TEST 10: RESET DURING ACTIVE OPERATION
        #10;
        start = 1;
        level_case = 2'd1;
        greater_one_cost = 16'd77;
        #5 rst_n = 0;   // ASYNC RESET
        #10 rst_n = 1;
        start = 0;
        #10 $display("RESET DURING ACTIVE: context_bits = %0d (Expected 0)", context_bits);

        // =============================
        // END
        // =============================
        #20;
        $display("---- ALL CORNER & NORMAL TESTS COMPLETED ----");
        $stop;
    end

endmodule
