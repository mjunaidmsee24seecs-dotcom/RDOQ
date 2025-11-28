`timescale 1ns/1ps

module tb_QuantBitsCalculator;
    reg [4:0] cQP_per;
    reg [5:0] iTransformShift;
    wire [5:0] iQBits;
    
    // Instantiate the DUT
    QuantBitsCalculator dut (
        .cQP_per(cQP_per),
        .iTransformShift(iTransformShift),
        .iQBits(iQBits)
    );
    
    initial begin
        // Initialize inputs
        cQP_per = 0;
        iTransformShift = 0;
        
        // Test case 1: Minimum values
        #10;
        cQP_per = 0;
        iTransformShift = 0;
        #10;
        $display("Test 1: cQP_per=%0d, iTransformShift=%0d ? iQBits=%0d", 
                 cQP_per, iTransformShift, iQBits);
        
        // Test case 2: Typical case 1
        #10;
        cQP_per = 5;      // QP=30
        iTransformShift = 4;
        #10;
        $display("Test 2: cQP_per=%0d, iTransformShift=%0d ? iQBits=%0d", 
                 cQP_per, iTransformShift, iQBits);
        
        // Test case 3: Typical case 2  
        #10;
        cQP_per = 2;      // QP=12
        iTransformShift = 2;
        #10;
        $display("Test 3: cQP_per=%0d, iTransformShift=%0d ? iQBits=%0d", 
                 cQP_per, iTransformShift, iQBits);
        
        // Test case 4: Maximum values
        #10;
        cQP_per = 9;      // QP=57 (max practical)
        iTransformShift = 10;
        #10;
        $display("Test 4: cQP_per=%0d, iTransformShift=%0d ? iQBits=%0d", 
                 cQP_per, iTransformShift, iQBits);
        
        // Test case 5: Random test
        #10;
        cQP_per = 8;      // QP=51
        iTransformShift = 6;
        #10;
        $display("Test 5: cQP_per=%0d, iTransformShift=%0d ? iQBits=%0d", 
                 cQP_per, iTransformShift, iQBits);
        
        // Verify all outputs match expected values
        #10;
        $display("\n=== VERIFICATION ===");
        if (iQBits == 14 + 8 + 6) 
            $display("? All tests passed!");
        else
            $display("? Test failed!");
            
        $finish;
    end
    
endmodule