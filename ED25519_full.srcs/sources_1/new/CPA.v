`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:34:54 AM
// Design Name: 
// Module Name: CPA
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


module CPA (
    input  wire [255:0] sum_in,
    input  wire [255:0] carry_in,
    input  wire [255:0] C_in,
    output wire [255:0] result,
    output wire             cout
);
    wire [256:0] temp_sum;
    assign temp_sum = {1'b0, sum_in} + carry_in + C_in;
    assign result   = temp_sum[255:0];
    assign cout     = temp_sum[256];
endmodule

