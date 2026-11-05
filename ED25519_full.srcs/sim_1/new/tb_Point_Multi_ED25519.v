`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 09:27:24 PM
// Design Name: 
// Module Name: tb_Point_Multi_ED25519
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

module tb_Point_Multi_ED25519;
    reg clk=0;
    always #5 clk=~clk;
    reg rst=0,start=0,valid=0;
    reg [255:0] k=0,px=0,py=0;
    wire [255:0] qx,qy;
    wire done,ready;
    integer errors=0;
    integer cycles;
    localparam integer TIMEOUT=1000000;
    localparam [255:0] BX=256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BY=256'h6666666666666666666666666666666666666666666666666666666666666658;
    localparam [255:0] B2X=256'h36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e;
    localparam [255:0] B2Y=256'h2260cdf3092329c21da25ee8c9a21f5697390f51643851560e5f46ae6af8a3c9;
    localparam [255:0] B3X=256'h67ae9c4a22928f491ff4ae743edac83a6343981981624886ac62485fd3f8e25c;
    localparam [255:0] B3Y=256'h1267b1d177ee69aba126a18e60269ef79f16ec176724030402c3684878f5b4d4;

    Point_Multi_ED25519 dut(
        .clk(clk),.rst(rst),.start(start),.valid(valid),
        .k(k),.px(px),.py(py),.qx(qx),.qy(qy),.done(done),.ready(ready)
    );

    task reset_dut;
        begin
            @(negedge clk);
            rst=1; start=0; valid=0;
            repeat(4) @(negedge clk);
            if (done!==0 || ready!==0 || qx!==0 || qy!==0) begin
                $display("[FAIL] reset output"); errors=errors+1;
            end
            rst=0;
            repeat(4) @(negedge clk);
        end
    endtask

    task run_scalar;
        input [255:0] scalar;
        input [255:0] ex,ey;
        input integer change_inputs_midflight;
        begin
            @(negedge clk);
            k=scalar; px=BX; py=BY; start=0; valid=0;
            repeat(4) @(negedge clk);
            if(ready!==1'b1) begin
                $display("[FAIL] not ready before scalar %0d",scalar);
                errors=errors+1;
            end
            start=1; valid=1;
            @(negedge clk);
            start=0; valid=0;
            cycles=0;
            if (change_inputs_midflight!=0) begin
                // Mutating external inputs must not modify the latched transaction.
                k=256'd99; px=256'd21; py=256'd73;
            end
            while(done!==1'b1 && cycles<TIMEOUT) begin
                @(negedge clk);
                cycles=cycles+1;
                if(cycles>4 && ready!==1'b0) begin
                    $display("[FAIL] ready high while computing k=%0d",scalar);
                    errors=errors+1;
                    // Avoid unbounded repeat messages.
                    cycles=TIMEOUT;
                end
                if(cycles%100000==0 && cycles<TIMEOUT)
                    $display("[INFO] k=%0d cycles=%0d top=%0d scalar=%0d",scalar,cycles,dut.state,dut.SMSM.state);
            end
            if(done!==1'b1) begin
                $display("[FAIL] TIMEOUT k=%0d top=%0d scalar=%0d",scalar,dut.state,dut.SMSM.state);
                errors=errors+1;
                reset_dut();
            end else begin
                if(qx!==ex || qy!==ey) begin
                    $display("[FAIL] k=%0d after %0d cycles",scalar,cycles);
                    $display(" expected X=%064h",ex);
                    $display("      got X=%064h",qx);
                    $display(" expected Y=%064h",ey);
                    $display("      got Y=%064h",qy);
                    errors=errors+1;
                end else begin
                    $display("[PASS] k=%0d in %0d cycles",scalar,cycles);
                end
                @(negedge clk);
                if(done!==1'b0) begin $display("[FAIL] done pulse >1 cycle"); errors=errors+1; end
                k=scalar; px=BX; py=BY;
                repeat(4) @(negedge clk);
                if(ready!==1'b1) begin $display("[FAIL] ready not recovered"); errors=errors+1; end
            end
        end
    endtask

    initial begin
`ifdef IVERILOG_DUMP
        $dumpfile("Point_Multi_ED25519.vcd");
        $dumpvars(0,clk,rst,start,valid,done,ready,qx,qy);
`endif
        reset_dut();
        k=256'd0; px=BX; py=BY; valid=1;
        repeat(4) @(negedge clk);
        if(ready!==1'b0) begin $display("[FAIL] k=0 accepted"); errors=errors+1; end
        valid=0;
        run_scalar(256'd1,BX,BY,1);
        run_scalar(256'd2,B2X,B2Y,0);
        run_scalar(256'd3,B3X,B3Y,0);
        if(errors==0) $display("[PASS] ALL TESTS PASSED");
        else $display("[FAIL] %0d test issue(s)", errors);
        $finish;
    end
endmodule