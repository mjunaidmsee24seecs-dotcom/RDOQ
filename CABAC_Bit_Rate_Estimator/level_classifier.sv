`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 10:24:46 AM
// Design Name: 
// Module Name: level_classifier
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
module level_classifier (
input  logic        clk,
input  logic        rst_n,
input  logic        start,
input  logic [15:0] uiAbsLevel,
input  logic [7:0]  baseLevel,
output logic [1:0]  level_case, // 0: ZERO, 1: ONE, 2: TWO, 3: BASEPLUS
output logic [15:0] symbol,
output logic        done
);

logic done_reg;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
level_case <= 2'd0;
symbol <= 16'd0;
done_reg <= 1'b0;
end else if (start) begin
if (uiAbsLevel == 0) begin
level_case <= 2'd0; // ZERO
symbol <= 16'd0;
end else if (uiAbsLevel == 1) begin
level_case <= 2'd1; // ONE
symbol <= 16'd0;
end else if (uiAbsLevel == 2) begin
level_case <= 2'd2; // TWO
symbol <= 16'd0;
end else if (uiAbsLevel >= baseLevel) begin
level_case <= 2'd3; // BASEPLUS
symbol <= uiAbsLevel - baseLevel;
end else begin
level_case <= 2'd0;
symbol <= 16'd0;
end
done_reg <= 1'b1;
end else begin
done_reg <= 1'b0;
end
end

assign done = done_reg;

endmodule