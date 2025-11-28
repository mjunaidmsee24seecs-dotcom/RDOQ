`timescale 1ns/1ps

module tb_context_bit_regfile_corner;

  localparam NUM_CTX  = 8;
  localparam CTX_TYPE = 0;

  logic        clk;
  logic        rst_n;

  logic        we;
  logic [7:0]  ctx_addr;
  logic        bin_val;
  logic [15:0] bit_cost_in;

  logic [4:0]  read_ctx_addr;
  logic        read_bin_sel;

  logic [15:0] bit_cost_out;
  logic [15:0] bit_cost_out0;
  logic [15:0] bit_cost_out1;

  // DUT
  context_bit_regfile #(
    .NUM_CTX(NUM_CTX),
    .CTX_TYPE(CTX_TYPE)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .we(we),
    .ctx_addr(ctx_addr),
    .bin_val(bin_val),
    .bit_cost_in(bit_cost_in),
    .read_ctx_addr(read_ctx_addr),
    .read_bin_sel(read_bin_sel),
    .bit_cost_out(bit_cost_out),
    .bit_cost_out0(bit_cost_out0),
    .bit_cost_out1(bit_cost_out1)
  );

  // Clock
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    we = 0;
    ctx_addr = 0;
    bin_val = 0;
    bit_cost_in = 0;
    read_ctx_addr = 0;
    read_bin_sel = 0;

    // ============================================================
    // 1. RESET BEHAVIOR
    // ============================================================
    $display("\n--- [TEST 1] Reset Verification ---");
    #20 rst_n = 1;

    read_ctx_addr = 2;
    read_bin_sel  = 1;
    #5;
    $display("Reset Read ctx=2 bin=1 -> %h", bit_cost_out);

    // ============================================================
    // 2. OUT-OF-RANGE READ
    // ============================================================
    $display("\n--- [TEST 2] Out-of-Range Read ---");
    read_ctx_addr = 31;   // Invalid
    read_bin_sel  = 1;
    #5;
    if (bit_cost_out == 16'd0)
      $display("PASS: Invalid read returned 0");
    else
      $display("FAIL: Invalid read returned %h", bit_cost_out);

    // ============================================================
    // 3. OUT-OF-RANGE WRITE (SHOULD BE IGNORED)
    // ============================================================
    $display("\n--- [TEST 3] Out-of-Range Write ---");
    we = 1;
    ctx_addr = 100;   // Invalid
    bin_val = 1;
    bit_cost_in = 16'hDEAD;
    #10;
    we = 0;

    read_ctx_addr = 3;
    read_bin_sel  = 1;
    #5;
    $display("Check valid memory not corrupted -> ctx=3 bin=1 = %h", bit_cost_out);

    // ============================================================
    // 4. BACK-TO-BACK WRITES (NO IDLE CYCLE)
    // ============================================================
    $display("\n--- [TEST 4] Back-to-Back Writes ---");

    we = 1; ctx_addr = 1; bin_val = 0; bit_cost_in = 16'h1111;
    #10;
    we = 1; ctx_addr = 1; bin_val = 1; bit_cost_in = 16'h2222;
    #10;
    we = 0;

    read_ctx_addr = 1;
    read_bin_sel  = 0; #5;
    $display("ctx=1 bin=0 = %h (Expected 1111)", bit_cost_out);

    read_bin_sel  = 1; #5;
    $display("ctx=1 bin=1 = %h (Expected 2222)", bit_cost_out);

    // ============================================================
    // 5. BIN ISOLATION (bin0 WRITE MUST NOT AFFECT bin1)
    // ============================================================
    $display("\n--- [TEST 5] Bin Isolation Check ---");

    we = 1; ctx_addr = 4; bin_val = 0; bit_cost_in = 16'hAAAA;
    #10; we = 0;

    read_ctx_addr = 4;
    #5;
    $display("bin0 = %h , bin1 = %h (bin1 must stay HM-initialized)",
              bit_cost_out0, bit_cost_out1);

    // ============================================================
    // 6. SIMULTANEOUS READ + WRITE SAME ADDRESS
    // ============================================================
    $display("\n--- [TEST 6] Read & Write Same Cycle ---");

    read_ctx_addr = 5;
    read_bin_sel  = 1;

    we = 1;
    ctx_addr = 5;
    bin_val = 1;
    bit_cost_in = 16'hFACE;
    #10;
    we = 0;

    #5;
    $display("ctx=5 bin=1 After RW same cycle = %h (Expected FACE)", bit_cost_out);

    // ============================================================
    // 7. RESET DURING OPERATION
    // ============================================================
    $display("\n--- [TEST 7] Reset During Operation ---");

    we = 1; ctx_addr = 6; bin_val = 1; bit_cost_in = 16'hBEEF;
    #10; we = 0;

    rst_n = 0;  // Force reset
    #10;
    rst_n = 1;

    read_ctx_addr = 6;
    read_bin_sel  = 1;
    #5;
    $display("After reset ctx=6 bin=1 = %h (Should be HM value)", bit_cost_out);

    // ============================================================
    // END
    // ============================================================
    #20;
    $display("\n---- ALL CORNER TESTS COMPLETED ----");
    $stop;
  end

endmodule
