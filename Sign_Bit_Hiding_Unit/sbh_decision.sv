module sbh_decision #(
parameter SBH_THRESHOLD = 4
)(
input  logic              clk,
input  logic              rst_n,
input  logic              valid_in,
input  logic [3:0]        firstNZ_in,
input  logic [3:0]        lastNZ_in,
input  logic              parity_in,
input  logic              lastNZ_sign_in,

output logic              needHide_out,
output logic              valid_out
);

// Internal registers
logic [3:0] firstNZ_reg;
logic [3:0] lastNZ_reg;
logic       parity_reg;
logic       lastNZ_sign_reg;
logic       calculation_active;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
firstNZ_reg <= 4'h0;
lastNZ_reg <= 4'h0;
parity_reg <= 1'b0;
lastNZ_sign_reg <= 1'b0;
calculation_active <= 1'b0;
needHide_out <= 1'b0;
valid_out <= 1'b0;
end else begin
// Default assignments
valid_out <= 1'b0;

// Register inputs when valid
if (valid_in) begin
firstNZ_reg <= firstNZ_in;
lastNZ_reg <= lastNZ_in;
parity_reg <= parity_in;
lastNZ_sign_reg <= lastNZ_sign_in;
calculation_active <= 1'b1;
end

// Perform calculation
if (calculation_active) begin
// Calculate range condition: lastNZ >= firstNZ
logic range_valid;
logic [3:0] range_diff;
logic range_threshold;

range_valid = (lastNZ_reg >= firstNZ_reg);
range_diff = lastNZ_reg - firstNZ_reg;
range_threshold = (range_diff >= SBH_THRESHOLD);

// Determine if hiding is needed
needHide_out <= range_valid && range_threshold && 
(lastNZ_sign_reg != parity_reg);

valid_out <= 1'b1;
calculation_active <= 1'b0;
end
end
end

endmodule