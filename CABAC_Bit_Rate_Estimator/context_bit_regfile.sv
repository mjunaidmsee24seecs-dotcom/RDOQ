`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 10:46:29 AM
// Design Name: 
// Module Name: context_bit_regfile
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
module context_bit_regfile #(
    parameter NUM_CTX = 24,
    parameter CTX_TYPE = 0  // 0: greaterOne, 1: levelAbs
)(
    input  logic        clk,
    input  logic        rst_n,

    // Write Interface
    input  logic        we,
    input  logic [7:0]  ctx_addr,
    input  logic        bin_val,
    input  logic [15:0] bit_cost_in,

    // Read Interface
    input  logic [4:0]  read_ctx_addr,
    input  logic        read_bin_sel,

    // Outputs
    output logic [15:0] bit_cost_out,
    output logic [15:0] bit_cost_out0,
    output logic [15:0] bit_cost_out1
);

    // Bit cost memory
    logic [15:0] bit_cost_mem [0:NUM_CTX-1][0:1];

    // HM FAST_BIT_EST entropy bits
    localparam [15:0] HM_ENTROPY_BITS [0:95] = '{
        16'h0F64, 16'h10BF, 16'h0E94, 16'h1197, 16'h0DDC, 16'h126A, 16'h0CFE, 16'h1383,
        16'h0C16, 16'h14C5, 16'h0B53, 16'h15EB, 16'h0A91, 16'h172A, 16'h09EA, 16'h1855,
        16'h0950, 16'h197E, 16'h08BA, 16'h1AB8, 16'h0828, 16'h1C03, 16'h07B1, 16'h1D26,
        16'h073C, 16'h1E59, 16'h06CC, 16'h1F93, 16'h0668, 16'h20C0, 16'h060A, 16'h21F2,
        16'h05A9, 16'h2340, 16'h055A, 16'h2466, 16'h050D, 16'h2595, 16'h04C0, 16'h26DB,
        16'h0484, 16'h27E9, 16'h043E, 16'h2938, 16'h0407, 16'h2A4F, 16'h03C9, 16'h2BA0,
        16'h0393, 16'h2CDB, 16'h035B, 16'h2E02, 16'h0334, 16'h2F31, 16'h02F1, 16'h3050,
        16'h02CB, 16'h3154, 16'h02A3, 16'h3264, 16'h027C, 16'h336F, 16'h0259, 16'h346A,
        16'h023E, 16'h3541, 16'h0218, 16'h3642, 16'h01FC, 16'h3747, 16'h01D6, 16'h384E,
        16'h01BD, 16'h3934, 16'h019E, 16'h3A2E, 16'h0182, 16'h3B20, 16'h0165, 16'h3C2E,
        16'h014D, 16'h3D17, 16'h0131, 16'h3E1C, 16'h011B, 16'h3F0A, 16'h0103, 16'h400D,
        16'h00F0, 16'h40DB, 16'h00DC, 16'h41E0, 16'h00C7, 16'h42E0, 16'h00B1, 16'h43F7
    };

    // ============================================================
    // Reset Initialization + Write Logic - FIXED VERSION
    // ============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all memory locations
            for (int i = 0; i < NUM_CTX; i++) begin
                if (CTX_TYPE == 0) begin
                    // greaterOne: use every 2nd entry
                    bit_cost_mem[i][0] <= HM_ENTROPY_BITS[(i*2) % 96];
                    bit_cost_mem[i][1] <= HM_ENTROPY_BITS[(i*2 + 1) % 96];
                end else begin
                    // levelAbs: use every 3rd entry  
                    bit_cost_mem[i][0] <= HM_ENTROPY_BITS[(i*3) % 96];
                    bit_cost_mem[i][1] <= HM_ENTROPY_BITS[(i*3 + 1) % 96];
                end
            end
        end 
        else if (we) begin
            // Write to memory - FIX: Check address bounds
            if (ctx_addr < NUM_CTX) begin
                bit_cost_mem[ctx_addr][bin_val] <= bit_cost_in;
                // Debug print
                $display("[CTX_MEM] Write: addr=%0d, bin=%0d, data=0x%4h",
                        ctx_addr, bin_val, bit_cost_in);
            end else begin
                $display("[CTX_MEM] ERROR: Write address %0d out of bounds", ctx_addr);
            end
        end
    end

    // ============================================================
    // Read Logic (Combinational) - FIXED VERSION
    // ============================================================
    
    // Direct outputs with bounds checking
    assign bit_cost_out0 = (read_ctx_addr < NUM_CTX) ?
                          bit_cost_mem[read_ctx_addr][1'b0] : 16'd0;

    assign bit_cost_out1 = (read_ctx_addr < NUM_CTX) ?
                          bit_cost_mem[read_ctx_addr][1'b1] : 16'd0;

    // Selected output via mux
    assign bit_cost_out = (read_bin_sel == 1'b0) ? 
                         bit_cost_out0 : bit_cost_out1;

endmodule
