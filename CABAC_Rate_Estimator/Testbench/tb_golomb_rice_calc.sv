`timescale 1ns/1ps
module tb_golomb_rice_calc;

    logic clk;
    logic rst_n;
    logic start;
    logic [15:0] symbol;
    logic [15:0] ui16AbsGoRice;
    logic useLimitedPrefixLength;
    logic [4:0] maxLog2TrDynamicRange;
    logic [7:0] suffix_length;
    logic [15:0] total_bits;
    logic done;

    // Instantiate DUT
    golomb_rice_calc dut(
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .symbol(symbol),
        .ui16AbsGoRice(ui16AbsGoRice),
        .useLimitedPrefixLength(useLimitedPrefixLength),
        .maxLog2TrDynamicRange(maxLog2TrDynamicRange),
        .suffix_length(suffix_length),
        .total_bits(total_bits),
        .done(done)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst_n = 0;
        start = 0;
        symbol = 0;
        ui16AbsGoRice = 0;
        useLimitedPrefixLength = 0;
        maxLog2TrDynamicRange = 0;

        #20 rst_n = 1;

        // ----------------- Test Case 1: SHORT -----------------
        @(posedge clk);
        symbol = 4; ui16AbsGoRice=1; useLimitedPrefixLength=0; maxLog2TrDynamicRange=10;
        start = 1; @(posedge clk); start = 0;
        @(posedge clk);
        $display("TC1 SHORT -> suffix=%0d total_bits=%0d done=%0b", suffix_length, total_bits, done);

        // ----------------- Test Case 2: LIMITED -----------------
        @(posedge clk);
        symbol = 40; ui16AbsGoRice=2; useLimitedPrefixLength=1; maxLog2TrDynamicRange=10;
        start = 1; @(posedge clk); start = 0;
        @(posedge clk);
        $display("TC2 LIMITED -> suffix=%0d total_bits=%0d done=%0b", suffix_length, total_bits, done);

        // ----------------- Test Case 3: UNLIMITED -----------------
        @(posedge clk);
        symbol = 50; ui16AbsGoRice=2; useLimitedPrefixLength=0; maxLog2TrDynamicRange=10;
        start = 1; @(posedge clk); start = 0;
        @(posedge clk);
        $display("TC3 UNLIMITED -> suffix=%0d total_bits=%0d done=%0b", suffix_length, total_bits, done);

        #20 $display("? GOLOMB RICE TEST COMPLETED");
        $stop;
    end

endmodule
