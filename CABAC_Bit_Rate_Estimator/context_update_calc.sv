module context_update_calc (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        update_start,
    input  logic [2:0]  current_state,
    input  logic        current_mps,
    input  logic        coded_bin,
    input  logic [15:0] current_cost,
    output logic [2:0]  next_state,
    output logic        next_mps,
    output logic [15:0] updated_cost,
    output logic        update_done
);

    logic done_reg;

    // -----------------------------
    // SYNTHESIZABLE STATE LOGIC
    // -----------------------------
    function automatic [2:0] mps_next (input [2:0] s);
        if (s == 3'd7)
            mps_next = 3'd7;
        else
            mps_next = s + 3'd1;
    endfunction

    function automatic [2:0] lps_next (input [2:0] s);
        if (s == 3'd0)
            lps_next = 3'd0;
        else if (s < 3'd4)
            lps_next = s >> 1;
        else
            lps_next = s - 3'd1;
    endfunction

    // -----------------------------
    // SEQUENTIAL UPDATE (FIXED)
    // -----------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state   <= 3'd0;
            next_mps     <= 1'b0;
            updated_cost <= 16'd0;
            done_reg     <= 1'b0;

        end else if (update_start) begin

            // ? DIRECT decision (no stale is_mps)
            if (coded_bin == current_mps) begin
                // -------- MPS --------
                next_state   <= mps_next(current_state);
                next_mps     <= current_mps;
                updated_cost <= current_cost + 16'h00FF;  // ? applied immediately

            end else begin
                // -------- LPS --------
                next_state   <= lps_next(current_state);
                next_mps     <= (current_state == 0) ? ~current_mps : current_mps;
                updated_cost <= current_cost + 16'h0001;  // ? applied immediately
            end

            done_reg <= 1'b1;

        end else begin
            done_reg <= 1'b0;
        end
    end

    assign update_done = done_reg;

endmodule
