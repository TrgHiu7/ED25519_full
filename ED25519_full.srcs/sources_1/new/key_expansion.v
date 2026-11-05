`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 05:00:33 PM
// Design Name: 
// Module Name: key_expansion
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


module key_expansion(
    input wire clk, rst_n, start,
    input wire [255:0] seed_be,
    output reg [255:0] public_key,
    output reg [255:0] secret_scalar,
    output reg [255:0] prefix,
    output reg done,
    output wire busy
);
    localparam [255:0] BASE_X =
        256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BASE_Y =
        256'h6666666666666666666666666666666666666666666666666666666666666658;
    localparam [3:0] IDLE=0, HASH_START=1, HASH_WAIT=2,
                     POINT_REQ=3, POINT_WAIT=4;
    reg [3:0] state;
    reg [255:0] seed_reg;
    reg hash_start, point_start;
    wire [511:0] digest;
    wire hash_done, hash_busy;
    wire [255:0] point_x, point_y;
    wire point_done, point_ready;
    wire [1023:0] hash_data={seed_reg,768'd0};
    assign busy=(state!=IDLE);

    function [255:0] rev32;
        input [255:0] x;
        integer i;
        begin
            for(i=0;i<32;i=i+1)
                rev32[8*i +: 8] = x[255-8*i -: 8];
        end
    endfunction
    function [255:0] clamp_scalar;
        input [255:0] hash_first32;
        reg [255:0] t;
        begin
            t=rev32(hash_first32);
            t[2:0]=3'b000;
            t[255]=1'b0;
            t[254]=1'b1;
            clamp_scalar=t;
        end
    endfunction
    kdy_sha2 u_sha (
        .clk(clk),
        .rst_n(rst_n),
        .start(hash_start),
        .data_i(hash_data),
        .hash_o(digest),
        .done(hash_done)
    );
    Point_Multi_ED25519 u_point (
        .clk(clk),.rst_n(rst_n),.start(point_start),.valid(1'b1),
        .k(secret_scalar),.px(BASE_X),.py(BASE_Y),
        .qx(point_x),.qy(point_y),.done(point_done),.ready(point_ready)
    );
    always @(posedge clk) begin
        if(!rst_n) begin
            state<=IDLE;
            seed_reg<=0;
            hash_start<=0; point_start<=0;
            public_key<=0; secret_scalar<=0; prefix<=0;
            done<=0;
        end else begin
            done<=0;
            hash_start<=0;
            point_start<=0;
            case(state)
                IDLE: if(start) begin
                    seed_reg<=seed_be;
                    state<=HASH_START;
                end
                HASH_START: begin
                    hash_start<=1;
                    state<=HASH_WAIT;
                end
                HASH_WAIT: if(hash_done) begin
                    secret_scalar<=clamp_scalar(digest[511:256]);
                    prefix<=digest[255:0];
                    state<=POINT_REQ;
                end
                POINT_REQ: if(point_ready) begin
                    point_start<=1;
                    state<=POINT_WAIT;
                end
                POINT_WAIT: if(point_done) begin
                    // Numerical compressed point = y | ((x&1)<<255).
                    // RFC8032 byte order is little-endian, hence rev32.
                    public_key<=rev32({point_x[0],point_y[254:0]});
                    done<=1;
                    state<=IDLE;
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule