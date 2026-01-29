module rom_coefficient_groups (
input  logic [1:0] log2WidthInGroups,   // 0=1, 1=2, 2=4, 3=8
input  logic [1:0] log2HeightInGroups,  // 0=1, 1=2, 2=4, 3=8
input  logic [5:0] address,             // CG position
output logic [6:0] data                  // up to 63
);

// ROMs
logic [6:0] rom_1x1 [0:0];
logic [6:0] rom_2x2 [0:3];
logic [6:0] rom_4x4 [0:15];
logic [6:0] rom_8x8 [0:63];

integer x, y, s, j, cnt;

// ---------------------------
// ROM Initialization
// ---------------------------
always_comb begin
// -------- 1×1 --------
rom_1x1[0] = 0;

// -------- 2×2 (HEVC zig-zag) --------
rom_2x2[0] = 0;
rom_2x2[1] = 1;
rom_2x2[2] = 3;
rom_2x2[3] = 2;

// -------- 4×4 (correct as you had) --------
rom_4x4[0]  = 0;  rom_4x4[1]  = 1;  rom_4x4[2]  = 4;  rom_4x4[3]  = 5;
rom_4x4[4]  = 2;  rom_4x4[5]  = 3;  rom_4x4[6]  = 6;  rom_4x4[7]  = 7;
rom_4x4[8]  = 8;  rom_4x4[9]  = 9;  rom_4x4[10] = 12; rom_4x4[11] = 13;
rom_4x4[12] = 10; rom_4x4[13] = 11; rom_4x4[14] = 14; rom_4x4[15] = 15;

// -------- 8×8 CG GRID (FULL HEVC ZIG-ZAG) --------
cnt = 0;
for (s = 0; s <= 14; s++) begin
if (s < 8) begin
for (j = 0; j <= s; j++) begin
if (s[0] == 0) begin
x = s - j; y = j;
end else begin
x = j; y = s - j;
end
rom_8x8[cnt++] = (x << 3) | y;
end
end else begin
for (j = 0; j < 15 - s; j++) begin
if (s[0] == 0) begin
x = 7 - j; y = s - 7 + j;
end else begin
x = s - 7 + j; y = 7 - j;
end
rom_8x8[cnt++] = (x << 3) | y;
end
end
end
end

// ---------------------------
// Output Selection
// ---------------------------
always_comb begin
data = 0;

if (log2WidthInGroups == log2HeightInGroups) begin
case (log2WidthInGroups)
2'd0: if (address < 1)  data = rom_1x1[address];
2'd1: if (address < 4)  data = rom_2x2[address];
2'd2: if (address < 16) data = rom_4x4[address];
2'd3: if (address < 64) data = rom_8x8[address];
default: data = 0;
endcase
end else begin
// Rectangular groups ? linear order (HEVC allowed)
if (address < 64)
data = address;
else
data = 0;
end
end

endmodule
