`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:34:35 AM
// Design Name: 
// Module Name: modulo_sub
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


module modulo_sub(
//    input  wire         clk,
//    input  wire         rst_n,
//    input  wire         start,

//    input  wire [255:0] A,
//    input  wire [255:0] B,

//    output reg  [255:0] result,
//    output reg          done
//);
//    localparam [255:0] P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
////    localparam [255:0] negP = 256'h8000000000000000000000000000000000000000000000000000000000000013; // -P = ~P + 1
    
//    wire [255:0] B_inv;
//    assign B_inv = ~B;
//    wire [255:0] s1;
//    wire [255:0] c1;
//    wire [255:0] s2;
//    wire [255:0] c2;
//    wire [255:0] res1;
//    wire [255:0] res2;
//    wire cout1;
//    wire cout2;
//    CSA csa1
//    (
//        .in1(A),
//        .in2(B_inv),
//        .in3(256'd0),

//        .sum(s1),
//        .carry(c1)
//    );

//    CPA cpa1
//    (
//        .sum_in(s1),
//        .carry_in(c1),
//        .C_in(256'd1),

//        .result(res1),
//        .cout(cout1)
//    );

//    CSA csa2
//    (
//        .in1(A),
//        .in2(B_inv),
//        .in3(P),

//        .sum(s2),
//        .carry(c2)
//    );

//    CPA cpa2
//    (
//        .sum_in(s2),
//        .carry_in(c2),
//        .C_in(256'd1),

//        .result(res2),
//        .cout(cout2)
//    );

//    always @(posedge clk)
//    begin
//        if(!rst_n)
//        begin
//            result <= 256'd0;
//            done   <= 1'b0;
//        end
//        else
//        begin
//            done <= 1'b0;
//            if(start)
//            begin
//                if(cout1)
//                    result <= res1;
//                else
//                    result <= res2;
//                done <= 1'b1;
//            end
//        end
//    end
//endmodule
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [255:0] A,
    input  wire [255:0] B,
    output reg  [255:0] result,
    output reg          done
);
    localparam [255:0] P       = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    localparam [255:0] P_PLUS1 = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEE;

    wire [255:0] B_inv = ~B;
    wire [255:0] diff_raw, diff_plus_p;
    wire         raw_cout, plus_p_cout;
    wire         raw_valid, plus_p_valid;

    // A + ~B + 1 = 2^256 + A - B.
    // raw_cout is 1 precisely when A >= B.
    CPA u_raw (
        .clk(clk), .rst_n(rst_n), .valid_in(start),
        .sum_in(A), .carry_in(B_inv), .C_in(256'd1),
        .result(diff_raw), .cout(raw_cout), .valid_out(raw_valid)
    );

    // A + ~B + (P+1) = 2^256 + A - B + P.
    // The low 256 bits give the corrected result when A < B.
    CPA u_plus_p (
        .clk(clk), .rst_n(rst_n), .valid_in(start),
        .sum_in(A), .carry_in(B_inv), .C_in(P_PLUS1),
        .result(diff_plus_p), .cout(plus_p_cout),
        .valid_out(plus_p_valid)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 256'd0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (raw_valid && plus_p_valid) begin
                result <= raw_cout ? diff_raw : diff_plus_p;
                done <= 1'b1;
            end
        end
    end
endmodule