`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2026 03:18:26 PM
// Design Name: 
// Module Name: tb_ed25519
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


module tb_ed25519();
    reg clk;
    reg rst_n;
    reg start_keygen, start_sign;
    reg [255:0] seed_be;
    reg [511:0] msg_be;
    reg [6:0] msg_len;

    wire [255:0] public_key;
    wire [511:0] signature;
    wire keygen_done, sign_done, sign_error;
    wire keygen_busy, sign_busy, keys_ready;

    integer tests, fails;
    integer cycles;
    reg [511:0] signature_before;

    // Optional 32-byte and 63-byte boundary cases (additional runtime).
    parameter RUN_STRESS = 0;
    localparam integer KEY_TIMEOUT  = 5000000;
    localparam integer SIGN_TIMEOUT = 5000000;

    localparam [255:0] SEED_1 = 256'h9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60;
    localparam [255:0] SEED_2 = 256'h4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb;
    localparam [255:0] SEED_3 = 256'hc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7;
    localparam [255:0] PUB_1  = 256'hd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a;
    localparam [255:0] PUB_2  = 256'h3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c;
    localparam [255:0] PUB_3  = 256'hfc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025;

    // Signature vectors: RFC 8032 section 7.1 (cases 1,2,3), plus
    // fixed known-answer vectors from an independent Ed25519 implementation.
    localparam [511:0] SIG_1_EMPTY = 512'he5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b;
    localparam [511:0] SIG_2_72    = 512'h92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00;
    localparam [511:0] SIG_3_AF82  = 512'h6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a;
    localparam [511:0] SIG_1_64    = 512'h2dc5736c5188aa2a615768c465cf49934f561cbfddc4ebf8cfb6cf323efc2e71c91b48cb26c2699ce2f56e24ace6dcc51f9cc7fb992a55c833c0889111f4ba03;
    localparam [511:0] SIG_1_72    = 512'h1b79abc415a34efe5915b4c1b53d2435e731b3c92d0ba440de29cab2999fa885bd0eb3c71dfd8df6fbecf8c0ef403e8902dec8e2abd00ab9b04b1df027929609;
    localparam [511:0] SIG_1_32    = 512'h355c74053a380ab58b298de23adcca49f39b7ca50a2cec5b861f6c7fddf87c8a53b78c7bb3959268c0db1edeb0440786839ef5defaad623290076198560b3c02;
    localparam [511:0] SIG_1_63    = 512'hba94bb95061862773199259c67a9a66b5001770aa85509d275894c0214649713513273a1c97eb64621330578c9b1a4ef1b855930f7eaf71665b1fd4ccb66c30d;
    localparam [511:0] MSG_64     = 512'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f;

    ed25519_topmodule dut (
        .clk(clk), .rst_n(rst_n),
        .start_keygen(start_keygen), .start_sign(start_sign),
        .seed_be(seed_be), .msg_be(msg_be), .msg_len(msg_len),
        .public_key(public_key), .signature(signature),
        .keygen_done(keygen_done), .sign_done(sign_done),
        .sign_error(sign_error),
        .keygen_busy(keygen_busy), .sign_busy(sign_busy),
        .keys_ready(keys_ready)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz

    task check;
        input [8*64-1:0] what;
        input condition;
        begin
            tests = tests + 1;
            if (condition === 1'b1)
                $display("[PASS] %0s", what);
            else begin
                fails = fails + 1;
                $display("[FAIL] %0s", what);
            end
        end
    endtask

    task run_keygen;
        input [8*64-1:0] label;
        input [255:0] input_seed;
        input [255:0] expected_pub;
        begin
            $display("\n========== KEYGEN: %0s =========", label);
            @(negedge clk);
            seed_be = input_seed;
            start_keygen = 1'b1;
            @(negedge clk);
            start_keygen = 1'b0;
            #1;
            check("keys_ready clears on new keygen", keys_ready === 1'b0);
            check("keygen_busy asserted", keygen_busy === 1'b1);

            // A signing request during key generation must be ignored.
            if (input_seed == SEED_1) begin
                @(negedge clk); start_sign = 1'b1;
                @(negedge clk); start_sign = 1'b0;
                #1;
                check("sign blocked while keygen busy",
                      sign_busy === 1'b0 && sign_done === 1'b0);
            end

            cycles = 0;
            while (keygen_done !== 1'b1 && cycles < KEY_TIMEOUT) begin
                @(posedge clk); #1;
                cycles = cycles + 1;
            end
            if (keygen_done !== 1'b1) begin
                $display("[TIMEOUT] KEYGEN after %0d cycles", cycles);
                $finish;
            end
            $display("[INFO] keygen latency = %0d cycles", cycles);
            check("public_key matches reference", public_key === expected_pub);
            if (public_key !== expected_pub)
                $display("       got=%064h\n       exp=%064h", public_key, expected_pub);

            // keys_ready is updated by the parent on the clock AFTER
            // keygen_done goes high (non-blocking sequential logic).
            @(posedge clk); #1;
            check("keys_ready becomes 1", keys_ready === 1'b1);
            check("keygen_busy becomes 0", keygen_busy === 1'b0);
        end
    endtask

    task run_sign;
        input [8*64-1:0] label;
        input [511:0] input_msg;
        input [6:0] input_len;
        input [511:0] expected_sig;
        begin
            $display("\n========== SIGN: %0s (len=%0d) =========", label, input_len);
            @(negedge clk);
            msg_be = input_msg;
            msg_len = input_len;
            start_sign = 1'b1;
            @(negedge clk);
            start_sign = 1'b0;
            #1;
            check("sign_busy asserted", sign_busy === 1'b1);

            // A re-key request during signing must be ignored.
            if (input_len == 7'd0) begin
                @(negedge clk); start_keygen = 1'b1;
                @(negedge clk); start_keygen = 1'b0;
                #1;
                check("keygen blocked while sign busy",
                      keygen_busy === 1'b0 && keys_ready === 1'b1);
            end

            cycles = 0;
            while (sign_done !== 1'b1 && cycles < SIGN_TIMEOUT) begin
                @(posedge clk); #1;
                cycles = cycles + 1;
            end
            if (sign_done !== 1'b1) begin
                $display("[TIMEOUT] SIGN after %0d cycles", cycles);
                $finish;
            end
            $display("[INFO] sign latency = %0d cycles", cycles);
            check("sign_error is 0", sign_error === 1'b0);
            check("signature matches reference", signature === expected_sig);
            if (signature !== expected_sig)
                $display("       got=%0128h\n       exp=%0128h", signature, expected_sig);
            @(posedge clk); #1;
            check("sign_busy returns to 0", sign_busy === 1'b0);
            check("keys_ready remains set", keys_ready === 1'b1);
        end
    endtask

    task sign_invalid_length;
        begin
            $display("\n========== NEGATIVE: msg_len=65 =========");
            signature_before = signature;
            @(negedge clk);
            msg_be = MSG_64;
            msg_len = 7'd65;
            start_sign = 1'b1;
            @(negedge clk);
            start_sign = 1'b0;
            #1;
            // ed25519_sign reports invalid length immediately in IDLE.
            check("invalid length raises sign_done", sign_done === 1'b1);
            check("invalid length raises sign_error", sign_error === 1'b1);
            check("invalid length does not set sign_busy", sign_busy === 1'b0);
            check("signature unchanged after error", signature === signature_before);
        end
    endtask

    initial begin
        rst_n = 0;
        start_keygen = 0;
        start_sign = 0;
        seed_be = 0;
        msg_be = 0;
        msg_len = 0;
        tests = 0;
        fails = 0;
        signature_before = 0;
        repeat (5) @(negedge clk);
        rst_n = 1;
        @(posedge clk); #1;
        check("keys_ready=0 after reset", keys_ready === 1'b0);

        // Sign request before key generation MUST be rejected by top gate.
        @(negedge clk);
        start_sign = 1;
        @(negedge clk);
        start_sign = 0;
        #1;
        check("sign before keygen is ignored", sign_busy === 1'b0 &&
              sign_done === 1'b0 && keys_ready === 1'b0);

        // RFC 8032 TEST 1: seed1, empty message.
        run_keygen("RFC 8032 #1", SEED_1, PUB_1);
        run_sign("RFC 8032 #1 empty", 512'd0, 7'd0, SIG_1_EMPTY);

        // 64-byte boundary causes SHA512(R||A||M) to hash 128 bytes,
        // requiring two SHA-512 blocks (signature reference is fixed).
        run_sign("64-byte boundary", MSG_64, 7'd64, SIG_1_64);
        sign_invalid_length();
        // A new valid signing request must clear a previous sign_error.
        run_sign("recovery after invalid length", {8'h72,504'd0}, 7'd1, SIG_1_72);

        if (RUN_STRESS) begin
            run_sign("32 zero bytes", 512'd0, 7'd32, SIG_1_32);
            run_sign("63 bytes FF", {{504{1'b1}},8'd0}, 7'd63, SIG_1_63);
        end

        // RFC 8032 TEST 2: re-key without global reset, 1 byte message.
        run_keygen("RFC 8032 #2 / rekey", SEED_2, PUB_2);
        run_sign("RFC 8032 #2", {8'h72,504'd0}, 7'd1, SIG_2_72);

        // RFC 8032 TEST 3: re-key without global reset, 2 byte message.
        run_keygen("RFC 8032 #3 / rekey", SEED_3, PUB_3);
        run_sign("RFC 8032 #3", {16'haf82,496'd0}, 7'd2, SIG_3_AF82);

        $display("\n==========================================");
        $display("FINAL: checks=%0d fails=%0d", tests, fails);
        if (fails == 0) $display("ALL PASS");
        else            $display("TEST FAILED");
        $display("==========================================");
        $finish;
    end
endmodule

