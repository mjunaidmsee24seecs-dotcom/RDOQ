`timescale 1ns/1ps

module sign_bit_hiding_top #(
parameter COEFF_W = 16,
parameter CG_SIZE = 16,
parameter SBH_THRESHOLD = 4
)(
// Clock and Reset
input  logic              clk,
input  logic              rst_n,

// Input Interface
input  logic              valid_in,
input  logic signed [COEFF_W-1:0] coef_in,
input  logic [3:0]                position_in,
input  logic                      load_done,
input  logic [3:0]                scan_order [0:CG_SIZE-1],
input  logic signed [COEFF_W-1:0] deltaU_in,
input  logic signed [COEFF_W:0]   minBound_in,
input  logic signed [COEFF_W:0]   maxBound_in,

// Output Interface
output logic signed [COEFF_W-1:0] coef_out,
output logic [3:0]                position_out,
output logic                      needHide_out,
output logic                      valid_out
);

// ===========================================
// Pipeline Stage 0: Coefficient Storage
// ===========================================
logic signed [COEFF_W-1:0] coeff_storage [0:CG_SIZE-1];
logic [3:0] stored_position_reg [0:2];  // Pipeline delay for position

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
for (int i = 0; i < CG_SIZE; i = i + 1) begin
coeff_storage[i] <= '0;
end
for (int i = 0; i < 3; i = i + 1) begin
stored_position_reg[i] <= '0;
end
end else begin
// Store coefficients
if (valid_in) begin
coeff_storage[position_in] <= coef_in;
end

// Pipeline position through stages
stored_position_reg[0] <= position_in;
stored_position_reg[1] <= stored_position_reg[0];
stored_position_reg[2] <= stored_position_reg[1];
end
end

// ===========================================
// Pipeline Stage 1: CG Controller
// ===========================================
logic [3:0] firstNZ, lastNZ;
logic hasNZ, cg_valid_out;

cg_controller #(
.COEFF_W (COEFF_W),
.CG_SIZE (CG_SIZE)
) cg_controller_inst (
.clk         (clk),
.rst_n       (rst_n),
.valid_in    (valid_in),
.coef_in     (coef_in),
.position_in (position_in),
.load_done   (load_done),
.scan_order  (scan_order),
.firstNZ     (firstNZ),
.lastNZ      (lastNZ),
.hasNZ       (hasNZ),
.valid_out   (cg_valid_out)
);

// Stage 1 pipeline registers
logic [3:0] firstNZ_reg, lastNZ_reg;
logic hasNZ_reg;
logic stage1_valid;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
firstNZ_reg  <= 4'hF;
lastNZ_reg   <= 4'hF;
hasNZ_reg    <= 1'b0;
stage1_valid <= 1'b0;
end else begin
firstNZ_reg  <= firstNZ;
lastNZ_reg   <= lastNZ;
hasNZ_reg    <= hasNZ;
stage1_valid <= cg_valid_out;
end
end

// ===========================================
// Pipeline Stage 2: Absolute Sum Calculation
// ===========================================
logic [19:0] absSum;
logic parity, abs_sum_valid_out;

abs_sum_block #(
.COEFF_W (COEFF_W),
.CG_SIZE (CG_SIZE)
) abs_sum_block_inst (
.clk        (clk),
.rst_n      (rst_n),
.valid_in   (valid_in),
.coef_in    (coef_in),
.index_in   (position_in),
.load_done  (load_done),
.start_calc (stage1_valid),  // Start when CG controller is done
.firstNZ    (firstNZ_reg),
.lastNZ     (lastNZ_reg),
.absSum     (absSum),
.parity     (parity),
.valid_out  (abs_sum_valid_out)
);

// Stage 2 pipeline registers
logic [3:0] stage2_firstNZ, stage2_lastNZ;
logic stage2_hasNZ;
logic [19:0] stage2_absSum;
logic stage2_parity;
logic stage2_valid;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
stage2_firstNZ <= 4'hF;
stage2_lastNZ  <= 4'hF;
stage2_hasNZ   <= 1'b0;
stage2_absSum  <= '0;
stage2_parity  <= 1'b0;
stage2_valid   <= 1'b0;
end else begin
stage2_firstNZ <= firstNZ_reg;
stage2_lastNZ  <= lastNZ_reg;
stage2_hasNZ   <= hasNZ_reg;
stage2_absSum  <= absSum;
stage2_parity  <= parity;
stage2_valid   <= abs_sum_valid_out;
end
end

// Extract sign of lastNZ coefficient (combinational)
logic lastNZ_sign;
assign lastNZ_sign = (stage2_hasNZ && stage2_lastNZ < CG_SIZE) ? 
coeff_storage[stage2_lastNZ][COEFF_W-1] : 1'b0;

// Store coefficient to be processed
logic signed [COEFF_W-1:0] processed_coef;
logic [3:0] processed_pos;
logic processed_isFirstNZ;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
processed_coef      <= '0;
processed_pos       <= '0;
processed_isFirstNZ <= 1'b0;
end else if (stage2_valid && stage2_hasNZ) begin
processed_coef      <= coeff_storage[stage2_lastNZ];
processed_pos       <= stage2_lastNZ;
processed_isFirstNZ <= (stage2_lastNZ == stage2_firstNZ);
end
end

// ===========================================
// Pipeline Stage 3: SBH Decision
// ===========================================
logic needHide, sbh_valid_out;

sbh_decision #(
.SBH_THRESHOLD (SBH_THRESHOLD)
) sbh_decision_inst (
.clk            (clk),
.rst_n          (rst_n),
.valid_in       (stage2_valid),
.firstNZ_in     (stage2_firstNZ),
.lastNZ_in      (stage2_lastNZ),
.parity_in      (stage2_parity),
.lastNZ_sign_in (lastNZ_sign),
.needHide_out   (needHide),
.valid_out      (sbh_valid_out)
);

// Stage 3 pipeline registers
logic stage3_needHide;
logic signed [COEFF_W-1:0] stage3_coef;
logic [3:0] stage3_pos;
logic stage3_isFirstNZ;
logic stage3_valid;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
stage3_needHide   <= 1'b0;
stage3_coef       <= '0;
stage3_pos        <= '0;
stage3_isFirstNZ  <= 1'b0;
stage3_valid      <= 1'b0;
end else begin
stage3_needHide   <= needHide;
stage3_coef       <= processed_coef;
stage3_pos        <= processed_pos;
stage3_isFirstNZ  <= processed_isFirstNZ;
stage3_valid      <= sbh_valid_out;
end
end

// ===========================================
// Pipeline Stage 4: Cost Evaluator
// ===========================================
logic signed [31:0] cost;
logic signed [1:0] change;
logic cost_valid_out;

cost_evaluator #(
.COEFF_W (COEFF_W)
) cost_evaluator_inst (
.clk          (clk),
.rst_n        (rst_n),
.valid_in     (stage3_valid && stage3_needHide),
.coef_in      (stage3_coef),
.deltaU_in    (deltaU_in),
.isFirstNZ_in (stage3_isFirstNZ),
.cost_out     (cost),
.change_out   (change),
.valid_out    (cost_valid_out)
);

// Stage 4 pipeline registers (for non-hiding path)
logic stage4_needHide;
logic signed [COEFF_W-1:0] stage4_coef;
logic [3:0] stage4_pos;
logic stage4_valid_nohide;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
stage4_needHide      <= 1'b0;
stage4_coef          <= '0;
stage4_pos           <= '0;
stage4_valid_nohide  <= 1'b0;
end else begin
stage4_needHide      <= stage3_needHide;
stage4_coef          <= stage3_coef;
stage4_pos           <= stage3_pos;
stage4_valid_nohide  <= stage3_valid && !stage3_needHide;
end
end

// ===========================================
// Pipeline Stage 5: Coefficient Update
// ===========================================
logic signed [COEFF_W-1:0] updated_coef;
logic update_valid_out;

coeff_update #(
.COEFF_W (COEFF_W)
) coeff_update_inst (
.clk          (clk),
.rst_n        (rst_n),
.valid_in     (cost_valid_out),
.coef_in      (stage3_coef),  // Direct from stage3
.change_in    (change),
.minBound_in  (minBound_in),
.maxBound_in  (maxBound_in),
.coef_out     (updated_coef),
.valid_out    (update_valid_out)
);

// Stage 5 pipeline registers for updated coefficient
logic signed [COEFF_W-1:0] stage5_coef;
logic [3:0] stage5_pos;
logic stage5_valid_hide;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
stage5_coef        <= '0;
stage5_pos         <= '0;
stage5_valid_hide  <= 1'b0;
end else begin
stage5_coef        <= updated_coef;
stage5_pos         <= stage4_pos;  // Position stays same
stage5_valid_hide  <= update_valid_out;
end
end

// ===========================================
// Output Stage: MUX between paths
// ===========================================
always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
coef_out     <= '0;
position_out <= '0;
needHide_out <= 1'b0;
valid_out    <= 1'b0;
end else begin
// Priority: Hiding path has higher latency, check it first
if (stage5_valid_hide) begin
coef_out     <= stage5_coef;
position_out <= stage5_pos;
needHide_out <= 1'b1;
valid_out    <= 1'b1;
end else if (stage4_valid_nohide) begin
coef_out     <= stage4_coef;
position_out <= stage4_pos;
needHide_out <= 1'b0;
valid_out    <= 1'b1;
end else begin
valid_out    <= 1'b0;
needHide_out <= 1'b0;
end
end
end

// ===========================================
// Debug Signals (optional - can remove in synthesis)
// ===========================================
// synthesis translate_off
logic [4:0] pipeline_debug;
assign pipeline_debug = {valid_out, stage5_valid_hide, stage4_valid_nohide, 
stage3_valid, stage2_valid, stage1_valid};
// synthesis translate_on

endmodule