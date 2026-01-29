`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2025 11:03:03 AM
// Design Name: 
// Module Name: rate_accumulator
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
module rate_accumulator (
input  logic        clk,
input  logic        rst_n,
input  logic        start,
input  logic [31:0] sign_bit_cost,
input  logic [31:0] suffix_bits,
input  logic [31:0] context_bits,
input  logic [1:0]  level_case,
output logic [31:0] iRate,
output logic        done
);

logic done_reg;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
iRate <= 32'd0;
done_reg <= 1'b0;
end else if (start) begin
if (level_case == 2'd0) begin // ZERO level
iRate <= 32'd0;
end else begin
iRate <= sign_bit_cost + suffix_bits + context_bits;
end
done_reg <= 1'b1;
end else begin
done_reg <= 1'b0;
end
end

assign done = done_reg;

endmodule