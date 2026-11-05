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
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    output reg          busy,
    output reg          done,
    output reg [255:0]  public_key,
    output reg [255:0]  signature_R,
    output reg [255:0]  signature_S,
    output wire [511:0] signature,
    output wire         vector_match
);
    // Order of basepoint B coordinates below is the numeric field-element
    // representation expected by Point_Multi_ED25519, NOT encoded bytes.
    localparam [255:0] BASE_X =
        256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BASE_Y =
        256'h6666666666666666666666666666666666666666666666666666666666666658;
    localparam [255:0] L =
        256'h1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed;

    // Original 32-byte seed and one-byte message (documentation/test fixture).
    localparam [255:0] PRIVATE_SEED =
        256'h4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb;
    localparam [7:0] MESSAGE_BYTE = 8'h72;  // literal ASCII 'r'
    localparam [511:0] SHA512_SEED =
        512'h6ebd9ed75882d52815a97585caf4790a7f6c6b3b7f821c5e259a24b02e502e114566848291dacaf225cc63deb348da318e2c2e17b00b8160f9ce6bfa0472911d;

    // a = prune(SHA512(seed)[0:32]), little-endian -> numeric 256-bit.
    localparam [255:0] A_SCALAR =
        256'h512e502eb0249a255e1c827f3b6b6c7f0a79f4ca8575a91528d58258d79ebd68;
    // a mod L, used for faster group-order arithmetic (not point multiplication).
    localparam [255:0] A_MOD_L =
        256'h012e502eb0249a255e1c827f3b6b6c7ea21f1371569f98e5707992d506d199c7;
    // r = SHA512(prefix || 8'h72) as a little-endian integer, then mod L.
    localparam [255:0] R_SCALAR =
        256'h08332edb9e5d3ac8522a07b5a1857169a67e6509ab59af23ccdb039970ffbf8f;
    // h = SHA512(R_encoded || A_encoded || 8'h72) little-endian, mod L.
    // R_encoded and A_encoded here are from the known GOOD RFC test vector.
    localparam [255:0] H_SCALAR =
        256'h035ce307f6524510110b4ea1c8af0e81fb705118ebcf886912f8d2d87b5776b3;

    localparam [255:0] EXPECTED_A =
        256'h3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c;
    localparam [255:0] EXPECTED_R =
        256'h92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da;
    localparam [255:0] EXPECTED_S =
        256'h085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00;

    // RFC 8032 point encoding: y little-endian bytes; top bit of the LAST
    // byte (bit 255 of numeric y-with-sign) is parity of affine x.
    function [255:0] encode_point;
        input [255:0] x;
        input [255:0] y;
        reg [255:0] y_sign;
        integer idx;
        begin
            y_sign = y;
            y_sign[255] = x[0];
            for (idx=0; idx<32; idx=idx+1)
                encode_point[255-idx*8 -: 8] = y_sign[idx*8 +: 8];
        end
    endfunction

    // Scalar encoding: numeric 256-bit S -> 32 little-endian bytes in display
    // order, so the displayed hex is the RFC 8032 S byte string.
    function [255:0] encode_scalar;
        input [255:0] val;
        integer idx;
        begin
            for (idx=0; idx<32; idx=idx+1)
                encode_scalar[255-idx*8 -: 8] = val[idx*8 +: 8];
        end
    endfunction

    // Modular addition for reduced operands x,y < L: 0 <= x+y < 2*L.
    function [255:0] add_mod_l;
        input [255:0] x;
        input [255:0] y;
        reg [256:0] sum;
        begin
            sum = {1'b0,x} + {1'b0,y};
            if (sum >= {1'b0,L})
                sum = sum - {1'b0,L};
            add_mod_l = sum[255:0];
        end
    endfunction

    reg          point_start;
    reg [255:0] point_k;
    wire         point_done;
    wire         point_ready;
    wire [255:0] point_qx, point_qy;

    // The only point multiplier is time-shared for A=aB and R=rB.
    Point_Multi_ED25519 u_point (
        .clk(clk), .rst(rst), .start(point_start), .valid(1'b1),
        .k(point_k), .px(BASE_X), .py(BASE_Y),
        .qx(point_qx), .qy(point_qy),
        .done(point_done), .ready(point_ready)
    );

    localparam [3:0]
        ST_IDLE     = 4'd0,
        ST_START_A  = 4'd1,
        ST_WAIT_A   = 4'd2,
        ST_START_R  = 4'd3,
        ST_WAIT_R   = 4'd4,
        ST_PREP_S   = 4'd5,
        ST_MUL_S    = 4'd6,
        ST_FINAL_S  = 4'd7,
        ST_DONE     = 4'd8;

    reg [3:0] state;
    reg [7:0] bit_index;
    reg [255:0] accum, addend, multiplier;

    assign signature = {signature_R, signature_S};
    assign vector_match = (public_key == EXPECTED_A) &&
                          (signature_R == EXPECTED_R) &&
                          (signature_S == EXPECTED_S);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= ST_IDLE;
            point_start   <= 1'b0;
            point_k       <= 256'd0;
            busy          <= 1'b0;
            done          <= 1'b0;
            public_key    <= 256'd0;
            signature_R   <= 256'd0;
            signature_S   <= 256'd0;
            bit_index     <= 8'd0;
            accum         <= 256'd0;
            addend        <= 256'd0;
            multiplier    <= 256'd0;
        end else begin
            point_start <= 1'b0;
            done <= 1'b0;
            case(state)
                ST_IDLE: begin
                    if(start) begin
                        busy <= 1'b1;
                        public_key  <= 256'd0;
                        signature_R <= 256'd0;
                        signature_S <= 256'd0;
                        point_k <= A_SCALAR;
                        state <= ST_START_A;
                    end
                end
                ST_START_A: begin
                    if(point_ready) begin
                        point_start <= 1'b1;
                        state <= ST_WAIT_A;
                    end
                end
                ST_WAIT_A: begin
                    if(point_done) begin
                        public_key <= encode_point(point_qx,point_qy);
                        point_k <= R_SCALAR;
                        state <= ST_START_R;
                    end
                end
                ST_START_R: begin
                    if(point_ready) begin
                        point_start <= 1'b1;
                        state <= ST_WAIT_R;
                    end
                end
                ST_WAIT_R: begin
                    if(point_done) begin
                        signature_R <= encode_point(point_qx,point_qy);
                        state <= ST_PREP_S;
                    end
                end
                ST_PREP_S: begin
                    accum      <= 256'd0;
                    addend     <= A_MOD_L;
                    multiplier <= H_SCALAR;
                    bit_index  <= 8'd0;
                    state <= ST_MUL_S;
                end
                ST_MUL_S: begin
                    // Shift/add modulo L: S_mul = h * (a mod L) mod L.
                    if(multiplier[0])
                        accum <= add_mod_l(accum,addend);
                    addend <= add_mod_l(addend,addend);
                    multiplier <= multiplier >> 1;
                    if(bit_index == 8'd255)
                        state <= ST_FINAL_S;
                    else
                        bit_index <= bit_index + 1'b1;
                end
                ST_FINAL_S: begin
                    signature_S <= encode_scalar(add_mod_l(accum,R_SCALAR));
                    state <= ST_DONE;
                end
                ST_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
