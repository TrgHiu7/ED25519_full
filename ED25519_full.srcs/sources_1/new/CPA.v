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


//module CPA (
//    input  wire [255:0] sum_in,
//    input  wire [255:0] carry_in,
//    input  wire [255:0] C_in,
//    output wire [255:0] result,
//    output wire             cout
//);
//    wire [256:0] temp_sum;
//    assign temp_sum = {1'b0, sum_in} + carry_in + C_in;
//    assign result   = temp_sum[255:0];
//    assign cout     = temp_sum[256];
//endmodule
module CPA (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         valid_in,
    input  wire [255:0] sum_in,
    input  wire [255:0] carry_in,
    input  wire [255:0] C_in,
    output reg  [255:0] result,
    output reg          cout,
    output reg          valid_out
);
    wire [255:0] cs_sum;
    wire [255:0] cs_carry;
    wire         cs_top;

    CSA u_csa (
        .in1(sum_in), .in2(carry_in), .in3(C_in),
        .sum(cs_sum), .carry(cs_carry)
    );

    // The MSB of the majority is shifted to bit 256 (outside CSA.carry).
    assign cs_top = (sum_in[255] & carry_in[255]) |
                    (sum_in[255] & C_in[255]) |
                    (carry_in[255] & C_in[255]);

    // Stage 0: register carry-save operands.
    reg [255:0] s0, c0;
    reg         top0, v0;

    // Stage 1: bits 63:0, pass higher 192 bits along.
    wire [64:0] add1 = {1'b0, s0[63:0]} + {1'b0, c0[63:0]};
    reg  [63:0] r1;
    reg [191:0] s1_hi, c1_hi;
    reg         cy1, top1, v1;

    // Stage 2: bits 127:64.
    wire [64:0] add2 = {1'b0, s1_hi[63:0]} +
                       {1'b0, c1_hi[63:0]} + cy1;
    reg [127:0] r2;
    reg [127:0] s2_hi, c2_hi;
    reg         cy2, top2, v2;

    // Stage 3: bits 191:128.
    wire [64:0] add3 = {1'b0, s2_hi[63:0]} +
                       {1'b0, c2_hi[63:0]} + cy2;
    reg [191:0] r3;
    reg  [63:0] s3_hi, c3_hi;
    reg         cy3, top3, v3;

    // Stage 4: bits 255:192; output register.
    wire [64:0] add4 = {1'b0, s3_hi} + {1'b0, c3_hi} + cy3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s0 <= 0; c0 <= 0; top0 <= 0; v0 <= 0;
            r1 <= 0; s1_hi <= 0; c1_hi <= 0;
            cy1 <= 0; top1 <= 0; v1 <= 0;
            r2 <= 0; s2_hi <= 0; c2_hi <= 0;
            cy2 <= 0; top2 <= 0; v2 <= 0;
            r3 <= 0; s3_hi <= 0; c3_hi <= 0;
            cy3 <= 0; top3 <= 0; v3 <= 0;
            result <= 0; cout <= 0; valid_out <= 0;
        end else begin
            // All stages advance every clock; valid bits tag useful data.
            s0 <= cs_sum;
            c0 <= cs_carry;
            top0 <= cs_top;
            v0 <= valid_in;

            r1 <= add1[63:0];
            cy1 <= add1[64];
            s1_hi <= s0[255:64];
            c1_hi <= c0[255:64];
            top1 <= top0;
            v1 <= v0;

            r2 <= {add2[63:0], r1};
            cy2 <= add2[64];
            s2_hi <= s1_hi[191:64];
            c2_hi <= c1_hi[191:64];
            top2 <= top1;
            v2 <= v1;

            r3 <= {add3[63:0], r2};
            cy3 <= add3[64];
            s3_hi <= s2_hi[127:64];
            c3_hi <= c2_hi[127:64];
            top3 <= top2;
            v3 <= v2;

            result <= {add4[63:0], r3};
            // Bit 256 receives BOTH the CSA top carry and the chunk carry.
            cout <= top3 ^ add4[64];
            valid_out <= v3;
        end
    end
endmodule

