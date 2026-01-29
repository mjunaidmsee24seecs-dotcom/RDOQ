`timescale 1ns/1ps

module last_position_optimizer #(
parameter MAX_BLOCK_SIZE  = 32,
parameter MAX_COEFF_COUNT = 1024,
parameter COST_WIDTH      = 32,
parameter ADDR_WIDTH      = 10,
parameter CG_SIZE         = 16  // coefficient group size
)(
input  logic                     clk,
input  logic                     rst_n,

// Control
input  logic                     start,
output logic                     done,

// Inputs
input  logic [COST_WIDTH-1:0]    pdCostCoeff [0:MAX_COEFF_COUNT-1],
input  logic [COST_WIDTH-1:0]    pdCostCoeff0[0:MAX_COEFF_COUNT-1], // HM base cost ref
input  logic [COST_WIDTH-1:0]    pdCostSig   [0:MAX_COEFF_COUNT-1],
input  logic [COST_WIDTH-1:0]    pdCostCoeffGroupSig [0:MAX_COEFF_COUNT/CG_SIZE-1], // NEW
input  logic signed [15:0]       piDstCoeff  [0:MAX_COEFF_COUNT-1],

input  logic [ADDR_WIDTH-1:0]    iLastScanPos,
input  logic [ADDR_WIDTH-1:0]    scanOrder   [0:MAX_COEFF_COUNT-1],
input  logic [MAX_COEFF_COUNT/CG_SIZE-1:0] uiSigCoeffGroupFlag, // group valid flags

// Output
output logic [ADDR_WIDTH-1:0]    iBestLastIdxP1
);

// FSM states
typedef enum logic [2:0] {
IDLE,
INIT,
PROCESS_CG,
SCAN_CG,
SCAN_POS,
CALC_COST,
UPDATE,
DONE
} state_t;

state_t state, next_state;

// Internal registers
logic [$clog2(MAX_COEFF_COUNT)-1:0] cg_scan_pos;
logic [$clog2(CG_SIZE)-1:0]         scan_pos_in_cg;
logic [$clog2(MAX_COEFF_COUNT)-1:0] scan_pos;
logic [$clog2(MAX_COEFF_COUNT)-1:0] blk_pos;
logic [COST_WIDTH-1:0]              d64BaseCost;
logic [COST_WIDTH-1:0]              d64BestCost;
logic [COST_WIDTH-1:0]              d64CostLast;
logic [COST_WIDTH-1:0]              totalCost;
logic                                bFoundLast;
logic                                skip_base_update;

// FSM sequential
always_ff @(posedge clk or negedge rst_n) begin
if(!rst_n) begin
state           <= IDLE;
cg_scan_pos     <= '0;
scan_pos_in_cg  <= '0;
d64BaseCost     <= 0;
d64BestCost     <= {COST_WIDTH{1'b1}}; // max value
iBestLastIdxP1  <= 0;
bFoundLast      <= 1'b0;
skip_base_update <= 1'b0;
end else begin
state <= next_state;
case(state)

INIT: begin
cg_scan_pos    <= iLastScanPos / CG_SIZE;
scan_pos_in_cg <= CG_SIZE-1;
d64BaseCost    <= 0;
d64BestCost    <= {COST_WIDTH{1'b1}};
iBestLastIdxP1 <= 0;
bFoundLast     <= 1'b0;
skip_base_update <= 1'b0;
end

PROCESS_CG: begin
// Subtract group cost for this CG (matching C++ code)
d64BaseCost <= d64BaseCost - pdCostCoeffGroupSig[cg_scan_pos];
end

SCAN_POS: begin
scan_pos <= cg_scan_pos * CG_SIZE + scan_pos_in_cg;
blk_pos  <= scanOrder[cg_scan_pos * CG_SIZE + scan_pos_in_cg];
skip_base_update <= 1'b0; // Reset for new position
end

CALC_COST: begin
if(scan_pos <= iLastScanPos && piDstCoeff[blk_pos] != 0) begin
d64CostLast = 32'd1000; // placeholder for xGetRateLast
totalCost   = d64BaseCost + d64CostLast - pdCostSig[scan_pos];
if(totalCost < d64BestCost) begin
d64BestCost    <= totalCost;
iBestLastIdxP1 <= scan_pos + 1;
end
// Check if we should break after this position
if(piDstCoeff[blk_pos] > 1) begin
bFoundLast <= 1'b1;
skip_base_update <= 1'b1; // Skip base cost update
end
end
end

UPDATE: begin
// Update base cost if not skipping
if(!skip_base_update) begin
if(scan_pos <= iLastScanPos && piDstCoeff[blk_pos] != 0) begin
d64BaseCost <= d64BaseCost - pdCostCoeff[scan_pos] + pdCostCoeff0[scan_pos];
end else begin
d64BaseCost <= d64BaseCost - pdCostSig[scan_pos];
end
end

// Update counters if not breaking
if(!bFoundLast) begin
if(scan_pos_in_cg != 0)
scan_pos_in_cg <= scan_pos_in_cg - 1;
else if(cg_scan_pos != 0) begin
cg_scan_pos    <= cg_scan_pos - 1;
scan_pos_in_cg <= CG_SIZE-1;
end
end
end

DONE: begin
// Optional debug display
// $display("scan_pos=%0d, cg_scan_pos=%0d, coeff=%0d, best=%0d",
//         scan_pos, cg_scan_pos, piDstCoeff[blk_pos], iBestLastIdxP1);
end

endcase
end
end

// FSM combinatorial
always_comb begin
next_state = state;
case(state)
IDLE:   if(start) next_state = INIT;
INIT:   next_state = PROCESS_CG;
PROCESS_CG: next_state = SCAN_CG;
SCAN_CG: 
if(uiSigCoeffGroupFlag[cg_scan_pos]) 
    next_state = SCAN_POS;
else if(cg_scan_pos != 0) 
    next_state = PROCESS_CG; // Next CG
else 
    next_state = DONE;
SCAN_POS: next_state = CALC_COST;
CALC_COST: next_state = UPDATE;
UPDATE:
if(bFoundLast) 
    next_state = DONE;
else if(scan_pos_in_cg != 0) 
    next_state = SCAN_POS;
else if(cg_scan_pos != 0) 
    next_state = PROCESS_CG;
else 
    next_state = DONE;
DONE:   if(!start) next_state = IDLE;
endcase
end

assign done = (state == DONE);

endmodule