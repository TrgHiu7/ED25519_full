`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 04:10:39 PM
// Design Name: 
// Module Name: tb_modulo_mul
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


module tb_modulo_mul();
localparam [255:0] P =
        256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    localparam integer EXPECT_CYCLES = 316;

    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    reg start = 1'b0;
    reg [255:0] X_in = 256'd0;
    reg [255:0] Y    = 256'd0;
    wire [255:0] R;
    wire done;

    modulo_mul dut (
        .clk(clk), .rst(rst), .start(start),
        .X_in(X_in), .Y(Y), .R(R), .done(done)
    );

    reg [511:0] product;
    reg [255:0] expected;
    reg [255:0] rx, ry;
    integer cycles, test_no, i, j;

    task run_case;
        input [255:0] x;
        input [255:0] y;
        begin
            if (x >= P || y >= P) begin
                $display("BAD TEST: inputs must be canonical, x=%h y=%h",x,y);
                $fatal(1);
            end
            product  = x * y;
            expected = product % {256'd0, P};

            // The DUT takes its own input snapshot on the next posedge.
            @(negedge clk);
            X_in = x;
            Y = y;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            // Deliberately disturb input ports to verify the input registers.
            X_in = ~x;
            Y = ~y;

            cycles = 0;
            while (done !== 1'b1 && cycles < EXPECT_CYCLES+5) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            if (done !== 1'b1) begin
                $display("TIMEOUT test=%0d x=%h y=%h", test_no,x,y);
                $fatal(1);
            end
            if ((^R === 1'bx) || (R !== expected) ||
                (R >= P) || (cycles != EXPECT_CYCLES)) begin
                $display("FAIL test=%0d cycles=%0d", test_no, cycles);
                $display("X        = %h", x);
                $display("Y        = %h", y);
                $display("Expected = %h", expected);
                $display("Actual   = %h", R);
                $fatal(1);
            end
            if (test_no < 12 || (test_no % 100) == 0)
                $display("PASS test=%0d, cycles=%0d, result=%h", test_no,cycles,R);
            test_no = test_no + 1;
        end
    endtask

    initial begin
        test_no=0;
        i=0; j=0;
        rx=0; ry=0;
        repeat(4) @(negedge clk);
        rst = 1'b0;

        // Directed tests: carry across radix-8 digits, nearly p and high bits.
        run_case(256'd0, 256'd0);
        run_case(256'd1, 256'd1);
        run_case(P-1'b1, P-1'b1);
        run_case(P-1'b1, P-2'd2);
        run_case(256'd1, P-1'b1);
        run_case(P-1'b1, 256'd1);
        run_case(256'd127, P-1'b1);
        run_case((256'd1 << 254), P-1'b1);
        run_case(P-1'b1, (256'd1 << 254));
        run_case((256'd1 << 252), (256'd1 << 253));
        run_case((256'd1 << 254) + 256'd123, P-1'b1);
        run_case(P-1'b1, P-19);

        // Low-digit exhaustive tests.
        for (i=0; i<16; i=i+1)
            for (j=0; j<16; j=j+1)
                run_case(i, j);

        // 500 random canonical elements, each built from eight 32-bit words.
        for (i=0; i<500; i=i+1) begin
            for (j=0; j<8; j=j+1) begin
                rx[j*32 +: 32] = $random;
                ry[j*32 +: 32] = $random;
            end
            rx[255] = 1'b0;
            ry[255] = 1'b0;
            if (rx >= P) rx = rx-P;
            if (ry >= P) ry = ry-P;
            run_case(rx,ry);
        end

        $display("ALL %0d CASES PASSED (canonical inputs, 316 cycles)",test_no);
        $finish;
    end
endmodule
