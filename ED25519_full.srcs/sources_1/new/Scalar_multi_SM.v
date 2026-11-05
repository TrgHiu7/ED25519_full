`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 08:16:45 AM
// Design Name: 
// Module Name: Scalar_multi_SM
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


module Scalar_multi_SM(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    input  wire [255:0] k,

    input  wire [255:0] px,py, pz, pt,

    output reg done,

    // ALU control
    output reg rst_n_alu,
    output reg start_alu,
    output reg op_alu,      // 1=Double, 0=Add

    input wire alu_done,
    input wire [255:0] qx_alu, qy_alu, qz_alu, qt_alu,
    
    output reg [255:0] px_alu, py_alu, pz_alu, pt_alu,
    output reg [255:0] bx_alu, by_alu, bz_alu, bt_alu,
    output reg [255:0] result_x, result_y, result_z, result_t
);
    localparam [3:0] IDLE=0, SCAN=1, DOUBLE_START=2, DOUBLE_WAIT=3,
                     ADD_START=4, ADD_WAIT=5, NEXT_BIT=6, DONE_ST=7;
    reg [3:0] state;
    reg [7:0] bit_index;
    reg [255:0] scalar_k;
    reg [255:0] qx_reg,qy_reg,qz_reg,qt_reg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=IDLE;
            done<=0;
            rst_n_alu<=0;
            start_alu<=0;
            op_alu<=1;
            bit_index<=8'd255;
            scalar_k<=0;
            qx_reg<=0; qy_reg<=1; qz_reg<=1; qt_reg<=0;
            px_alu<=0; py_alu<=1; pz_alu<=1; pt_alu<=0;
            bx_alu<=0; by_alu<=1; bz_alu<=1; bt_alu<=0;
            result_x<=0; result_y<=0; result_z<=0; result_t<=0;
        end else begin
            done<=0;
            start_alu<=0;
            case(state)
                IDLE: if(start) begin
                    scalar_k<=k; bit_index<=8'd255;
                    bx_alu<=px; by_alu<=py; bz_alu<=pz; bt_alu<=pt;
                    qx_reg<=0; qy_reg<=1; qz_reg<=1; qt_reg<=0;
                    rst_n_alu<=1;
                    state<=SCAN;
                end
                SCAN: begin
                    rst_n_alu<=0;
                    if(scalar_k[bit_index]) begin
                        // Leading 1: avoid needlessly doubling the identity.
                        qx_reg<=bx_alu; qy_reg<=by_alu;
                        qz_reg<=bz_alu; qt_reg<=bt_alu;
                        if(bit_index==0) state<=DONE_ST;
                        else begin bit_index<=bit_index-1'b1; state<=DOUBLE_START; end
                    end else if(bit_index==0) state<=DONE_ST;
                    else bit_index<=bit_index-1'b1;
                end
                DOUBLE_START: begin
                    op_alu<=1'b1;
                    px_alu<=qx_reg; py_alu<=qy_reg;
                    pz_alu<=qz_reg; pt_alu<=qt_reg;
                    start_alu<=1'b1;
                    state<=DOUBLE_WAIT;
                end
                DOUBLE_WAIT: if(alu_done) begin
                    qx_reg<=qx_alu; qy_reg<=qy_alu;
                    qz_reg<=qz_alu; qt_reg<=qt_alu;
                    if(scalar_k[bit_index]) state<=ADD_START;
                    else state<=NEXT_BIT;
                end
                ADD_START: begin
                    op_alu<=1'b0;
                    px_alu<=qx_reg; py_alu<=qy_reg;
                    pz_alu<=qz_reg; pt_alu<=qt_reg;
                    start_alu<=1'b1;
                    state<=ADD_WAIT;
                end
                ADD_WAIT: if(alu_done) begin
                    qx_reg<=qx_alu; qy_reg<=qy_alu;
                    qz_reg<=qz_alu; qt_reg<=qt_alu;
                    state<=NEXT_BIT;
                end
                NEXT_BIT: if(bit_index==0) state<=DONE_ST;
                          else begin bit_index<=bit_index-1'b1; state<=DOUBLE_START; end
                DONE_ST: begin
                    result_x<=qx_reg; result_y<=qy_reg;
                    result_z<=qz_reg; result_t<=qt_reg;
                    done<=1;
                    state<=IDLE;
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule