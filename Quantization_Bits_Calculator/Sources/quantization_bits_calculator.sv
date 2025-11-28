module QuantBitsCalculator (
    input [4:0]  cQP_per,        // 5-bit input: 0-9 (baseQp/6)
    input [5:0]  iTransformShift, // 5-bit input: 0-10
    output [5:0] iQBits          // 6-bit output: 14-33
);

// Since cQP_per is only 0-9, we can use 5-bit arithmetic
wire [5:0] temp_sum;  // Need 6 bits for 14+9=23
wire [5:0] iTransformShift_ext; // Zero-extended

assign iTransformShift_ext = {1'b0, iTransformShift}; // 5-bit ? 6-bit
assign temp_sum = 6'd14 + {1'b0, cQP_per};  // 14 + (0-9)
assign iQBits = temp_sum + iTransformShift_ext; // Final sum

endmodule