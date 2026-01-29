`timescale 1ns / 1ps
//==============================================================================  
// Module 14: Sign Restoration  
//  
// Description:  
// Implements the final sign application step in HEVC RDOQ pipeline.  
// This module applies the original coefficient signs to the quantized  
// magnitude values after rate-distortion optimization is complete.  
//  
// C++ Reference: TComTrQuant.cpp::xRateDistOptQuant() lines 2515-2521  
// Formula: piDstCoeff[blkPos] = (plSrcCoeff[blkPos] < 0) ? -level : level;  
//=============================================================================
module SB_Rest#(  
    parameter int COEFF_WIDTH = 16,    // Bit-width for coefficients  
    parameter int ADDR_WIDTH = 10      // Bit-width for block position  
)(  
    input  logic                      clk,  
    input  logic                      rst_n,  
    input  logic                      start,          // Triggers the operation on the next clock edge  
      
    // Reference: TComTrQuant.cpp uses signed integers for coefficient values  
    input  logic        [COEFF_WIDTH-1:0] level,      // Absolute quantized value (treat as positive)  
    input  logic signed [COEFF_WIDTH-1:0] src_coeff,  // Original coefficient WITH SIGN  
    input  logic        [ADDR_WIDTH-1:0]  blk_pos,    // Block position  
    input  logic                      valid_in,  
  
    // Reference: TComTrQuant.cpp line 2520 - signed coefficient output  
    output logic signed [COEFF_WIDTH-1:0] dst_coeff,  // Signed quantized coefficient  
    output logic        [ADDR_WIDTH-1:0]  out_pos,    // Output position  
    output logic                      valid_out,  
    output logic                      done  
);  
  
    //==========================================================================  
    // 1. Combinational Sign Restoration Logic  
    //==========================================================================  
    // This implements the core sign application from the C++ reference:  
    // piDstCoeff[ blkPos ] = ( plSrcCoeff[ blkPos ] < 0 ) ? -level : level;  
    // Reference: TComTrQuant.cpp:2520  
    logic signed [COEFF_WIDTH-1:0] dst_coeff_comb;  
  
    always_comb begin
        // If src_coeff is negative, negate level; otherwise keep level.
        // Note: 'level' is unsigned, but '-level' implicitly casts it to signed
        // because the LHS variable (dst_coeff_comb) is signed.
        dst_coeff_comb = (src_coeff < 0) ? -level : level;
    end
  
    //==========================================================================  
    // 2. Sequential Output Registration (Pipeline Stage)  
    //==========================================================================  
    always_ff @(posedge clk or negedge rst_n) begin  
        if (!rst_n) begin  
            dst_coeff  <= '0;  
            out_pos    <= '0;  
            valid_out  <= 1'b0;  
            done       <= 1'b0;  
        end else if (start && valid_in) begin  
            // Latch the combinational result into the output register  
            // This implements the final coefficient assignment from C++  
            // Reference: TComTrQuant.cpp:2520  
            dst_coeff  <= dst_coeff_comb;  
              
            // Pass through the position information  
            // Reference: TComTrQuant.cpp uses blkPos for coefficient indexing  
            out_pos    <= blk_pos;  
              
            // Assert control signals for the next cycle  
            valid_out  <= 1'b1;  
            done       <= 1'b1;  
        end else begin  
            // Hold data values (optional, could reset them too), but clear controls  
            valid_out  <= 1'b0;  
            done       <= 1'b0;  
        end  
    end
endmodule