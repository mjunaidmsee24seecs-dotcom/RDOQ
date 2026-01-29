
module scaling_coeff_lut_simple #(
parameter int COEFF_WIDTH = 16,
parameter int ERROR_SCALE_WIDTH = 32
)(
// Inputs
input  logic [2:0]         qp_rem,           // QP % 6 (0-5)
input  logic [4:0]         iTransformShift,  // From Module 3  
input  logic [2:0]         channelBitDepth,  // Bit depth (8, 10, 12)

// Outputs  
output logic [COEFF_WIDTH-1:0]      piQCoef,      // Quantization coefficient
output logic [ERROR_SCALE_WIDTH-1:0] pdErrScale,  // Error scale

// Control
input  logic                     clk,
input  logic                     enable
);

// ROM for base quantization scales (EXACT HM VALUES)
localparam logic [15:0] g_quantScales [0:5] = 
'{16'd26214, 16'd23302, 16'd20560, 16'd18396, 16'd16384, 16'd14564};

// Quantization coefficient (direct lookup)
always_ff @(posedge clk) begin
if (enable) begin
piQCoef <= g_quantScales[qp_rem];
end
end

// Error scale computation
always_comb begin
automatic logic [31:0] scale_bits = (32'd1 << 15);      // SCALE_BITS = 15
logic [31:0] base_err_scale;
logic [31:0] quant_coeff_squared;
logic [4:0]  distortion_shift;

// Apply transform shift
base_err_scale = scale_bits >> (2 * iTransformShift);

// Quant coefficient squared  
quant_coeff_squared = piQCoef * piQCoef;

// Bit depth adjustment
distortion_shift = (channelBitDepth > 0) ? (2 * channelBitDepth) : 0;

// Final error scale computation
if (quant_coeff_squared == 0 || base_err_scale == 0) begin
pdErrScale = {ERROR_SCALE_WIDTH{1'b1}};
end else begin
pdErrScale = (base_err_scale << 16) / quant_coeff_squared;
pdErrScale = pdErrScale >> distortion_shift;
end
end

endmodule
