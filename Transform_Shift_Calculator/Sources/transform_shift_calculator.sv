`timescale 1ns / 1ps
// Module: Transform Shift Calculator
// Description: Calculates the bit shift amount for transform scaling in RDOQ.
//              Formula: shift = maxLog2TrDynamicRange - channelBitDepth - log2TrSize.
//
//              Updates based on C++ Reference:
//              - Added 'extended_precision_processing' input.
//              - Logic: if (use_transform_skip && extended_precision_processing && shift < 0) -> clamp to 0.
//              - Otherwise: allow negative shift (left shift) as per standard precision rules.

module transform_shift_calculator (
    input  logic [3:0] channel_bit_depth,         // Input: Bit depth (e.g., 8, 10, 12)
    input  logic [2:0] log2_tr_size,              // Input: Log2 of transform block size
    input  logic [4:0] max_log2_tr_dynamic_range, // Input: Dynamic range limit
    input  logic         use_transform_skip,        // Input: Transform Skip Flag
    input  logic         extended_precision_processing, // Input: Extended Precision Flag (matches C++ 'extendedPrecision')
    
    output logic signed [5:0] i_transform_shift   // Output: Calculated shift value
);

    logic signed [6:0] base_shift; 

    always_comb begin
        // 1. Calculate Base Shift
        //    iTransformShift = maxLog2TrDynamicRange - channelBitDepth - uiLog2TrSize
        base_shift = $signed({2'b0, max_log2_tr_dynamic_range}) - $signed({2'b0, channel_bit_depth}) - $signed({2'b0, log2_tr_size});

        // 2. Conditional Clamping
        //    C++ Ref: if (transformSkip != 0 && extendedPrecision) iTransformShift = max(0, iTransformShift)
        //    This ensures we only clamp negative shifts when specifically in Extended Precision mode.
        if (use_transform_skip && extended_precision_processing) begin
            if (base_shift < 0) begin
                i_transform_shift = 6'sd0;
            end else begin
                i_transform_shift = base_shift[5:0];
            end
        end else begin
            // Default behavior:
            // If TS is off, OR if we are in TS mode but Extended Precision is NOT enabled,
            // the negative shift (left shift) is preserved.
            i_transform_shift = base_shift[5:0];
        end
    end

endmodule
