module golomb_rice_calc #(
parameter COEF_REMAIN_BIN_REDUCTION = 3
) (
input  logic        clk,
input  logic        rst_n,
input  logic        start,
input  logic [15:0] symbol,
input  logic [15:0] ui16AbsGoRice,
input  logic        useLimitedPrefixLength,
input  logic [4:0]  maxLog2TrDynamicRange,
output logic [7:0]  suffix_length,
output logic [15:0] total_bits,
output logic        done
);

logic [7:0]  prefixLength;
logic [15:0] suffix;
logic [7:0]  length;
logic [15:0] temp_symbol;
logic [4:0]  maximumPrefixLength;
logic done_reg;

always_ff @(posedge clk or negedge rst_n) begin
if (!rst_n) begin
suffix_length <= 0;
total_bits    <= 0;
done_reg      <= 0;
end else if (start) begin
// Path 3a: Short symbol path
if (symbol < (COEF_REMAIN_BIN_REDUCTION << ui16AbsGoRice)) begin
length = symbol >> ui16AbsGoRice;
total_bits <= length + 1 + ui16AbsGoRice;
suffix_length <= ui16AbsGoRice[7:0];
end
// Path 3b: Limited prefix length path
else if (useLimitedPrefixLength) begin
maximumPrefixLength = 32 - (COEF_REMAIN_BIN_REDUCTION + maxLog2TrDynamicRange);
prefixLength = 0;
suffix = (symbol >> ui16AbsGoRice) - COEF_REMAIN_BIN_REDUCTION;

for (int i = 0; i < 32; i++) begin
if (prefixLength < maximumPrefixLength && suffix > ((2 << prefixLength) - 2))
    prefixLength = prefixLength + 1;
end

if (prefixLength == maximumPrefixLength)
suffix_length <= maxLog2TrDynamicRange - ui16AbsGoRice[4:0];
else
suffix_length <= prefixLength + 1;

total_bits <= COEF_REMAIN_BIN_REDUCTION + prefixLength + suffix_length + ui16AbsGoRice;
end
// Path 3c: Unlimited prefix length path
else begin
length = ui16AbsGoRice[7:0];
temp_symbol = symbol - (COEF_REMAIN_BIN_REDUCTION << ui16AbsGoRice);

for (int i = 0; i < 16; i++) begin
if (temp_symbol >= (1 << length)) begin
    temp_symbol = temp_symbol - (1 << length);
    length = length + 1;
end
end

total_bits <= COEF_REMAIN_BIN_REDUCTION + length + 1 - ui16AbsGoRice + length;
suffix_length <= length;
end

done_reg <= 1'b1; // latch done
end
end

assign done = done_reg;

endmodule
