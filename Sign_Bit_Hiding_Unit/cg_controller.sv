module cg_controller #(
parameter COEFF_W = 16,
parameter CG_SIZE = 16
)(
input  logic              clk,
input  logic              rst_n,
input  logic              valid_in,
input  logic signed [COEFF_W-1:0] coef_in,
input  logic [3:0]                position_in,
input  logic                      load_done,
input  logic [3:0]                scan_order [0:CG_SIZE-1],

output logic [3:0]                firstNZ,
output logic [3:0]                lastNZ,
output logic                      hasNZ,
output logic                      valid_out
);

// Internal storage
logic signed [COEFF_W-1:0] cgCoef_reg [0:CG_SIZE-1];
logic                      coeffs_loaded;
logic                      nz_array [0:CG_SIZE-1];
logic [1:0]                state;
logic [3:0]                fNZ, lNZ;
logic                      hNZ;

localparam [1:0] IDLE    = 2'b00;
localparam [1:0] LOADING = 2'b01;
localparam [1:0] PROCESS = 2'b10;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
for (int i = 0; i < CG_SIZE; i = i + 1) begin
cgCoef_reg[i] <= '0;
end
coeffs_loaded <= 1'b0;
state <= IDLE;
firstNZ <= 4'hF;
lastNZ <= 4'hF;
hasNZ <= 1'b0;
valid_out <= 1'b0;
end else begin
valid_out <= 1'b0;

case (state)
IDLE: begin
if (valid_in) begin
cgCoef_reg[position_in] <= coef_in;
state <= LOADING;
end
end

LOADING: begin
if (valid_in) begin
cgCoef_reg[position_in] <= coef_in;
end

if (load_done) begin
state <= PROCESS;
end
end

PROCESS: begin
// Build nz_array using generate loop (combinational)
for (int i = 0; i < CG_SIZE; i = i + 1) begin
nz_array[i] = (cgCoef_reg[scan_order[i]] != 0);
end

// Initialize search variables
fNZ = 4'hF;
lNZ = 4'hF;
hNZ = 1'b0;

// Find firstNZ (forward search)
for (int i = 0; i < CG_SIZE; i = i + 1) begin
if (nz_array[i] == 1'b1 && hNZ == 1'b0) begin
fNZ = i[3:0];
hNZ = 1'b1;
end
end

// Find lastNZ (backward search) - only if hasNZ
if (hNZ) begin
for (int i = CG_SIZE-1; i >= 0; i = i - 1) begin
if (nz_array[i] == 1'b1) begin
lNZ = i[3:0];
break;
end
end
end else begin
lNZ = 4'hF;
end

// Output results
firstNZ <= fNZ;
lastNZ <= lNZ;
hasNZ <= hNZ;
valid_out <= 1'b1;
state <= IDLE;
coeffs_loaded <= 1'b0;
end
endcase
end
end

endmodule