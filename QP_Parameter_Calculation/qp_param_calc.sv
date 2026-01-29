module qp_param_calc #(
parameter int TABLE_LEN = 58
)(
input  logic              isLuma,          // 1 = Luma, 0 = Chroma
input  logic signed [7:0] qpy,
input  logic signed [7:0] qpBdOffset,
input  logic signed [7:0] chromaQPOffset,
input  logic [1:0]        chFmt,           // 0..3
output logic signed [7:0] Qp,
output logic [4:0]        per,            // period = Qp / 6
output logic [2:0]        rem             // remainder = Qp % 6
);

// Internal signals
logic signed [15:0] qp_pre;
logic signed [15:0] clipped_qp;
logic [7:0] mapped_chroma_qp;
logic [$clog2(TABLE_LEN)-1:0] rom_addr;

// Instantiate Clip3 with correct parameters
clip3 #(.MIN_VAL(-52), .MAX_VAL(TABLE_LEN-1)) clip_val (
.x(qp_pre),
.y(clipped_qp)
);

// Safe ROM address calculation - prevent negative addresses
assign rom_addr = (clipped_qp < 0) ? 6'd0 : clipped_qp[$clog2(TABLE_LEN)-1:0];

// Instantiate Chroma Mapping ROM
chroma_scale_rom chroma_rom (
.fmt(chFmt),
.addr(rom_addr),
.data(mapped_chroma_qp)
);

// QP Computation
always_comb begin
// Luma path
if (isLuma) begin
Qp = qpy + qpBdOffset;
end
// Chroma path
else begin
qp_pre = qpy + chromaQPOffset;   // before Clip3

// After Clip3 ? clipped_qp
if (clipped_qp < 0) begin
Qp = clipped_qp + qpBdOffset;    // negative path
end else begin
Qp = mapped_chroma_qp + qpBdOffset;  // scaled chroma path
end
end

// Calculate period and remainder
per = Qp / 6;
rem = Qp % 6;
end
endmodule