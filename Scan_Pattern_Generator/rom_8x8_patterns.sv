//==============================================================================
// Module: rom_8x8_patterns
// Description: ROM containing all 8x8 HEVC scan patterns
//==============================================================================
module rom_8x8_patterns (
    input  logic [1:0] scan_type,      // 0=diag, 1=hor, 2=ver
    input  logic [5:0] address,        // 0-63
    output logic [6:0] data            // Scan address (0-63)
);

    // Internal ROM arrays
    logic [6:0] rom_diag [0:63];
    logic [6:0] rom_hor  [0:63];
    logic [6:0] rom_ver  [0:63];

    //==========================================================================
    // ROM Initialization (HEVC Standard)
    //==========================================================================
    always_comb begin
        // -------------------------------
        // ? HEVC 8x8 DIAGONAL (ZIG-ZAG)
        // -------------------------------
        rom_diag[ 0] =  0;  rom_diag[ 1] =  1;  rom_diag[ 2] =  8;  rom_diag[ 3] = 16;
        rom_diag[ 4] =  9;  rom_diag[ 5] =  2;  rom_diag[ 6] =  3;  rom_diag[ 7] = 10;
        rom_diag[ 8] = 17;  rom_diag[ 9] = 24;  rom_diag[10] = 32;  rom_diag[11] = 25;
        rom_diag[12] = 18;  rom_diag[13] = 11;  rom_diag[14] =  4;  rom_diag[15] =  5;

        rom_diag[16] = 12;  rom_diag[17] = 19;  rom_diag[18] = 26;  rom_diag[19] = 33;
        rom_diag[20] = 40;  rom_diag[21] = 48;  rom_diag[22] = 41;  rom_diag[23] = 34;
        rom_diag[24] = 27;  rom_diag[25] = 20;  rom_diag[26] = 13;  rom_diag[27] =  6;

        rom_diag[28] =  7;  rom_diag[29] = 14;  rom_diag[30] = 21;  rom_diag[31] = 28;
        rom_diag[32] = 35;  rom_diag[33] = 42;  rom_diag[34] = 49;  rom_diag[35] = 56;
        rom_diag[36] = 57;  rom_diag[37] = 50;  rom_diag[38] = 43;  rom_diag[39] = 36;

        rom_diag[40] = 29;  rom_diag[41] = 22;  rom_diag[42] = 15;  rom_diag[43] = 23;
        rom_diag[44] = 30;  rom_diag[45] = 37;  rom_diag[46] = 44;  rom_diag[47] = 51;

        rom_diag[48] = 58;  rom_diag[49] = 59;  rom_diag[50] = 52;  rom_diag[51] = 45;
        rom_diag[52] = 38;  rom_diag[53] = 31;  rom_diag[54] = 39;  rom_diag[55] = 46;

        rom_diag[56] = 53;  rom_diag[57] = 60;  rom_diag[58] = 61;  rom_diag[59] = 54;
        rom_diag[60] = 47;  rom_diag[61] = 55;  rom_diag[62] = 62;  rom_diag[63] = 63;

        // -------------------------------
        // ? HORIZONTAL (ROW-MAJOR)
        // -------------------------------
        for (int i = 0; i < 64; i++) begin
            rom_hor[i] = i;
        end

        // -------------------------------
        // ? VERTICAL (COLUMN-MAJOR)
        // -------------------------------
        for (int col = 0; col < 8; col++) begin
            for (int row = 0; row < 8; row++) begin
                rom_ver[col*8 + row] = row*8 + col;
            end
        end
    end

    //==========================================================================
    // Output MUX
    //==========================================================================
    always_comb begin
        case (scan_type)
            2'd0: data = rom_diag[address];   // Diagonal (HEVC Zig-Zag)
            2'd1: data = rom_hor[address];    // Horizontal
            2'd2: data = rom_ver[address];    // Vertical
            default: data = rom_diag[address];
        endcase
    end

endmodule
