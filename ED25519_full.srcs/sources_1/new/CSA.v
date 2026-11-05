`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:34:46 AM
// Design Name: 
// Module Name: CSA
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments
// 
//////////////////////////////////////////////////////////////////////////////////

module CSA (
    input  wire [255:0] in1,
    input  wire [255:0] in2,
    input  wire [255:0] in3,

    output wire [255:0] sum,
    output wire [255:0] carry
);

    wire [255:0] majority;

    assign majority = (in1 & in2) |
                      (in2 & in3) |
                      (in1 & in3);

    assign sum = in1 ^ in2 ^ in3;

    assign carry = {majority[254:0], 1'b0};

endmodule
