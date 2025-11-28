module tb_initial_quantization_unit_hevc;
logic clk, rst_n;
logic signed [15:0] plSrcCoeff;
logic [15:0] quantCoeff;
logic [5:0] iQBits;
logic signed [31:0] entropyCodingMaximum; // 32-bit for HEVC
logic [31:0] lLevelDouble;
logic [15:0] uiMaxAbsLevel;
logic valid_out;

initial_quantization_unit dut (.*);

always #5 clk = ~clk;

initial begin
clk = 0; rst_n = 0;
plSrcCoeff = 0; quantCoeff = 0; iQBits = 0;
entropyCodingMaximum = 32767;  // HEVC 8-bit: (1 << 15) - 1

#100; rst_n = 1; #10;

$display("=== HEVC/H.265 Test Results ===");
$display("Entropy Coding Maximum: %0d (HEVC 8-bit)", entropyCodingMaximum);
$display("");

// Test 1: Basic Positive Coefficient
plSrcCoeff = 250; quantCoeff = 1820; iQBits = 8; #90;
$display("Test 1: Basic Positive Coefficient");
$display("  Input: coeff=250, quant=1820, qbits=8");
$display("  Expected: lLevelDouble=455000, uiMaxAbsLevel=1777");
$display("  Actual:   lLevelDouble=%0d, uiMaxAbsLevel=%0d", lLevelDouble, uiMaxAbsLevel);
$display("  Status: %s", (lLevelDouble == 455000 && uiMaxAbsLevel == 1777) ? "PASS" : "FAIL");
$display("");

// Test 2: Negative Coefficient - Should NOT clip with HEVC limit
plSrcCoeff = -150; quantCoeff = 2000; iQBits = 6; #90;
$display("Test 2: Negative Coefficient");
$display("  Input: coeff=-150, quant=2000, qbits=6");
$display("  Expected: lLevelDouble=300000, uiMaxAbsLevel=4688");
$display("  Actual:   lLevelDouble=%0d, uiMaxAbsLevel=%0d", lLevelDouble, uiMaxAbsLevel);
$display("  Status: %s", (lLevelDouble == 300000 && uiMaxAbsLevel == 4688) ? "PASS" : "FAIL");
$display("");

// Test 3: Large values - Should clip to 32767 with HEVC limit
plSrcCoeff = 30000; quantCoeff = 25000; iQBits = 4; #90;
$display("Test 3: Large Values (Clipping Test)");
$display("  Input: coeff=30000, quant=25000, qbits=4");
$display("  Expected: lLevelDouble=750000000, uiMaxAbsLevel=32767");
$display("  Actual:   lLevelDouble=%0d, uiMaxAbsLevel=%0d", lLevelDouble, uiMaxAbsLevel);
$display("  Status: %s", (lLevelDouble == 750000000 && uiMaxAbsLevel == 32767) ? "PASS" : "FAIL");
$display("");

// Test 4: Medium values - Should ALSO clip to 32767 with HEVC limit
plSrcCoeff = 1000; quantCoeff = 2000; iQBits = 4; #90;
$display("Test 4: Medium Values (Also Clipped)");
$display("  Input: coeff=1000, quant=2000, qbits=4");
$display("  Expected: lLevelDouble=2000000, uiMaxAbsLevel=32767");
$display("  Actual:   lLevelDouble=%0d, uiMaxAbsLevel=%0d", lLevelDouble, uiMaxAbsLevel);
$display("  Status: %s", (lLevelDouble == 2000000 && uiMaxAbsLevel == 32767) ? "PASS" : "FAIL");
$display("  Note: 125000 > 32767, so correctly clipped to 32767");
$display("");

// Test 5: Zero input
plSrcCoeff = 0; quantCoeff = 1000; iQBits = 8; #90;
$display("Test 5: Zero Input");
$display("  Input: coeff=0, quant=1000, qbits=8");
$display("  Expected: lLevelDouble=0, uiMaxAbsLevel=0");
$display("  Actual:   lLevelDouble=%0d, uiMaxAbsLevel=%0d", lLevelDouble, uiMaxAbsLevel);
$display("  Status: %s", (lLevelDouble == 0 && uiMaxAbsLevel == 0) ? "PASS" : "FAIL");
$display("");

$display("=== Test Summary ===");
#100 $finish;
end

// Waveform dumping for debugging
initial begin
$dumpfile("initial_quantization_unit_hevc.vcd");
$dumpvars(0, tb_initial_quantization_unit_hevc);
end
endmodule