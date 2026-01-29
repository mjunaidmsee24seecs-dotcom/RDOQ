module chroma_scale_rom #(
parameter int TABLE_LEN = 58
)(
input  logic [1:0] fmt,
input  logic [$clog2(TABLE_LEN)-1:0] addr,
output logic [7:0] data
);
always_comb begin
case (fmt)
// Format 0: 4:0:0 (no chroma) - all zeros
2'd0: begin
data = 8'd0;
end

// Format 1: 4:2:0 - Main HEVC chroma format
2'd1: begin
case (addr)
// Exact mapping from HEVC specification
0: data=0;   1: data=1;   2: data=2;   3: data=3;
4: data=4;   5: data=5;   6: data=6;   7: data=7;
8: data=8;   9: data=9;  10: data=10; 11: data=11;
12: data=12; 13: data=13; 14: data=14; 15: data=15;
16: data=16; 17: data=17; 18: data=18; 19: data=19;
20: data=20; 21: data=21; 22: data=22; 23: data=23;
24: data=24; 25: data=25; 26: data=26; 27: data=27;
28: data=28; 29: data=29; 30: data=29; 31: data=30;
32: data=31; 33: data=32; 34: data=33; 35: data=33;
36: data=34; 37: data=34; 38: data=35; 39: data=35;
40: data=36; 41: data=36; 42: data=37; 43: data=37;
44: data=38; 45: data=39; 46: data=40; 47: data=41;
48: data=42; 49: data=43; 50: data=44; 51: data=45;
52: data=46; 53: data=47; 54: data=48; 55: data=49;
56: data=50; 57: data=51;
default: data = 8'd0;
endcase
end

// Format 2: 4:2:2 (for completeness)
2'd2: begin
case (addr)
0: data=0;   1: data=1;   2: data=2;   3: data=3;
4: data=4;   5: data=5;   6: data=6;   7: data=7;
8: data=8;   9: data=9;  10: data=10; 11: data=11;
12: data=12; 13: data=13; 14: data=14; 15: data=15;
16: data=16; 17: data=17; 18: data=18; 19: data=19;
20: data=20; 21: data=21; 22: data=22; 23: data=23;
24: data=24; 25: data=25; 26: data=26; 27: data=27;
28: data=28; 29: data=29; 30: data=30; 31: data=31;
32: data=32; 33: data=33; 34: data=34; 35: data=35;
36: data=36; 37: data=37; 38: data=38; 39: data=39;
40: data=40; 41: data=41; 42: data=42; 43: data=43;
44: data=44; 45: data=45; 46: data=46; 47: data=47;
48: data=48; 49: data=49; 50: data=50; 51: data=51;
52: data=51; 53: data=51; 54: data=51; 55: data=51;
56: data=51; 57: data=51;
default: data = 8'd0;
endcase
end

// Format 3: 4:4:4 (for completeness)
2'd3: begin
case (addr)
0: data=0;   1: data=1;   2: data=2;   3: data=3;
4: data=4;   5: data=5;   6: data=6;   7: data=7;
8: data=8;   9: data=9;  10: data=10; 11: data=11;
12: data=12; 13: data=13; 14: data=14; 15: data=15;
16: data=16; 17: data=17; 18: data=18; 19: data=19;
20: data=20; 21: data=21; 22: data=22; 23: data=23;
24: data=24; 25: data=25; 26: data=26; 27: data=27;
28: data=28; 29: data=29; 30: data=30; 31: data=31;
32: data=32; 33: data=33; 34: data=34; 35: data=35;
36: data=36; 37: data=37; 38: data=38; 39: data=39;
40: data=40; 41: data=41; 42: data=42; 43: data=43;
44: data=44; 45: data=45; 46: data=46; 47: data=47;
48: data=48; 49: data=49; 50: data=50; 51: data=51;
52: data=51; 53: data=51; 54: data=51; 55: data=51;
56: data=51; 57: data=51;
default: data = 8'd0;
endcase
end
endcase
end
endmodule