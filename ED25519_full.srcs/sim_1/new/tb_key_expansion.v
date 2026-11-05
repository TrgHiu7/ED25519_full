`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 05:23:12 PM
// Design Name: 
// Module Name: tb_key_expansion
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


module tb_key_expansion;
    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg [255:0] secret;
    wire [255:0] a;
    wire [255:0] prefix;
    wire busy;
    wire done;

    key_expansion dut(
        .clk(clk), .rst(rst), .start(start), .secret(secret),
        .a(a), .prefix(prefix), .busy(busy), .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        // RFC 8032 test vector 1 seed. Byte 0 is placed at secret[7:0].
        secret = 256'h607fae1c03ac3b701969327b69c54944c42cec92f44a84ba605afdef9db1619d;
        #20;
        rst = 0;
        #10;
        start = 1;
        #10;
        start = 0;
        wait(done);
        #1;
        $display("a      = %064x", a);
        $display("prefix = %064x", prefix);
        if (a !== 256'h4fe94d9006f020a5a3c080d96827fffd3c010ac0f12e7a42cb33284f86837c30) begin
            $display("FAIL: a mismatch");
            $finish;
        end
        if (prefix !== 256'h8f1fe087928ea3f5968ff0033a47b75720504254e78486776a740b28fe0a4f9b) begin
            $display("FAIL: prefix mismatch");
            $finish;
        end
        $display("PASS");
        $finish;
    end
endmodule
