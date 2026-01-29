module rom_mux_controller (
    input  logic [2:0] log2BlockWidth,
    input  logic [2:0] log2BlockHeight,
    input  logic [1:0] scanType,
    input  logic [9:0] scanPosition,

    input  logic [4:0] rom_4x4_data,
    input  logic [6:0] rom_8x8_data,
    input  logic [8:0] rom_16x16_data,
    input  logic [9:0] rom_32x32_data,

    output logic [9:0] scanAddress,
    output logic [4:0] rom_4x4_addr,
    output logic [5:0] rom_8x8_addr,
    output logic [7:0] rom_16x16_addr,
    output logic [9:0] rom_32x32_addr,
    output logic [1:0] rom_4x4_scan_type,
    output logic [1:0] rom_8x8_scan_type,
    output logic [1:0] rom_16x16_scan_type,
    output logic [1:0] rom_32x32_scan_type
);

always_comb begin
    // --------------------
    // DEFAULTS
    // --------------------
    rom_4x4_addr       = 0;
    rom_8x8_addr       = 0;
    rom_16x16_addr     = 0;
    rom_32x32_addr     = 0;

    rom_4x4_scan_type   = scanType;
    rom_8x8_scan_type   = scanType;
    rom_16x16_scan_type = scanType;
    rom_32x32_scan_type = scanType;

    scanAddress = scanPosition;

    // --------------------
    // ONLY USE ROMS FOR *SQUARE* BLOCKS
    // --------------------
    if (log2BlockWidth == log2BlockHeight) begin
        case (log2BlockWidth)

        3'd2: begin // 4×4
            rom_4x4_addr = scanPosition[3:0];
            scanAddress  = rom_4x4_data;
        end

        3'd3: begin // 8×8
            rom_8x8_addr = scanPosition[5:0];
            scanAddress  = rom_8x8_data;
        end

        3'd4: begin // 16×16
            rom_16x16_addr = scanPosition[7:0];
            scanAddress    = rom_16x16_data;
        end

        3'd5: begin // 32×32
            rom_32x32_addr = scanPosition[9:0];
            scanAddress    = rom_32x32_data;
        end

        default: begin
            scanAddress = scanPosition;
        end
        endcase
    end
    else begin
        // --------------------
        // RECTANGULAR BLOCK FALLBACK (HEVC SAFE)
        // --------------------
        case (scanType)
            2'd0: scanAddress = scanPosition; // diag fallback (linear)
            2'd1: scanAddress = scanPosition; // horizontal
            2'd2: scanAddress = scanPosition; // vertical handled elsewhere
            default: scanAddress = scanPosition;
        endcase
    end
end

endmodule
