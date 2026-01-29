module rom_16x16_patterns (
    input  logic [1:0] scan_type,   // 0=diag, 1=hor, 2=ver
    input  logic [7:0] address,     // 0-255
    output logic [8:0] data         // 0-255
);

    logic [8:0] rom_diag [0:255];
    logic [8:0] rom_hor  [0:255];
    logic [8:0] rom_ver  [0:255];

    //============================================================
    // ROM Initialization
    //============================================================
    integer x, y, s, j, cnt;
    always_comb begin

        // ---------- HEVC 16x16 DIAGONAL ----------
        cnt = 0;
        for (s = 0; s <= 30; s++) begin
            if (s < 16) begin
                for (j = 0; j <= s; j++) begin
                    if (s[0] == 0) begin
                        x = s - j; y = j;
                    end else begin
                        x = j; y = s - j;
                    end
                    rom_diag[cnt] = (x << 4) | y;
                    cnt++;
                end
            end else begin
                for (j = 0; j < 31 - s; j++) begin
                    if (s[0] == 0) begin
                        x = 15 - j; y = s - 15 + j;
                    end else begin
                        x = s - 15 + j; y = 15 - j;
                    end
                    rom_diag[cnt] = (x << 4) | y;
                    cnt++;
                end
            end
        end

        // ---------- HORIZONTAL ----------
        for (int i = 0; i < 256; i++)
            rom_hor[i] = i;

        // ---------- VERTICAL ----------
        for (int col = 0; col < 16; col++)
            for (int row = 0; row < 16; row++)
                rom_ver[col*16 + row] = row*16 + col;
    end

    //============================================================
    // Output MUX
    //============================================================
    always_comb begin
        case (scan_type)
            2'd0: data = rom_diag[address];
            2'd1: data = rom_hor[address];
            2'd2: data = rom_ver[address];
            default: data = rom_diag[address];
        endcase
    end

endmodule
