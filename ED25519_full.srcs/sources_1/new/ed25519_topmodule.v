`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2026 03:08:31 PM
// Design Name: 
// Module Name: ed25519_topmodule
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


module ed25519_topmodule(
input wire clk, rst_n,
    input wire start_keygen, start_sign,
    input wire [255:0] seed_be,
    input wire [511:0] msg_be,
    input wire [6:0] msg_len,
    output wire [255:0] public_key,
    output wire [511:0] signature,
    output wire keygen_done, sign_done, sign_error,
    output wire keygen_busy, sign_busy,
    output reg keys_ready
);
    wire [255:0] a_secret,prefix_secret;
    wire do_sign=start_sign && keys_ready && !keygen_busy && !sign_busy;
    wire do_keygen=start_keygen && !keygen_busy && !sign_busy;
    key_expansion u_keygen (
        .clk(clk),.rst_n(rst_n),.start(do_keygen),.seed_be(seed_be),
        .public_key(public_key),.secret_scalar(a_secret),.prefix(prefix_secret),
        .done(keygen_done),.busy(keygen_busy)
    );
    ed25519_sign u_sign (
        .clk(clk),.rst_n(rst_n),.start(do_sign),
        .secret_scalar(a_secret),.prefix(prefix_secret),.public_key(public_key),
        .msg_be(msg_be),.msg_len(msg_len),
        .signature(signature),.done(sign_done),.error(sign_error),.busy(sign_busy)
    );
    always @(posedge clk) begin
        if (!rst_n) keys_ready<=1'b0;
        else if(do_keygen) keys_ready<=1'b0;
        else if(keygen_done) keys_ready<=1'b1;
    end
endmodule
