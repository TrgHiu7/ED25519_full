`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 05:09:30 PM
// Design Name: 
// Module Name: tb_invert
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

module tb_invert();

    // Khai báo các tín hiệu
    reg clk;
    reg rst;
    reg start;
    reg  [255:0] a;
    wire [255:0] result;
    wire done;

    // Hằng số P của đường cong Ed25519 (chỉ dùng để in ra/ghi chú)
    localparam [255:0] P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    // Khởi tạo module Invert (Nghịch đảo)
    invert uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a(a),
        .result(result),
        .done(done)
    );

    // Tạo xung nhịp 10ns (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Kịch bản test
    initial begin
        // 1. Reset hệ thống
        rst = 1;
        start = 0;
        a = 0;
        #20;
        rst = 0;
        #20;

        // -----------------------------------------------------------
        // TEST CASE 1: Nghịch đảo của 1
        // Toán học: 1^(-1) mod P = 1
        // -----------------------------------------------------------
        $display("--- TEST CASE 1: Nghich dao cua 1 ---");
        a = 256'd1;
        
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1); // Chờ FSM chạy xong (Khoảng 22,000+ clock)
        #10;
        
        if (result == 256'd1)
            $display("[PASS] Test 1: result = %0d", result);
        else
            $display("[FAIL] Test 1: Expected 1, Got %h", result);

        #100;

        // -----------------------------------------------------------
        // TEST CASE 2: Nghịch đảo của 2
        // Toán học: 2^(-1) mod P = (P + 1) / 2
        // Vì P = 2^255 - 19 => (P+1)/2 = 2^254 - 9
        // Dạng Hex: 3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7
        // -----------------------------------------------------------
        $display("--- TEST CASE 2: Nghich dao cua 2 ---");
        a = 256'd2;
        
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1);
        #10;
        
        if (result == 256'h3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7)
            $display("[PASS] Test 2: result match expected (P+1)/2");
        else
            $display("[FAIL] Test 2: Expected 3FFFF...F7, Got %h", result);

        #100;

        // -----------------------------------------------------------
        // TEST CASE 3: Nghịch đảo của (P - 1)
        // Toán học: (P-1)^(-1) mod P = P - 1
        // Dạng Hex: 7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEC
        // -----------------------------------------------------------
        $display("--- TEST CASE 3: Nghich dao cua P-1 ---");
        a = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEC;
        
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1);
        #10;
        
        if (result == 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEC)
            $display("[PASS] Test 3: result match expected P-1");
        else
            $display("[FAIL] Test 3: Expected 7FFFF...EC, Got %h", result);

        #100;

        $display("--- HOAN THANH TESTBENCH ---");
        $finish;
    end
    
    // Timeout để tránh treo mô phỏng nếu FSM bị lỗi kẹt trạng thái
    initial begin
        #5000000; // Đợi tối đa 5ms mô phỏng
        $display("[LỖI] Timeout! Mô phỏng chạy quá lâu do FSM không xuất tín hiệu done.");
        $finish;
    end

endmodule
