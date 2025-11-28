`timescale 1ns/1ps

module tb_level_classifier;

// -------------------------
// DUT Signals
// -------------------------
logic clk;
logic rst_n;
logic start;
logic [15:0] uiAbsLevel;
logic [7:0]  baseLevel;
logic [1:0]  level_case;
logic [15:0] symbol;
logic done;

// -------------------------
// DUT Instantiation
// -------------------------
level_classifier dut (
.clk         (clk),
.rst_n        (rst_n),
.start        (start),
.uiAbsLevel  (uiAbsLevel),
.baseLevel   (baseLevel),
.level_case  (level_case),
.symbol      (symbol),
.done         (done)
);

// -------------------------
// Clock Generation (10ns)
// -------------------------
always #5 clk = ~clk;

// -------------------------
// Test Sequence
// -------------------------
initial begin
// Initial values
clk        = 0;
rst_n      = 0;
start      = 0;
uiAbsLevel = 0;
baseLevel  = 3;

// -------------------------
// Apply Reset
// -------------------------
#20;
rst_n = 1;

// -------------------------
// Test Case 1: ZERO
// uiAbsLevel = 0
// -------------------------
@(posedge clk);
start      = 1;
uiAbsLevel = 0;

@(posedge clk);
start = 0;

$display("TC1 ZERO -> uiAbsLevel=%0d | level_case=%0d symbol=%0d done=%0b",
uiAbsLevel, level_case, symbol, done);

// -------------------------
// Test Case 2: ONE
// uiAbsLevel = 1
// -------------------------
@(posedge clk);
start      = 1;
uiAbsLevel = 1;

@(posedge clk);
start = 0;

$display("TC2 ONE -> uiAbsLevel=%0d | level_case=%0d symbol=%0d done=%0b",
uiAbsLevel, level_case, symbol, done);

// -------------------------
// Test Case 3: TWO
// uiAbsLevel = 2
// -------------------------
@(posedge clk);
start      = 1;
uiAbsLevel = 2;

@(posedge clk);
start = 0;

$display("TC3 TWO -> uiAbsLevel=%0d | level_case=%0d symbol=%0d done=%0b",
uiAbsLevel, level_case, symbol, done);

// -------------------------
// Test Case 4: BASEPLUS
// uiAbsLevel = 7, baseLevel = 3
// -------------------------
@(posedge clk);
start      = 1;
uiAbsLevel = 7;
baseLevel  = 3;

@(posedge clk);
start = 0;

$display("TC4 BASEPLUS -> uiAbsLevel=%0d baseLevel=%0d | level_case=%0d symbol=%0d done=%0b",
uiAbsLevel, baseLevel, level_case, symbol, done);

// -------------------------
// End Simulation
// -------------------------
#20;
$display("? LEVEL CLASSIFIER TEST COMPLETE");
$stop;
end

endmodule
