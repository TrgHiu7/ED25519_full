`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:34:01 AM
// Design Name: 
// Module Name: modulo_add
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


module modulo_add (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,

    input  wire [255:0] A,
    input  wire [255:0] B,

    output reg  [255:0] result,
    output reg          done
);
    localparam [255:0] P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    localparam [255:0] negP = 256'h8000000000000000000000000000000000000000000000000000000000000013; // -P = ~P + 1
    wire [255:0] sum_ab;

    assign sum_ab = A + B;


    wire [255:0] csa_sum;
    wire [255:0] csa_carry;

    CSA u_csa
    (
        .in1(A),
        .in2(B),
        .in3(negP),

        .sum(csa_sum),
        .carry(csa_carry)
    );

    wire [255:0] reduced;
    wire          cout;

    CPA u_cpa
    (
        .sum_in(csa_sum),
        .carry_in(csa_carry),
        .C_in(256'd0),

        .result(reduced),
        .cout(cout)
    );

    always @(posedge clk)
    begin

        if(!rst_n)
        begin

            result <= 256'd0;
            done   <= 1'b0;

        end

        else
        begin

            done <= 1'b0;

            if(start)
            begin

                if(cout)
                    result <= reduced;
                else
                    result <= sum_ab;

                done <= 1'b1;

            end

        end

    end

endmodule