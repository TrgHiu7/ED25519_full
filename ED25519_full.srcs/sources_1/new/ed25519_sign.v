`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:21:43 AM
// Design Name: 
// Module Name: ed25519_sign
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

module ed25519_sign (
    input wire clk, rst_n, start,
    input wire [255:0] secret_scalar,
    input wire [255:0] prefix,
    input wire [255:0] public_key,
    input wire [511:0] msg_be,
    input wire [6:0] msg_len,
    output reg [511:0] signature,
    output reg done,
    output reg error,
    output wire busy
);
    localparam [255:0] BASE_X =
        256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BASE_Y =
        256'h6666666666666666666666666666666666666666666666666666666658;
    localparam [3:0]
        IDLE=0, R_HASH_START=1, R_HASH_WAIT=2, R_REDUCE_WAIT=3,
        R_POINT_REQ=4, R_POINT_WAIT=5, H_HASH_START=6, H_HASH_WAIT=7,
        H_REDUCE_WAIT=8, MULADD_WAIT=9, S_REDUCE_WAIT=10;
    reg [3:0] state;
    assign busy=(state!=IDLE);
    reg [255:0] a_reg,prefix_reg,pub_reg,r_reg,h_reg,R_enc;
    reg [511:0] msg_reg;
    reg [6:0] len_reg;
    reg sha_start,reduce_start,point_start,muladd_start;
    reg [1023:0] sha_data;
    reg [7:0] sha_bytes;
    reg [511:0] reduce_input;
    wire [511:0] sha_digest;
    wire sha_done,sha_busy;
    wire [255:0] mod_result;
    wire reduce_done,reduce_busy;
    wire [511:0] wide_result;
    wire muladd_done,muladd_busy;
    wire [255:0] point_x,point_y;
    wire point_done,point_ready;
    wire [255:0] r_point_scalar=r_reg;

    function [255:0] rev32;
        input [255:0] x;
        integer i;
        begin
            for(i=0;i<32;i=i+1)
                rev32[8*i +: 8]=x[255-8*i -: 8];
        end
    endfunction
    function [511:0] rev64;
        input [511:0] x;
        integer i;
        begin
            for(i=0;i<64;i=i+1)
                rev64[8*i +: 8]=x[511-8*i -: 8];
        end
    endfunction
    kdy_sha2 u_sha (
        .clk(clk),
        .rst_n(rst_n),
        .start(sha_start),
        .data_i(sha_data),
        .hash_o(sha_digest),
        .done(sha_done)
    );
    ed25519_reduce_l u_reduce (
        .clk(clk),.rst_n(rst_n),.start(reduce_start),
        .value(reduce_input),.result(mod_result),
        .done(reduce_done),.busy(reduce_busy)
    );
    ed25519_muladd_wide u_muladd (
        .clk(clk),.rst_n(rst_n),.start(muladd_start),
        .h(h_reg),.a(a_reg),.r(r_reg),
        .value(wide_result),.done(muladd_done),.busy(muladd_busy)
    );
    Point_Multi_ED25519 u_point (
        .clk(clk),.rst_n(rst_n),.start(point_start),.valid(1'b1),
        .k(r_point_scalar),.px(BASE_X),.py(BASE_Y),
        .qx(point_x),.qy(point_y),.done(point_done),.ready(point_ready)
    );
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=IDLE;
            a_reg<=0;prefix_reg<=0;pub_reg<=0;r_reg<=0;h_reg<=0;R_enc<=0;
            msg_reg<=0;len_reg<=0;
            sha_start<=0; reduce_start<=0; point_start<=0; muladd_start<=0;
            sha_data<=0;sha_bytes<=0;reduce_input<=0;
            signature<=0;done<=0;error<=0;
        end else begin
            done<=0;
            sha_start<=0;
            reduce_start<=0;
            point_start<=0;
            muladd_start<=0;
            case(state)
                IDLE: if(start) begin
                    error<=0;
                    if(msg_len > 7'd64) begin
                        error<=1;
                        done<=1;
                    end else begin
                        a_reg<=secret_scalar;
                        prefix_reg<=prefix;
                        pub_reg<=public_key;
                        msg_reg<=msg_be;
                        len_reg<=msg_len;
                        state<=R_HASH_START;
                    end
                end
                R_HASH_START: begin
                    // SHA512(prefix || M): 32 + len <= 96 octets.
                    sha_data<={prefix_reg,msg_reg,256'd0};
                    sha_bytes<=8'd32+{1'b0,len_reg};
                    sha_start<=1;
                    state<=R_HASH_WAIT;
                end
                R_HASH_WAIT: if(sha_done) begin
                    reduce_input<=rev64(sha_digest);
                    reduce_start<=1;
                    state<=R_REDUCE_WAIT;
                end
                R_REDUCE_WAIT: if(reduce_done) begin
                    r_reg<=mod_result;
                    if(mod_result==0) begin
                        // 0*B = identity, encoding y=1,x=0 in LE bytes.
                        R_enc<={8'h01,248'd0};
                        state<=H_HASH_START;
                    end else state<=R_POINT_REQ;
                end
                R_POINT_REQ: if(point_ready) begin
                    point_start<=1;
                    state<=R_POINT_WAIT;
                end
                R_POINT_WAIT: if(point_done) begin
                    R_enc<=rev32({point_x[0],point_y[254:0]});
                    state<=H_HASH_START;
                end
                H_HASH_START: begin
                    // SHA512(R || A || M): 64 + len <= 128 octets.
                    sha_data<={R_enc,pub_reg,msg_reg};
                    sha_bytes<=8'd64+{1'b0,len_reg};
                    sha_start<=1;
                    state<=H_HASH_WAIT;
                end
                H_HASH_WAIT: if(sha_done) begin
                    reduce_input<=rev64(sha_digest);
                    reduce_start<=1;
                    state<=H_REDUCE_WAIT;
                end
                H_REDUCE_WAIT: if(reduce_done) begin
                    h_reg<=mod_result;
                    muladd_start<=1;
                    state<=MULADD_WAIT;
                end
                MULADD_WAIT: if(muladd_done) begin
                    reduce_input<=wide_result;
                    reduce_start<=1;
                    state<=S_REDUCE_WAIT;
                end
                S_REDUCE_WAIT: if(reduce_done) begin
                    signature<={R_enc,rev32(mod_result)};
                    done<=1;
                    state<=IDLE;
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule