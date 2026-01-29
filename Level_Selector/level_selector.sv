module level_selector #(  
parameter MAX_LEVEL = 32  // Maximum supported level  
)(  
input  logic        clk,  
input  logic        rst_n,  

// Control  
input  logic        start,  
output logic        done,  

// Data inputs  
input  logic [31:0] rdCost_in [0:MAX_LEVEL-1],  
input  logic [7:0]  uiMaxAbsLevel,  

// Outputs  
output logic [7:0]  bestLevel,  
output logic [31:0] bestCost  
);  

// State machine  
typedef enum logic [2:0] {  
IDLE,  
INIT,  
COMPARE,  
DONE  
} state_t;  

state_t state, next_state;  

// Internal registers  
logic [7:0]  current_level;  
logic [31:0] min_cost;  
logic [7:0]  min_level;  
logic [7:0]  level_counter;  

// State transition logic  
always_comb begin  
next_state = state;  
case (state)  
IDLE: begin  
if (start) next_state = INIT;  
end  

INIT: begin  
next_state = COMPARE;  
end  

COMPARE: begin  
// FIX: Handle uiMaxAbsLevel = 0 case
if (uiMaxAbsLevel == 0) begin
next_state = DONE;  // No levels to compare
end else if (level_counter == uiMaxAbsLevel) begin  
next_state = DONE;  
end  
end  

DONE: begin  
next_state = IDLE;  
end  
endcase  
end  

// State machine and comparison logic  
always_ff @(posedge clk or negedge rst_n) begin  
if (!rst_n) begin  
state <= IDLE;  
done <= 1'b0;  
bestLevel <= 8'd0;  
bestCost <= 32'd0;  
current_level <= 8'd0;  
min_cost <= 32'hFFFFFFFF;  
min_level <= 8'd0;  
level_counter <= 8'd0;  
end else begin  
state <= next_state;  

case (state)  
IDLE: begin  
done <= 1'b0;  
end  

INIT: begin  
// Initialize with first level  
min_cost <= rdCost_in[0];  
min_level <= 8'd0;  
// FIX: Handle uiMaxAbsLevel = 0
if (uiMaxAbsLevel == 0) begin
level_counter <= 8'd0;  // No comparisons needed
end else begin
level_counter <= 8'd1;  
current_level <= 8'd1;  
end
end  

COMPARE: begin  
// Compare current level cost with minimum  
if (rdCost_in[current_level] < min_cost) begin  
min_cost <= rdCost_in[current_level];  
min_level <= current_level;  
end  

// Move to next level  
if (current_level < uiMaxAbsLevel) begin  
current_level <= current_level + 1;  
level_counter <= level_counter + 1;  
end  
end  

DONE: begin  
bestLevel <= min_level;  
bestCost <= min_cost;  
done <= 1'b1;  
end  
endcase  
end  
end  

endmodule