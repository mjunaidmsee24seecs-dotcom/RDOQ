module initial_quantization_unit (  
// Clock and reset  
input  logic        clk,  
input  logic        rst_n,  

// Inputs  
input  logic signed [15:0]  plSrcCoeff,           // Transform coefficient (16-bit signed)  
input  logic [15:0]         quantCoeff,           // Quantization coefficient from Module 2  
input  logic [5:0]          iQBits,               // Quantization bits from Module 4  
input  logic signed [31:0]  entropyCodingMaximum, // Max value for entropy coding (32-bit for HEVC)  

// Outputs  
output logic [31:0]         lLevelDouble,         // Unquantized level (scaled coefficient)  
output logic [15:0]         uiMaxAbsLevel,        // Maximum quantized level  
output logic                valid_out             // Output valid signal  
);  

// Internal signals  
logic signed [15:0] absCoeff;  
logic signed [31:0] tmpLevel;  
logic [31:0]        roundingOffset;  
logic [31:0]        roundedLevel;  

// Pipeline registers for multi-cycle operation  
logic [31:0]        lLevelDouble_reg;  
logic [15:0]        uiMaxAbsLevel_reg;  
logic [5:0]         iQBits_stage1, iQBits_stage2;
logic signed [31:0] entropyCodingMaximum_stage1, entropyCodingMaximum_stage2;
logic               valid_stage1, valid_stage2;  

// Constants  
localparam MAX_INTERMEDIATE_VALUE = 32'h7FFFFFFF; // Max 32-bit signed value  

// Stage 1: Absolute value and multiplication  
always_ff @(posedge clk or negedge rst_n) begin  
if (!rst_n) begin  
absCoeff <= 16'd0;  
tmpLevel <= 32'd0;  
iQBits_stage1 <= 6'd0;
entropyCodingMaximum_stage1 <= 32'd0;
valid_stage1 <= 1'b0;  
end else begin  
// Take absolute value of input coefficient  
absCoeff <= (plSrcCoeff < 0) ? -plSrcCoeff : plSrcCoeff;  

// Multiply by quantization coefficient (16-bit × 16-bit = 32-bit)  
tmpLevel <= $signed(absCoeff) * $signed(quantCoeff);  

// Pipeline control signals
iQBits_stage1 <= iQBits;
entropyCodingMaximum_stage1 <= entropyCodingMaximum;

valid_stage1 <= 1'b1;  
end  
end  

// Stage 2: Saturation (lLevelDouble calculation)  
always_ff @(posedge clk or negedge rst_n) begin  
if (!rst_n) begin  
lLevelDouble_reg <= 32'd0;  
iQBits_stage2 <= 6'd0;
entropyCodingMaximum_stage2 <= 32'd0;
valid_stage2 <= 1'b0;  
end else if (valid_stage1) begin  
// Saturate to MAX_VALUE to prevent overflow  
if (tmpLevel > MAX_INTERMEDIATE_VALUE) begin  
lLevelDouble_reg <= MAX_INTERMEDIATE_VALUE;  
end else begin  
lLevelDouble_reg <= tmpLevel;  
end  

// Pipeline control signals
iQBits_stage2 <= iQBits_stage1;
entropyCodingMaximum_stage2 <= entropyCodingMaximum_stage1;

valid_stage2 <= 1'b1;  
end else begin  
valid_stage2 <= 1'b0;  
end  
end  

// Stage 3: Quantization with rounding  
always_ff @(posedge clk or negedge rst_n) begin  
if (!rst_n) begin  
uiMaxAbsLevel_reg <= 16'd0;  
valid_out <= 1'b0;  
end else if (valid_stage2) begin  
// Calculate rounding offset: (1 << (iQBits-1))  
roundingOffset <= (32'd1 << (iQBits_stage2 - 1));  

// Add rounding offset and right shift  
roundedLevel <= (lLevelDouble_reg + roundingOffset) >> iQBits_stage2;  

// Clip to entropy coding maximum  
if (roundedLevel > entropyCodingMaximum_stage2) begin  
uiMaxAbsLevel_reg <= entropyCodingMaximum_stage2[15:0];  
end else begin  
uiMaxAbsLevel_reg <= roundedLevel[15:0];  
end  

valid_out <= 1'b1;  
end else begin  
valid_out <= 1'b0;  
end  
end  

// Output assignments  
assign lLevelDouble = lLevelDouble_reg;  
assign uiMaxAbsLevel = uiMaxAbsLevel_reg;  

endmodule