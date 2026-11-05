`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 08:09:06 AM
// Design Name: 
// Module Name: alu_point_core
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


module alu_point_core(
    input wire clk,rst,start,op,
    input wire [255:0] px,py,pz,pt,
    input wire [255:0] bx,by,bz,bt,
    output wire [255:0] qx,qy,qz,qt,
    output wire done
);
    wire [4:0] ecpa_sel_a,ecpa_sel_b,ecpa_sel_w;
    wire [4:0] ecpd_sel_a,ecpd_sel_b,ecpd_sel_w;
    wire ecpa_we,ecpd_we,ecpa_start,ecpd_start,done_ecpa,done_ecpd;
    wire [1:0] ecpa_op,ecpd_op;
    wire [2:0] ecpa_din,ecpd_din;
    wire [4:0] sel_a,sel_b,sel_w;
    wire we_reg,start_alu;
    wire [1:0] alu_op;
    wire [2:0] din_sel;
    wire [255:0] data_a,data_b,alu_result;
    reg [255:0] data_w;
    wire alu_done;
    // Capture operation so the mux cannot switch during an active request.
    reg op_active;
    always @(posedge clk or posedge rst) begin
        if (rst) op_active <= 1'b0;
        else if (start) op_active <= op;
    end
    assign sel_a=(op_active==1'b0)?ecpa_sel_a:ecpd_sel_a;
    assign sel_b=(op_active==1'b0)?ecpa_sel_b:ecpd_sel_b;
    assign sel_w=(op_active==1'b0)?ecpa_sel_w:ecpd_sel_w;
    assign we_reg=(op_active==1'b0)?ecpa_we:ecpd_we;
    assign din_sel=(op_active==1'b0)?ecpa_din:ecpd_din;
    assign start_alu=(op_active==1'b0)?ecpa_start:ecpd_start;
    assign alu_op=(op_active==1'b0)?ecpa_op:ecpd_op;
    assign done=(op_active==1'b0)?done_ecpa:done_ecpd;

    ECPA ecpa_sm (
        .clk(clk),.rst(rst),.start(start & ~op),.done(done_ecpa),
        .alu_op(ecpa_op),.alu_start(ecpa_start),.alu_done(alu_done),
        .src1_sel(ecpa_sel_a),.src2_sel(ecpa_sel_b),.dst_sel(ecpa_sel_w),
        .we(ecpa_we),.din_sel(ecpa_din)
    );
    ECPD ecpd_sm (
        .clk(clk),.rst(rst),.start(start & op),.done(done_ecpd),
        .alu_op(ecpd_op),.alu_start(ecpd_start),.alu_done(alu_done),
        .src1_sel(ecpd_sel_a),.src2_sel(ecpd_sel_b),.dst_sel(ecpd_sel_w),
        .we(ecpd_we),.din_sel(ecpd_din)
    );
    alu_core u_alu (
        .clk(clk),.rst(rst),.start(start_alu),.op(alu_op),
        .a(data_a),.b(data_b),.result(alu_result),.done(alu_done)
    );
    regbank u_regbank (
        .clk(clk),.rst(rst),.we(we_reg),.src1_sel(sel_a),.src2_sel(sel_b),
        .dst_sel(sel_w),.din(data_w),
        .px(px),.py(py),.pz(pz),.pt(pt),
        .bx(bx),.by(by),.bz(bz),.bt(bt),
        .src1_out(data_a),.src2_out(data_b),
        .qx(qx),.qy(qy),.qz(qz),.qt(qt)
    );
    always @(*) begin
        case(din_sel)
            3'd0: data_w=alu_result;
            3'd1: data_w=px;
            3'd2: data_w=py;
            3'd3: data_w=pz;
            3'd4: data_w=pt;
            default: data_w=256'd0;
        endcase
    end
endmodule
