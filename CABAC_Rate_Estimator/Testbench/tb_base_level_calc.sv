`timescale 1ns/1ps

module tb_base_level_calc;

// ======================
// DUT Signals
// ======================
logic clk;
logic rst_n;
logic start;
logic [7:0] c1Idx;
logic [7:0] c2Idx;
logic [7:0] baseLevel;
logic done;

// ======================
// DUT Instantiation
// ======================
base_level_calc dut (
.clk       (clk),
.rst_n      (rst_n),
.start     (start),
.c1Idx     (c1Idx),
.c2Idx     (c2Idx),
.baseLevel (baseLevel),
.done      (done)
);

// ======================
// Clock Generation
// ======================
always #5 clk = ~clk;   // 10ns clock period

// ======================
// Test Sequence
// ======================
initial begin
// Initialize all signals
clk   = 0;
rst_n = 0;
start = 0;
c1Idx = 0;
c2Idx = 0;

// ----------------------
// Apply Reset
// ----------------------
#20;
rst_n = 1;   // Release reset

// ----------------------
// Test Case 1
// c1Idx < 8, c2Idx < 1 ? baseLevel = 3
// ----------------------
@(posedge clk);
start = 1;
c1Idx = 5;
c2Idx = 0;

@(posedge clk);
start = 0;

$display("TC1 -> c1Idx=%0d c2Idx=%0d | baseLevel=%0d done=%0b",
c1Idx, c2Idx, baseLevel, done);

// ----------------------
// Test Case 2
// c1Idx < 8, c2Idx >= 1 ? baseLevel = 2
// ----------------------
@(posedge clk);
start = 1;
c1Idx = 3;
c2Idx = 4;

@(posedge clk);
start = 0;

$display("TC2 -> c1Idx=%0d c2Idx=%0d | baseLevel=%0d done=%0b",
c1Idx, c2Idx, baseLevel, done);

// ----------------------
// Test Case 3
// c1Idx >= 8 ? baseLevel = 1
// ----------------------
@(posedge clk);
start = 1;
c1Idx = 12;
c2Idx = 0;

@(posedge clk);
start = 0;

$display("TC3 -> c1Idx=%0d c2Idx=%0d | baseLevel=%0d done=%0b",
c1Idx, c2Idx, baseLevel, done);

// ----------------------
// Test Case 4
// start = 0 ? no update
// ----------------------
@(posedge clk);
start = 0;
c1Idx = 2;
c2Idx = 0;

@(posedge clk);

$display("TC4 -> start=0 | baseLevel=%0d done=%0b",
baseLevel, done);

// ----------------------
// End Simulation
// ----------------------
#20;
$display("? TEST COMPLETED");
$stop;
end

endmodule
