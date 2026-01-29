`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 12:16:16 PM
// Design Name: 
// Module Name: sign_bit_cost
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
module sign_bit_cost (
input  logic       clk,
input  logic       rst_n,
input  logic       start,
output logic [31:0] sign_bit_cost,
output logic       done
);

// Constants - ADDED MISSING DECLARATION
localparam IEP_RATE = 32768;  // Fixed sign bit cost (equal probability)

logic done_reg;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
sign_bit_cost <= 32'd0;
done_reg <= 1'b0;
end else if (start) begin
sign_bit_cost <= IEP_RATE; // Fixed sign bit cost
done_reg <= 1'b1;
end else begin
done_reg <= 1'b0;
end
end

assign done = done_reg;

endmodule


