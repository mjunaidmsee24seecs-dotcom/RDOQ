`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 12:06:19 PM
// Design Name: 
// Module Name: context_bit_lookup
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module context_bit_lookup (
input  logic        clk,
input  logic        rst_n,
input  logic        start,
input  logic [1:0]  level_case,
input  logic [7:0]  c1Idx,
input  logic [7:0]  c2Idx,
input  logic [15:0] greater_one_cost,
input  logic [15:0] level_abs_cost,
output logic [31:0] context_bits,
output logic        done
);

logic done_reg;
logic [31:0] temp_bits;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
context_bits <= 32'd0;
done_reg <= 1'b0;
end else if (start) begin
context_bits <= 32'd0;
temp_bits <= 32'd0;

case (level_case)
2'd1: begin // ONE = greaterOneBits[ctx][0]
// For level=1, use cost for bin=0
context_bits <= {16'd0, greater_one_cost};
end
2'd2: begin // TWO = greaterOneBits[ctx][1] + levelAbsBits[ctx][0]
// For level=2, use cost for bin=1 from greaterOne and bin=0 from levelAbs
temp_bits = {16'd0, greater_one_cost} + {16'd0, level_abs_cost};
context_bits <= temp_bits;
end
2'd3: begin // BASEPLUS
if (c1Idx < 8) begin
// Use cost for bin=1 from greaterOne
context_bits <= {16'd0, greater_one_cost};
if (c2Idx < 1) begin
// Also use cost for bin=1 from levelAbs
temp_bits = {16'd0, greater_one_cost} + {16'd0, level_abs_cost};
context_bits <= temp_bits;
end
end
end
default: begin // ZERO or others
context_bits <= 32'd0;
end
endcase
done_reg <= 1'b1;
end else begin
done_reg <= 1'b0;
end
end

assign done = done_reg;

endmodule
