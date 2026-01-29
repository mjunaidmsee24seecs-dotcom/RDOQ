/**
 * Module: rdoq_distortion_calc
 * * Description:
 * Calculates the distortion cost for a candidate quantized coefficient level
 * in Rate-Distortion Optimized Quantization (RDOQ) for HEVC/VVC.
 *
 * Latency: 3 Clock Cycles
 *
 * Algorithm:
 * 1. Reconstruction: recLevel = (uiAbsLevel << i_q_bits)
 * 2. Difference:     dErr     = l_level_double - recLevel
 * 3. Square:         sqErr    = dErr * dErr
 * 4. Scale:          dist     = sqErr * error_scale
 *
 * Fixed-Point Format & Precision Guide:
 * -------------------------------------
 * This module operates on generic integer widths. The interpretation of the
 * "decimal point" is implicit and must be managed by the system integrator.
 *
 * Assumptions:
 * 1. l_level_double: Represents a Fixed-Point value in Q(I.F) format.
 * - I = Integer bits
 * - F = Fractional bits
 *
 * 2. i_q_bits:       This shift must align the integer 'ui_abs_level' to the 
 * same Q(I.F) grid as 'l_level_double'.
 * Effective Value = ui_abs_level * 2^(i_q_bits).
 *
 * 3. error_scale:    Represents a Fixed-Point value in Q(S_I.S_F) format.
 *
 * 4. distortion_out: The resulting output format is determined by the inputs:
 * - Difference Q-Format: Q(I.F)
 * - Squared Q-Format:    Q(2*I . 2*F)
 * - Output Q-Format:     Q( (2*I + S_I) . (2*F + S_F) )
 *
 * Example Configuration:
 * - If l_level_double is Q44.20 (20 fractional bits)
 * - If error_scale    is Q20.12 (12 fractional bits)
 * - Output will be Q(Int.52) -> (2*20 + 12 = 52 fractional bits).
 *
 * Synthesis Considerations:
 * -------------------------
 * - The input shift and saturation logic (Combinatorial Stage) involves a large
 * OR-reduction to detect overflow.
 * - On high-frequency targets (e.g., >800MHz ASIC or >300MHz FPGA), ensure 
 * 'ui_abs_level' and 'i_q_bits' arrive early in the clock cycle, or enable
 * register retiming/pipelining optimizations in the synthesis tool.
 */
`timescale 1ns / 1ps
module Dist_Cal#(
    parameter int LEVEL_WIDTH     = 64,  // Width of lLevelDouble (Fixed Point)
    parameter int ABS_LEVEL_WIDTH = 32,  // Width of uiAbsLevel (Integer)
    parameter int QBITS_WIDTH     = 6,   // Width of iQBits (Shift amount)
    parameter int SCALE_WIDTH     = 32,  // Width of errorScale
    // Output Width Calculation:
    // Diff (65b) -> Sq (130b) -> * Scale (32b) = 162b required for full precision
    parameter int OUT_WIDTH       = 162  
)(
    input  logic                        clk,
    input  logic                        rst_n,
    
    // Valid/Ready Handshake
    input  logic                        data_valid_in,
    
    // Inputs
    input  logic [LEVEL_WIDTH-1:0]      l_level_double, // Unquantized level (Ref: TComTrQuant.cpp)
    input  logic [ABS_LEVEL_WIDTH-1:0]  ui_abs_level,   // Candidate Quantized Level
    input  logic [QBITS_WIDTH-1:0]      i_q_bits,       // Quantization shift (scale + format align)
    input  logic [SCALE_WIDTH-1:0]      error_scale,    // Error Scale Factor
    
    // Outputs
    output logic                        data_valid_out,
    output logic [OUT_WIDTH-1:0]        distortion_out  // Format: Q(Input_Frac*2 + Scale_Frac)
);

    // =========================================================================
    // Combinatorial Pre-Computation (Overflow Protection)
    // =========================================================================
    
    // 1. Calculate required width for the shift:
    //    32-bit value shifted by max 63 bits = 95 bits.
    localparam int SHIFT_RESULT_WIDTH = ABS_LEVEL_WIDTH + (1 << QBITS_WIDTH) - 1; 
    
    logic [SHIFT_RESULT_WIDTH-1:0] raw_shifted_level;
    logic [LEVEL_WIDTH-1:0]        reconstructed_clamped;

    always_comb begin
        // Perform the full-width shift.
        // SystemVerilog handles the width expansion automatically if LHS is sized correctly,
        // but explicit padding ensures clarity.
        raw_shifted_level = {{(SHIFT_RESULT_WIDTH-ABS_LEVEL_WIDTH){1'b0}}, ui_abs_level} << i_q_bits;

        // Saturation/Clamping Logic:
        // We compare the shifted result against the bit-width of the reference level (LEVEL_WIDTH).
        // If any bits above (LEVEL_WIDTH-1) are set, we saturate to the maximum value.
        // This prevents the subtraction in Stage 1 from wrapping around incorrectly.
        // Synthesis Note: This large OR-reduction is efficient on LUT-based FPGAs but
        // check timing constraints if QBITS_WIDTH > 6.
        if (|raw_shifted_level[SHIFT_RESULT_WIDTH-1:LEVEL_WIDTH]) begin
            reconstructed_clamped = {LEVEL_WIDTH{1'b1}}; // Saturate to Max
        end else begin
            reconstructed_clamped = raw_shifted_level[LEVEL_WIDTH-1:0];
        end
    end

    // =========================================================================
    // Pipeline Stage 1: Difference Calculation
    // dErr = lLevelDouble - Clamped(uiAbsLevel << iQBits)
    // =========================================================================
    
    logic signed [LEVEL_WIDTH:0] diff_stage1; // 65 bits (1 sign + 64 magnitude)
    logic [SCALE_WIDTH-1:0]      scale_stage1;
    logic                        valid_stage1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage1  <= '0;
            scale_stage1 <= '0;
            valid_stage1 <= 1'b0;
        end else begin
            if (data_valid_in) begin
                // Calculate Signed Difference.
                // Even though inputs are unsigned, the result can be negative 
                // if the quantized reconstruction exceeds the original level.
                diff_stage1 <= $signed({1'b0, l_level_double}) - $signed({1'b0, reconstructed_clamped});
                
                // Pass through scale factor to next stage
                scale_stage1 <= error_scale;
            end
            valid_stage1 <= data_valid_in;
        end
    end

    // =========================================================================
    // Pipeline Stage 2: Square Error
    // square = dErr * dErr
    // =========================================================================

    // Width: 65 bits * 65 bits = 130 bits
    logic [2*LEVEL_WIDTH+1:0] sq_err_stage2; 
    logic [SCALE_WIDTH-1:0]   scale_stage2;
    logic                     valid_stage2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sq_err_stage2 <= '0;
            scale_stage2  <= '0;
            valid_stage2  <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Square the signed difference.
                // The result is always positive.
                // $signed * $signed hints DSP usage to synthesis tools.
                sq_err_stage2 <= $signed(diff_stage1) * $signed(diff_stage1);
                
                scale_stage2  <= scale_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // =========================================================================
    // Pipeline Stage 3: Apply Error Scale
    // distortion = square * errorScale
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            distortion_out <= '0;
            data_valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Final Multiplication.
                // Input 1: sq_err_stage2 (approx 130 bits, Positive)
                // Input 2: scale_stage2  (32 bits, Unsigned)
                // Result fits within OUT_WIDTH (162 bits).
                distortion_out <= sq_err_stage2 * scale_stage2;
            end
            data_valid_out <= valid_stage2;
        end
    end
endmodule