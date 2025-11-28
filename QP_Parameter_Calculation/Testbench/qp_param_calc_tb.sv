module tb_qp_param_calc;
logic isLuma;
logic signed [7:0] qpy;
logic signed [7:0] qpBdOffset;
logic signed [7:0] chromaQPOffset;
logic [1:0] chFmt;
logic signed [7:0] Qp;
logic [3:0] per;
logic [2:0] rem;

qp_param_calc dut (.*);

initial begin
$display("=== HEVC QP Parameter Calculator Testbench ===");
$display("Time | isLuma | qpy | qpBdOffset | chromaQPOffset | chFmt | Qp | per | rem | Status");
$display("-----------------------------------------------------------------------------");

// Test 1: Luma case
isLuma = 1'b1;
qpy = 25;
qpBdOffset = 0;
chromaQPOffset = 0;
chFmt = 2'd1;
#10;
$display("%4t | %6b | %3d | %10d | %14d | %5d | %2d | %3d | %2d | %s", 
$time, isLuma, qpy, qpBdOffset, chromaQPOffset, chFmt, Qp, per, rem,
(Qp==25 && per==4 && rem==1) ? "PASS" : "FAIL");

// Test 2: Chroma case - qpy=30 should map to 29 in 4:2:0!
isLuma = 1'b0;
qpy = 30;
qpBdOffset = 0;
chromaQPOffset = 0;
chFmt = 2'd1;
#10;
$display("%4t | %6b | %3d | %10d | %14d | %5d | %2d | %3d | %2d | %s", 
$time, isLuma, qpy, qpBdOffset, chromaQPOffset, chFmt, Qp, per, rem,
(Qp==29 && per==4 && rem==5) ? "PASS" : "FAIL");

// Test 3: Chroma negative case
isLuma = 1'b0;
qpy = 10;
qpBdOffset = 52;
chromaQPOffset = -20;
chFmt = 2'd1;
#10;
$display("%4t | %6b | %3d | %10d | %14d | %5d | %2d | %3d | %2d | %s", 
$time, isLuma, qpy, qpBdOffset, chromaQPOffset, chFmt, Qp, per, rem,
(Qp==42 && per==7 && rem==0) ? "PASS" : "FAIL");

// Test 4: Chroma format 2 (direct mapping)
isLuma = 1'b0;
qpy = 40;
qpBdOffset = 0;
chromaQPOffset = 0;
chFmt = 2'd2;
#10;
$display("%4t | %6b | %3d | %10d | %14d | %5d | %2d | %3d | %2d | %s", 
$time, isLuma, qpy, qpBdOffset, chromaQPOffset, chFmt, Qp, per, rem,
(Qp==40 && per==6 && rem==4) ? "PASS" : "FAIL");

// Test 5: Luma maximum QP
isLuma = 1'b1;
qpy = 51;
qpBdOffset = 0;
chromaQPOffset = 0;
chFmt = 2'd1;
#10;
$display("%4t | %6b | %3d | %10d | %14d | %5d | %2d | %3d | %2d | %s", 
$time, isLuma, qpy, qpBdOffset, chromaQPOffset, chFmt, Qp, per, rem,
(Qp==51 && per==8 && rem==3) ? "PASS" : "FAIL");

$display("\n=== Testbench Complete ===");
$finish;
end
endmodule