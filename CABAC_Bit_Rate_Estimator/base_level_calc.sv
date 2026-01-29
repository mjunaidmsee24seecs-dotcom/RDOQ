`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 10:17:57 AM
// Design Name: 
// Module Name: base_level_calc
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
module base_level_calc (  
input  logic       clk,  
input  logic       rst_n,  
input  logic       start,  
input  logic [7:0] c1Idx,  
input  logic [7:0] c2Idx,  
output logic [7:0] baseLevel,  
output logic       done  
);  

// Constants from HM standard  
localparam C1FLAG_NUMBER = 4;  
localparam C2FLAG_NUMBER = 1;  

logic done_reg;  

always_ff @(posedge clk or negedge rst_n) begin  
if (!rst_n) begin  
baseLevel <= 8'd0;  
done_reg <= 1'b0;  
end else if (start) begin  
// Correct base level calculation  
if (c1Idx < C1FLAG_NUMBER) begin  
baseLevel <= (c2Idx < C2FLAG_NUMBER) ? 8'd3 : 8'd2;  
end else begin  
baseLevel <= 8'd1;  
end  
done_reg <= 1'b1;  
end else begin  
done_reg <= 1'b0;  
end  
end  

assign done = done_reg;  

endmodule