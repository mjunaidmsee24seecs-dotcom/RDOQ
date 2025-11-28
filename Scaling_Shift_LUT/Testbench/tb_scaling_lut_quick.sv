module tb_scaling_coeff_lut_simple;

// Parameters
localparam CLK_PERIOD = 10;

// Signals
logic [2:0] qp_rem;
logic [4:0] iTransformShift;
logic [2:0] channelBitDepth;
logic [15:0] piQCoef;
logic [31:0] pdErrScale;
logic clk, enable;

// Instantiate DUT
scaling_coeff_lut_simple dut (.*);

// Clock generation
initial begin
clk = 0;
forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test sequence
initial begin
// Initialize
enable = 0;
qp_rem = 3'd0;
iTransformShift = 5'd0;
channelBitDepth = 3'd0; // 8-bit

#20;
enable = 1;

$display("=== Scaling Coefficient LUT Test ===");
$display("QP_rem | piQCoef  | pdErrScale | Status");
$display("-------------------------------------");

// Test different QP remainders
for (int qp = 0; qp < 6; qp++) begin
qp_rem = qp;
iTransformShift = 5'd0;
channelBitDepth = 3'd0;
@(posedge clk);
#1; // Wait for combinational logic
if (pdErrScale == 0) begin
$display("   %0d   | %5d   | %8d   | ERROR: Zero", qp_rem, piQCoef, pdErrScale);
end else begin
$display("   %0d   | %5d   | %8d   | OK", qp_rem, piQCoef, pdErrScale);
end
end

// Test with small QP values (smaller quant coefficients)
$display("\n--- Testing Small QP values ---");
for (int qp = 0; qp < 3; qp++) begin
qp_rem = qp;
iTransformShift = 5'd0;
@(posedge clk);
#1;
$display("   %0d   | %5d   | %8d", qp_rem, piQCoef, pdErrScale);
end

$display("\n=== Test Complete ===");
$finish;
end

endmodule