module abs_sum_block #(
parameter COEFF_W = 16,
parameter CG_SIZE = 16
)(
input  logic              clk,
input  logic              rst_n,
input  logic              valid_in,
input  logic signed [COEFF_W-1:0] coef_in,
input  logic [3:0]                index_in,
input  logic                      load_done,
input  logic                      start_calc,  // NEW: Start calculation signal
input  logic [3:0]                firstNZ,
input  logic [3:0]                lastNZ,

output logic [19:0]               absSum,
output logic                      parity,
output logic                      valid_out
);

// Internal signals
logic signed [COEFF_W-1:0] cgCoef_reg [0:CG_SIZE-1];
logic [COEFF_W-1:0]        abs_coef_reg [0:CG_SIZE-1];
logic                      coeffs_loaded;
logic [19:0]               partial_sum_reg;
logic [3:0]                calc_index;
logic                      calculation_active;
logic [19:0]               final_sum;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
for (int i = 0; i < CG_SIZE; i = i + 1) begin
cgCoef_reg[i] <= '0;
abs_coef_reg[i] <= '0;
end
coeffs_loaded <= 1'b0;
calculation_active <= 1'b0;
calc_index <= 4'b0;
partial_sum_reg <= 20'b0;
absSum <= 20'b0;
parity <= 1'b0;
valid_out <= 1'b0;
end else begin
// Default assignment
valid_out <= 1'b0;

// Load coefficients
if (valid_in && !coeffs_loaded) begin
cgCoef_reg[index_in] <= coef_in;
abs_coef_reg[index_in] <= (coef_in < 0) ? -coef_in : coef_in;

if (load_done) begin
coeffs_loaded <= 1'b1;
// Don't start calculation yet - wait for start_calc
end
end

// Start calculation when signaled
if (coeffs_loaded && start_calc && !calculation_active) begin
// Check for valid range before starting calculation
if (firstNZ <= lastNZ) begin
calculation_active <= 1'b1;
calc_index <= firstNZ;
partial_sum_reg <= 20'b0;
end else begin
// Invalid range: output 0 immediately
calculation_active <= 1'b0;
absSum <= 20'b0;
parity <= 1'b0;
valid_out <= 1'b1;
coeffs_loaded <= 1'b0;
end
end

// Accumulation calculation (only if range is valid)
if (calculation_active) begin
if (calc_index < lastNZ) begin
// Add current coefficient and move to next
partial_sum_reg <= partial_sum_reg + {4'b0, abs_coef_reg[calc_index]};
calc_index <= calc_index + 1;
end else if (calc_index == lastNZ) begin
// Process last coefficient
final_sum = partial_sum_reg + {4'b0, abs_coef_reg[calc_index]};
absSum <= final_sum;
parity <= final_sum[0];
valid_out <= 1'b1;

// Reset for next calculation
calculation_active <= 1'b0;
coeffs_loaded <= 1'b0;
calc_index <= 4'b0;
end
end
end
end

endmodule