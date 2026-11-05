`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 04:35:00 PM
// Design Name: 
// Module Name: tb_modulo_add
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_modulo_add;
localparam [255:0] P =
        256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    reg clk;
    reg rst;
    reg start;

    reg  [255:0] A;
    reg  [255:0] B;

    wire [255:0] result;
    wire         done;

    integer pass_count;
    integer fail_count;

    // ============================================================
    // DUT
    // ============================================================
    modulo_add dut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .A      (A),
        .B      (B),
        .result (result),
        .done   (done)
    );

    // ============================================================
    // Clock 10 ns
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Test task
    // ============================================================
    task test_add;

        input [255:0] test_A;
        input [255:0] test_B;

        reg [256:0] full_sum;
        reg [255:0] expected;

        begin

            // Golden model
            full_sum = {1'b0, test_A} + {1'b0, test_B};

            if (full_sum >= {1'b0, P})
                expected = full_sum - {1'b0, P};
            else
                expected = full_sum[255:0];


            // Apply inputs at negedge
            @(negedge clk);

            A     = test_A;
            B     = test_B;
            start = 1'b1;


            // DUT computes at next posedge
            @(posedge clk);
            #1;


            // Check done
            if (done !== 1'b1) begin

                $display("==============================================");
                $display("[FAIL] done not asserted");
                $display("A        = %h", test_A);
                $display("B        = %h", test_B);
                $display("Expected = %h", expected);
                $display("Result   = %h", result);
                $display("==============================================");

                fail_count = fail_count + 1;

            end

            // Check result
            else if (result !== expected) begin

                $display("==============================================");
                $display("[ADD FAIL]");
                $display("A        = %h", test_A);
                $display("B        = %h", test_B);
                $display("Expected = %h", expected);
                $display("Result   = %h", result);
                $display("==============================================");

                fail_count = fail_count + 1;

            end

            else begin

                $display(
                    "[ADD PASS] A = %h, B = %h, Result = %h",
                    test_A,
                    test_B,
                    result
                );

                pass_count = pass_count + 1;

            end


            // Deassert start
            @(negedge clk);

            start = 1'b0;


            // done should go low
            @(posedge clk);
            #1;

            if (done !== 1'b0) begin

                $display("[FAIL] done should return to 0");

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // Main
    // ============================================================
    initial begin

        pass_count = 0;
        fail_count = 0;

        rst   = 1'b1;
        start = 1'b0;

        A = 256'd0;
        B = 256'd0;


        // Reset
        repeat (3)
            @(posedge clk);

        @(negedge clk);
        rst = 1'b0;


        $display("");
        $display("==============================================");
        $display("           MODULO ADD TEST");
        $display("==============================================");


        // --------------------------------------------------------
        // Test 1: 0 + 0 = 0
        // --------------------------------------------------------
        test_add(
            256'd0,
            256'd0
        );


        // --------------------------------------------------------
        // Test 2: 1 + 1 = 2
        // --------------------------------------------------------
        test_add(
            256'd1,
            256'd1
        );


        // --------------------------------------------------------
        // Test 3: 10 + 20 = 30
        // --------------------------------------------------------
        test_add(
            256'd10,
            256'd20
        );


        // --------------------------------------------------------
        // Test 4: (P-1) + 0 = P-1
        // --------------------------------------------------------
        test_add(
            P - 256'd1,
            256'd0
        );


        // --------------------------------------------------------
        // Test 5:
        // (P-1) + 1 = P = 0 mod P
        // --------------------------------------------------------
        test_add(
            P - 256'd1,
            256'd1
        );


        // --------------------------------------------------------
        // Test 6:
        // (P-1) + 2 = P+1 = 1 mod P
        // --------------------------------------------------------
        test_add(
            P - 256'd1,
            256'd2
        );


        // --------------------------------------------------------
        // Test 7:
        // (P-1) + (P-1)
        // = 2P-2
        // = P-2 mod P
        // --------------------------------------------------------
        test_add(
            P - 256'd1,
            P - 256'd1
        );


        // --------------------------------------------------------
        // Test 8:
        // A+B exactly P
        // --------------------------------------------------------
        test_add(
            256'd100,
            P - 256'd100
        );


        // --------------------------------------------------------
        // Test 9
        // --------------------------------------------------------
        test_add(
            256'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0,
            256'h1111111111111111111111111111111111111111111111111111111111111111
        );


        // ========================================================
        // Summary
        // ========================================================
        $display("");
        $display("==============================================");
        $display("              TEST SUMMARY");
        $display("==============================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display(">>> ALL MODULO_ADD TESTS PASSED <<<");
        else
            $display(">>> MODULO_ADD HAS FAILED TESTS <<<");

        #20;
        $finish;

    end


    // Waveform
    initial begin
        $dumpfile("tb_modulo_add.vcd");
        $dumpvars(0, tb_modulo_add);
    end

endmodule
