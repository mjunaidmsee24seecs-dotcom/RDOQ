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
module sign_bit_cost #(
parameter IEP_RATE = 32768
)(
input  logic       clk,
input  logic       rst_n,
input  logic       start,
output logic [31:0] sign_bit_cost,
output logic       done
);

logic start_d;
logic done_reg;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
sign_bit_cost <= 32'd0;
start_d <= 1'b0;
done_reg <= 1'b0;
end else begin
// Rising edge detection: sample previous start
done_reg <= start & ~start_d; 

// Update output only when rising edge detected
if (start & ~start_d) begin
sign_bit_cost <= IEP_RATE;
end

// update delayed start
start_d <= start;
end
end

assign done = done_reg;

endmodule


