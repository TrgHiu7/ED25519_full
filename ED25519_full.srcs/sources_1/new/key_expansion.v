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
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [255:0] secret,

    output reg  [255:0] a,
    output reg  [255:0] prefix,
    output wire         busy,
    output reg          done
);

    localparam [1:0]
        S_IDLE   = 2'd0,
        S_EXPAND = 2'd1,
        S_ROUND  = 2'd2,
        S_DONE   = 2'd3;

    reg [1:0] state;
    reg [6:0] index;

    reg [63:0] W [0:79];

    reg [63:0] av, bv, cv, dv, ev, fv, gv, hv;

    localparam [63:0] IV0 = 64'h6a09e667f3bcc908;
    localparam [63:0] IV1 = 64'hbb67ae8584caa73b;
    localparam [63:0] IV2 = 64'h3c6ef372fe94f82b;
    localparam [63:0] IV3 = 64'ha54ff53a5f1d36f1;
    localparam [63:0] IV4 = 64'h510e527fade682d1;
    localparam [63:0] IV5 = 64'h9b05688c2b3e6c1f;
    localparam [63:0] IV6 = 64'h1f83d9abfb41bd6b;
    localparam [63:0] IV7 = 64'h5be0cd19137e2179;

    assign busy = (state != S_IDLE);

    // Rotate-right.
    function [63:0] rotr64;
        input [63:0] x;
        input [6:0]  n;
        begin
            rotr64 = (x >> n) | (x << (64 - n));
        end
    endfunction

    function [63:0] big_sigma0;
        input [63:0] x;
        begin
            big_sigma0 = rotr64(x, 7'd28) ^ rotr64(x, 7'd34) ^ rotr64(x, 7'd39);
        end
    endfunction

    function [63:0] big_sigma1;
        input [63:0] x;
        begin
            big_sigma1 = rotr64(x, 7'd14) ^ rotr64(x, 7'd18) ^ rotr64(x, 7'd41);
        end
    endfunction

    function [63:0] small_sigma0;
        input [63:0] x;
        begin
            small_sigma0 = rotr64(x, 7'd1) ^ rotr64(x, 7'd8) ^ (x >> 7);
        end
    endfunction

    function [63:0] small_sigma1;
        input [63:0] x;
        begin
            small_sigma1 = rotr64(x, 7'd19) ^ rotr64(x, 7'd61) ^ (x >> 6);
        end
    endfunction

    function [63:0] choose;
        input [63:0] x, y, z;
        begin
            choose = (x & y) ^ ((~x) & z);
        end
    endfunction

    function [63:0] majority;
        input [63:0] x, y, z;
        begin
            majority = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    // SHA-512 round constants.
    function [63:0] K;
        input [6:0] i;
        begin
            case (i)
                7'd0 : K=64'h428a2f98d728ae22;  7'd1 : K=64'h7137449123ef65cd;
                7'd2 : K=64'hb5c0fbcfec4d3b2f;  7'd3 : K=64'he9b5dba58189dbbc;
                7'd4 : K=64'h3956c25bf348b538;  7'd5 : K=64'h59f111f1b605d019;
                7'd6 : K=64'h923f82a4af194f9b;  7'd7 : K=64'hab1c5ed5da6d8118;
                7'd8 : K=64'hd807aa98a3030242;  7'd9 : K=64'h12835b0145706fbe;
                7'd10: K=64'h243185be4ee4b28c;  7'd11: K=64'h550c7dc3d5ffb4e2;
                7'd12: K=64'h72be5d74f27b896f;  7'd13: K=64'h80deb1fe3b1696b1;
                7'd14: K=64'h9bdc06a725c71235;  7'd15: K=64'hc19bf174cf692694;
                7'd16: K=64'he49b69c19ef14ad2;  7'd17: K=64'hefbe4786384f25e3;
                7'd18: K=64'h0fc19dc68b8cd5b5;  7'd19: K=64'h240ca1cc77ac9c65;
                7'd20: K=64'h2de92c6f592b0275;  7'd21: K=64'h4a7484aa6ea6e483;
                7'd22: K=64'h5cb0a9dcbd41fbd4;  7'd23: K=64'h76f988da831153b5;
                7'd24: K=64'h983e5152ee66dfab;  7'd25: K=64'ha831c66d2db43210;
                7'd26: K=64'hb00327c898fb213f;  7'd27: K=64'hbf597fc7beef0ee4;
                7'd28: K=64'hc6e00bf33da88fc2;  7'd29: K=64'hd5a79147930aa725;
                7'd30: K=64'h06ca6351e003826f;  7'd31: K=64'h142929670a0e6e70;
                7'd32: K=64'h27b70a8546d22ffc;  7'd33: K=64'h2e1b21385c26c926;
                7'd34: K=64'h4d2c6dfc5ac42aed;  7'd35: K=64'h53380d139d95b3df;
                7'd36: K=64'h650a73548baf63de;  7'd37: K=64'h766a0abb3c77b2a8;
                7'd38: K=64'h81c2c92e47edaee6;  7'd39: K=64'h92722c851482353b;
                7'd40: K=64'ha2bfe8a14cf10364;  7'd41: K=64'ha81a664bbc423001;
                7'd42: K=64'hc24b8b70d0f89791;  7'd43: K=64'hc76c51a30654be30;
                7'd44: K=64'hd192e819d6ef5218;  7'd45: K=64'hd69906245565a910;
                7'd46: K=64'hf40e35855771202a;  7'd47: K=64'h106aa07032bbd1b8;
                7'd48: K=64'h19a4c116b8d2d0c8;  7'd49: K=64'h1e376c085141ab53;
                7'd50: K=64'h2748774cdf8eeb99;  7'd51: K=64'h34b0bcb5e19b48a8;
                7'd52: K=64'h391c0cb3c5c95a63;  7'd53: K=64'h4ed8aa4ae3418acb;
                7'd54: K=64'h5b9cca4f7763e373;  7'd55: K=64'h682e6ff3d6b2b8a3;
                7'd56: K=64'h748f82ee5defb2fc;  7'd57: K=64'h78a5636f43172f60;
                7'd58: K=64'h84c87814a1f0ab72;  7'd59: K=64'h8cc702081a6439ec;
                7'd60: K=64'h90befffa23631e28;  7'd61: K=64'ha4506cebde82bde9;
                7'd62: K=64'hbef9a3f7b2c67915;  7'd63: K=64'hc67178f2e372532b;
                7'd64: K=64'hca273eceea26619c;  7'd65: K=64'hd186b8c721c0c207;
                7'd66: K=64'heada7dd6cde0eb1e;  7'd67: K=64'hf57d4f7fee6ed178;
                7'd68: K=64'h06f067aa72176fba;  7'd69: K=64'h0a637dc5a2c898a6;
                7'd70: K=64'h113f9804bef90dae;  7'd71: K=64'h1b710b35131c471b;
                7'd72: K=64'h28db77f523047d84;  7'd73: K=64'h32caab7b40c72493;
                7'd74: K=64'h3c9ebe0a15c9bebc;  7'd75: K=64'h431d67c49c100d4c;
                7'd76: K=64'h4cc5d4becb3e42b6;  7'd77: K=64'h597f299cfc657e2a;
                7'd78: K=64'h5fcb6fab3ad6faec;  7'd79: K=64'h6c44198c4a475817;
                default: K=64'd0;
            endcase
        end
    endfunction

    // Read eight little-endian-packed input bytes and form one SHA-512
    // big-endian 64-bit message word.
    function [63:0] secret_word;
        input [255:0] s;
        input [1:0] word_index;
        integer base;
        begin
            base = word_index * 64;
            secret_word = {
                s[base +  0 +: 8], s[base +  8 +: 8],
                s[base + 16 +: 8], s[base + 24 +: 8],
                s[base + 32 +: 8], s[base + 40 +: 8],
                s[base + 48 +: 8], s[base + 56 +: 8]
            };
        end
    endfunction

    // Convert four SHA digest words (network byte order) into the packed
    // little-endian byte convention used by this design.
    function [255:0] digest_words_to_le256;
        input [63:0] d0, d1, d2, d3;
        reg [255:0] be;
        integer j;
        begin
            be = {d0, d1, d2, d3};
            for (j = 0; j < 32; j = j + 1)
                digest_words_to_le256[j*8 +: 8] = be[255-j*8 -: 8];
        end
    endfunction

    wire [63:0] wt = W[index];
    wire [63:0] t1 = hv + big_sigma1(ev) + choose(ev, fv, gv) + K(index) + wt;
    wire [63:0] t2 = big_sigma0(av) + majority(av, bv, cv);

    // Values after the currently selected SHA-512 round.
    wire [63:0] next_a = t1 + t2;
    wire [63:0] next_b = av;
    wire [63:0] next_c = bv;
    wire [63:0] next_d = cv;
    wire [63:0] next_e = dv + t1;
    wire [63:0] next_f = ev;
    wire [63:0] next_g = fv;
    wire [63:0] next_h = gv;

    wire [63:0] digest0 = IV0 + next_a;
    wire [63:0] digest1 = IV1 + next_b;
    wire [63:0] digest2 = IV2 + next_c;
    wire [63:0] digest3 = IV3 + next_d;
    wire [63:0] digest4 = IV4 + next_e;
    wire [63:0] digest5 = IV5 + next_f;
    wire [63:0] digest6 = IV6 + next_g;
    wire [63:0] digest7 = IV7 + next_h;

    function [255:0] clamp_ed25519_scalar;
        input [255:0] x;
        reg [255:0] t;
        begin
            t = x;
            t[2:0] = 3'b000;
            t[255] = 1'b0;
            t[254] = 1'b1;
            clamp_ed25519_scalar = t;
        end
    endfunction

    wire [255:0] first_half_raw = digest_words_to_le256(
        digest0, digest1, digest2, digest3);
    wire [255:0] second_half_raw = digest_words_to_le256(
        digest4, digest5, digest6, digest7);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= S_IDLE;
            index   <= 7'd0;
            av      <= 64'd0;
            bv      <= 64'd0;
            cv      <= 64'd0;
            dv      <= 64'd0;
            ev      <= 64'd0;
            fv      <= 64'd0;
            gv      <= 64'd0;
            hv      <= 64'd0;
            a       <= 256'd0;
            prefix  <= 256'd0;
            done    <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start) begin
                        // 32 message bytes -> W[0..3].
                        W[0]  <= secret_word(secret, 2'd0);
                        W[1]  <= secret_word(secret, 2'd1);
                        W[2]  <= secret_word(secret, 2'd2);
                        W[3]  <= secret_word(secret, 2'd3);

                        // SHA-512 padding for a 256-bit message:
                        // byte 32 = 0x80, then zeros, then 128-bit length = 256.
                        W[4]  <= 64'h8000000000000000;
                        W[5]  <= 64'd0;
                        W[6]  <= 64'd0;
                        W[7]  <= 64'd0;
                        W[8]  <= 64'd0;
                        W[9]  <= 64'd0;
                        W[10] <= 64'd0;
                        W[11] <= 64'd0;
                        W[12] <= 64'd0;
                        W[13] <= 64'd0;
                        W[14] <= 64'd0;
                        W[15] <= 64'd256;

                        index <= 7'd16;
                        state <= S_EXPAND;
                    end
                end

                S_EXPAND: begin
                    W[index] <= small_sigma1(W[index-2]) + W[index-7]
                              + small_sigma0(W[index-15]) + W[index-16];

                    if (index == 7'd79) begin
                        av <= IV0;
                        bv <= IV1;
                        cv <= IV2;
                        dv <= IV3;
                        ev <= IV4;
                        fv <= IV5;
                        gv <= IV6;
                        hv <= IV7;
                        index <= 7'd0;
                        state <= S_ROUND;
                    end else begin
                        index <= index + 7'd1;
                    end
                end

                S_ROUND: begin
                    if (index == 7'd79) begin
                        // Final round. Add the initial hash values and map the
                        // digest bytes to Ed25519's little-endian scalar format.
                        // Ed25519 pruning / clamping:
                        // h[0]  &= 248  -> clear scalar bits 0,1,2
                        // h[31] &= 127  -> clear scalar bit 255
                        // h[31] |= 64   -> set   scalar bit 254
                        a      <= clamp_ed25519_scalar(first_half_raw);
                        prefix <= second_half_raw;
                        state  <= S_DONE;
                    end else begin
                        av <= next_a;
                        bv <= next_b;
                        cv <= next_c;
                        dv <= next_d;
                        ev <= next_e;
                        fv <= next_f;
                        gv <= next_g;
                        hv <= next_h;
                        index <= index + 7'd1;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule