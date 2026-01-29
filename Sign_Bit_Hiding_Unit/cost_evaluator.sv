module cost_evaluator #(
parameter COEFF_W = 16
)(
input  logic              clk,
input  logic              rst_n,
input  logic              valid_in,
input  logic signed [COEFF_W-1:0] coef_in,
input  logic signed [COEFF_W-1:0] deltaU_in,
input  logic                      isFirstNZ_in,

output logic signed [31:0]        cost_out,
output logic signed [1:0]         change_out,
output logic                      valid_out
);

// Pipeline stage 1 registers
logic                      stage1_valid;
logic signed [COEFF_W-1:0] stage1_coef;
logic signed [COEFF_W-1:0] stage1_deltaU;
logic                      stage1_isFirstNZ;

// Pipeline stage 2 registers
logic                      stage2_valid;
logic signed [31:0]        stage2_cost;
logic signed [1:0]         stage2_change;

// Main pipeline
always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
// Stage 1 reset
stage1_valid <= 1'b0;
stage1_coef <= '0;
stage1_deltaU <= '0;
stage1_isFirstNZ <= 1'b0;

// Stage 2 reset
stage2_valid <= 1'b0;
stage2_cost <= 32'h7fffffff;
stage2_change <= 2'b00;

// Outputs reset
cost_out <= 32'h7fffffff;
change_out <= 2'b00;
valid_out <= 1'b0;
end else begin
// Default outputs
valid_out <= 1'b0;

// Pipeline Stage 1: Register inputs
stage1_valid <= valid_in;
if (valid_in) begin
stage1_coef <= coef_in;
stage1_deltaU <= deltaU_in;
stage1_isFirstNZ <= isFirstNZ_in;
end

// Pipeline Stage 2: Perform calculation
stage2_valid <= stage1_valid;
if (stage1_valid) begin
// Default values
stage2_cost <= 32'h7fffffff;
stage2_change <= 2'b00;

if (stage1_coef == 0) begin
// Zero coefficient: can only go to +1
if (stage1_deltaU > 0) begin
stage2_cost <= -stage1_deltaU;  // Negative cost encourages change
stage2_change <= 1;             // 0 ? 1
end
end else begin
// Non-zero coefficient
if (stage1_deltaU > 0) begin
// Positive deltaU: good to increase coefficient
stage2_cost <= -stage1_deltaU;
stage2_change <= 1;             // n ? n+1
end else if (stage1_deltaU < 0) begin
// Negative deltaU: good to decrease coefficient
// Except special case: firstNZ with coef=1 can't go to 0
if (!(stage1_isFirstNZ && stage1_coef == 1)) begin
stage2_cost <= stage1_deltaU;   // Already negative
stage2_change <= -1;            // n ? n-1
end
end
end
end

// Output stage
if (stage2_valid) begin
cost_out <= stage2_cost;
change_out <= stage2_change;
valid_out <= 1'b1;
end
end
end

endmodule