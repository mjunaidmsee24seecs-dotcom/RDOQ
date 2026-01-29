module rom_32x32_patterns (
    input  logic [1:0] scan_type,   // 0=diag, 1=hor, 2=ver
    input  logic [9:0] address,     // 0-1023
    output logic [9:0] data
);

    logic [9:0] rom_diag [0:1023];
    logic [9:0] rom_hor  [0:1023];
    logic [9:0] rom_ver  [0:1023];

    integer x, y, s, j, cnt;

    always_comb begin
        // ------------------ DIAGONAL ------------------
        cnt = 0;
        for (s = 0; s <= 62; s++) begin
            if (s < 32) begin
                for (j = 0; j <= s; j++) begin
                    if (s[0] == 0) begin
                        x = s - j; y = j;
                    end else begin
                        x = j; y = s - j;
                    end
                    rom_diag[cnt] = (x << 5) | y;
                    cnt++;
                end
            end else begin
                for (j = 0; j < 63 - s; j++) begin
                    if (s[0] == 0) begin
                        x = 31 - j; y = s - 31 + j;
                    end else begin
                        x = s - 31 + j; y = 31 - j;
                    end
                    rom_diag[cnt] = (x << 5) | y;
                    cnt++;
                end
            end
        end

        // ------------------ HORIZONTAL ------------------
        for (int i = 0; i < 1024; i++)
            rom_hor[i] = i;

        // ------------------ VERTICAL ------------------
        for (int col = 0; col < 32; col++)
            for (int row = 0; row < 32; row++)
                rom_ver[col*32 + row] = row*32 + col;
    end

    always_comb begin
        case (scan_type)
            2'd0: data = rom_diag[address];
            2'd1: data = rom_hor[address];
            2'd2: data = rom_ver[address];
            default: data = rom_diag[address];
        endcase
    end

endmodule
