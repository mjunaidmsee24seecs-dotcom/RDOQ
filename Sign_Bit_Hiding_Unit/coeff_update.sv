module coeff_update #(
parameter COEFF_W = 16
)(
input  logic              clk,
input  logic              rst_n,
input  logic              valid_in,
input  logic signed [COEFF_W-1:0] coef_in,
input  logic signed [1:0]         change_in,
input  logic signed [COEFF_W:0]   minBound_in,
input  logic signed [COEFF_W:0]   maxBound_in,

output logic signed [COEFF_W-1:0] coef_out,
output logic                      valid_out
);

// Pipeline stage 1 registers
logic                      stage1_valid;
logic signed [COEFF_W-1:0] stage1_coef;
logic signed [1:0]         stage1_change;
logic signed [COEFF_W:0]   stage1_minBound;
logic signed [COEFF_W:0]   stage1_maxBound;

// Pipeline stage 2 registers
logic                      stage2_valid;
logic signed [COEFF_W-1:0] stage2_result;
logic signed [COEFF_W:0] coef_ext;
logic signed [COEFF_W:0] new_coef;
always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
// Stage 1 reset
stage1_valid <= 1'b0;
stage1_coef <= '0;
stage1_change <= '0;
stage1_minBound <= '0;
stage1_maxBound <= '0;

// Stage 2 reset
stage2_valid <= 1'b0;
stage2_result <= '0;

// Outputs reset
coef_out <= '0;
valid_out <= 1'b0;
end else begin
// Default outputs
valid_out <= 1'b0;

// Pipeline Stage 1: Register inputs
stage1_valid <= valid_in;
if (valid_in) begin
stage1_coef <= coef_in;
stage1_change <= change_in;
stage1_minBound <= minBound_in;
stage1_maxBound <= maxBound_in;
end

// Pipeline Stage 2: Perform calculation
stage2_valid <= stage1_valid;
if (stage1_valid) begin
// Default: no change
stage2_result <= stage1_coef;

// Sign-extend coefficient to 17-bit


coef_ext = {stage1_coef[COEFF_W-1], stage1_coef};

if (stage1_change == 1) begin
new_coef = coef_ext + 1;
if (new_coef <= stage1_maxBound) begin
stage2_result <= stage1_coef + 1;
end
end
else if (stage1_change == -1) begin
new_coef = coef_ext - 1;
if (new_coef >= stage1_minBound) begin
stage2_result <= stage1_coef - 1;
end
end
end

// Output stage
if (stage2_valid) begin
coef_out <= stage2_result;
valid_out <= 1'b1;
end
end
end

endmodule