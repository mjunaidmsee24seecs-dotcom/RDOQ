//==============================================================================
// Module: rom_4x4_patterns
// Description: ROM containing all 4x4 scan patterns (HEVC compliant)
//==============================================================================
module rom_4x4_patterns (
    input  logic [1:0] scan_type,      // 0=diag, 1=hor, 2=ver
    input  logic [3:0] address,        // 0-15
    output logic [4:0] data            // Scan address (0-15)
);

    // Internal ROM arrays
    logic [4:0] rom_diag [0:15];
    logic [4:0] rom_hor  [0:15];
    logic [4:0] rom_ver  [0:15];

    //--------------------------------------------------------------------------
    // ROM Initialization (Pure Combinational, Synthesizable)
    //--------------------------------------------------------------------------
    always_comb begin
        // ? HEVC STANDARD 4x4 DIAGONAL SCAN
        rom_diag[0]  = 5'd0;
        rom_diag[1]  = 5'd1;
        rom_diag[2]  = 5'd4;
        rom_diag[3]  = 5'd5;
        rom_diag[4]  = 5'd2;
        rom_diag[5]  = 5'd3;
        rom_diag[6]  = 5'd6;
        rom_diag[7]  = 5'd7;
        rom_diag[8]  = 5'd8;
        rom_diag[9]  = 5'd9;
        rom_diag[10] = 5'd12;
        rom_diag[11] = 5'd13;
        rom_diag[12] = 5'd10;
        rom_diag[13] = 5'd11;
        rom_diag[14] = 5'd14;
        rom_diag[15] = 5'd15;

        // ? Horizontal scan pattern (row-major)
        rom_hor[0]  = 5'd0;   rom_hor[1]  = 5'd1;   rom_hor[2]  = 5'd2;   rom_hor[3]  = 5'd3;
        rom_hor[4]  = 5'd4;   rom_hor[5]  = 5'd5;   rom_hor[6]  = 5'd6;   rom_hor[7]  = 5'd7;
        rom_hor[8]  = 5'd8;   rom_hor[9]  = 5'd9;   rom_hor[10] = 5'd10;  rom_hor[11] = 5'd11;
        rom_hor[12] = 5'd12;  rom_hor[13] = 5'd13;  rom_hor[14] = 5'd14;  rom_hor[15] = 5'd15;

        // ? Vertical scan pattern (column-major)
        rom_ver[0]  = 5'd0;   rom_ver[1]  = 5'd4;   rom_ver[2]  = 5'd8;   rom_ver[3]  = 5'd12;
        rom_ver[4]  = 5'd1;   rom_ver[5]  = 5'd5;   rom_ver[6]  = 5'd9;   rom_ver[7]  = 5'd13;
        rom_ver[8]  = 5'd2;   rom_ver[9]  = 5'd6;   rom_ver[10] = 5'd10;  rom_ver[11] = 5'd14;
        rom_ver[12] = 5'd3;   rom_ver[13] = 5'd7;   rom_ver[14] = 5'd11;  rom_ver[15] = 5'd15;
    end

    //--------------------------------------------------------------------------
    // Output MUX
    //--------------------------------------------------------------------------
    always_comb begin
        case (scan_type)
            2'd0: data = rom_diag[address]; // ? HEVC Diagonal
            2'd1: data = rom_hor[address];  // ? Horizontal
            2'd2: data = rom_ver[address];  // ? Vertical
            default: data = rom_diag[address];
        endcase
    end

endmodule
