`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2026 01:04:37 PM
// Design Name: 
// Module Name: tb_point_compress
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


module tb_point_compress;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg          rst = 1'b1;
    reg          start = 1'b0;
    reg [255:0]  x1 = 256'd0;
    reg [255:0]  y1 = 256'd0;
    reg [255:0]  z1 = 256'd0;
    reg [255:0]  t1 = 256'd0;
    wire [255:0] k;
    wire         busy, done, invalid_z;

    localparam [255:0] EXPECTED_K =
        256'h6666666666666666666666666666666666666666666666666666666666666658;

    point_compress dut (
        .clk      (clk),
        .rst    (rst),
        .start    (start),
        .x1       (x1),
        .y1       (y1),
        .z1       (z1),
        .t1       (t1),
        .k        (k),
        .busy     (busy),
        .done     (done),
        .invalid_z(invalid_z)
    );

    task launch;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
        end
    endtask

    task check_basepoint;
        begin
            wait (done === 1'b1);
            #1;
            if (invalid_z !== 1'b0 || k !== EXPECTED_K) begin
                $display("FAIL: k=%h, error=%b, expected=%h", k, invalid_z, EXPECTED_K);
                $stop;
            end else begin
                $display("PASS: k=%h", k);
            end
        end
    endtask

    initial begin
        #5000000;
        $display("TIMEOUT: point_compress did not complete");
        $stop;
    end

    initial begin
        repeat (4) @(negedge clk);
        rst = 1'b0;

        // Ed25519 base point: z=1, t=x*y mod p.
        x1 = 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
        y1 = 256'h6666666666666666666666666666666666666666666666666666666666666658;
        z1 = 256'd1;
        t1 = 256'h67875f0fd78b766566ea4e8e64abe37d20f09f80775152f56dde8ab3a5b7dda3;
        launch();
        check_basepoint();

        // Same affine point represented by extended coords scaled by 7.
        @(negedge clk);
        x1 = 256'h69e07fca9e044bf744822f5df0e00686e03973a4140795e3815b3da3ea08d3c9;
        y1 = 256'h4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7;
        z1 = 256'd7;
        t1 = 256'h54b3996ee4d03cc5d06825e4c0b3386be6945c83433944b60115cae988070fd4;
        launch();
        check_basepoint();

        // Z=0 is rejected explicitly.
        @(negedge clk);
        z1 = 256'd0;
        launch();
        wait (done === 1'b1);
        #1;
        if (invalid_z !== 1'b1 || k !== 256'd0) begin
            $display("FAIL: invalid Z was not rejected");
            $stop;
        end
        $display("PASS: Z=0 rejected; all test cases passed.");
        $finish;
    end
endmodule