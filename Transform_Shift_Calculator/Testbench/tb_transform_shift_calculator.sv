`timescale 1ns / 1ps
module tb_transform_shift_calculator;
        // Inputs
    logic [3:0] channel_bit_depth;
    logic [2:0] log2_tr_size;
    logic [4:0] max_log2_tr_dynamic_range;
    logic       use_transform_skip;
    logic       extended_precision_processing;

    // Outputs
    logic signed [5:0] i_transform_shift;

    // Instantiate DUT
    transform_shift_calculator u_dut (
        .channel_bit_depth(channel_bit_depth),
        .log2_tr_size(log2_tr_size),
        .max_log2_tr_dynamic_range(max_log2_tr_dynamic_range),
        .use_transform_skip(use_transform_skip),
        .extended_precision_processing(extended_precision_processing),
        .i_transform_shift(i_transform_shift)
    );

    initial begin
        $monitor("Time=%0t | Depth=%2d Size=%1d MaxR=%2d TS=%b EP=%b | Shift=%2d", 
                 $time, channel_bit_depth, log2_tr_size, max_log2_tr_dynamic_range, 
                 use_transform_skip, extended_precision_processing, i_transform_shift);

        $display("=== Test Starting ===");

        // Case 1: Standard Calculation (Positive Shift)
        // Formula: 15 - 8 - 2 = 5
        channel_bit_depth = 8;
        log2_tr_size = 2;
        max_log2_tr_dynamic_range = 15;
        use_transform_skip = 0;
        extended_precision_processing = 0;
        #10;
        if (i_transform_shift !== 5) $display("Error Case 1");

        // Case 2: High Precision, Normal Transform (Negative Shift Valid)
        // Formula: 15 - 12 - 5 = -2
        // Since TS is 0, we expect -2 regardless of EP.
        channel_bit_depth = 12;
        log2_tr_size = 5;
        max_log2_tr_dynamic_range = 15;
        use_transform_skip = 0;
        extended_precision_processing = 1; 
        #10;
        if (i_transform_shift !== -2) $display("Error Case 2");

        // Case 3: Transform Skip + Extended Precision (CLAMPING ACTIVE)
        // Formula: 15 - 12 - 5 = -2
        // TS=1 AND EP=1 -> Logic forces max(0, -2) = 0
        use_transform_skip = 1;
        extended_precision_processing = 1;
        #10;
        if (i_transform_shift !== 0) $display("Error Case 3 (Clamping Failed)");

        // Case 4: Transform Skip + NO Extended Precision (No Clamping)
        // Formula: 15 - 12 - 5 = -2
        // TS=1 but EP=0. The C++ condition (TS && EP) fails.
        // Logic should return raw -2.
        use_transform_skip = 1;
        extended_precision_processing = 0;
        #10;
        if (i_transform_shift !== -2) $display("Error Case 4 (Should not have clamped)");

        $display("=== Test Complete ===");
        $finish;
    end
endmodule