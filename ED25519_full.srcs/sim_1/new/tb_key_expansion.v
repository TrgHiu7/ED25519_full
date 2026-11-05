`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 05:23:12 PM
// Design Name: 
// Module Name: tb_key_expansion
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


module tb_key_expansion;
    reg          clk;
    reg          rst_n;
    reg          start;
    reg [255:0]  seed_be;

    wire [255:0] public_key;
    wire [255:0] secret_scalar;
    wire [255:0] prefix;
    wire         done;
    wire         busy;

    // Scalar multiplication of a clamped 255-bit scalar can take
    // millions of cycles. Increase if your ECC architecture is slower.
    localparam integer TIMEOUT_CYCLES = 5000000;
    integer passed, failed, cycles;

    key_expansion dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .seed_be(seed_be),
        .public_key(public_key),
        .secret_scalar(secret_scalar),
        .prefix(prefix),
        .done(done),
        .busy(busy)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz

    task automatic check_case;
        input integer     test_id;
        input [255:0]     input_seed;
        input [255:0]     expected_pk;
        input [255:0]     expected_scalar;
        input [255:0]     expected_prefix;
        reg               case_ok;
        begin
            case_ok = 1'b1;
            // Start only when idle. Check that every request is accepted.
            @(negedge clk);
            seed_be = input_seed;
            start   = 1'b1;
            @(posedge clk);
            #1;
            if (busy !== 1'b1) begin
                $display("[FAIL] Test %0d: busy did not assert", test_id);
                case_ok = 1'b0;
            end
            @(negedge clk);
            start = 1'b0;
            // Change external seed after acceptance to check input latching.
            seed_be = 256'd0;

            cycles = 0;
            while ((done !== 1'b1) && (cycles < TIMEOUT_CYCLES)) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (done !== 1'b1) begin
                $display("[FAIL] Test %0d: TIMEOUT after %0d cycles (busy=%b)",
                         test_id, cycles, busy);
                case_ok = 1'b0;
            end else begin
                if (public_key !== expected_pk) begin
                    $display("[FAIL] Test %0d: public_key", test_id);
                    $display("       GOT = %064h", public_key);
                    $display("       EXP = %064h", expected_pk);
                    case_ok = 1'b0;
                end
                if (secret_scalar !== expected_scalar) begin
                    $display("[FAIL] Test %0d: secret_scalar", test_id);
                    $display("       GOT = %064h", secret_scalar);
                    $display("       EXP = %064h", expected_scalar);
                    case_ok = 1'b0;
                end
                if (prefix !== expected_prefix) begin
                    $display("[FAIL] Test %0d: prefix", test_id);
                    $display("       GOT = %064h", prefix);
                    $display("       EXP = %064h", expected_prefix);
                    case_ok = 1'b0;
                end
                if (busy !== 1'b0) begin
                    $display("[FAIL] Test %0d: busy must be low when done=1", test_id);
                    case_ok = 1'b0;
                end
                // done is intended to be a one-cycle pulse.
                @(posedge clk);
                #1;
                if (done !== 1'b0) begin
                    $display("[FAIL] Test %0d: done was not a 1-cycle pulse", test_id);
                    case_ok = 1'b0;
                end
            end

            if (case_ok) begin
                passed = passed + 1;
                $display("[PASS] RFC8032 test %0d: PK/scalar/prefix, cycles=%0d",
                         test_id, cycles);
            end else begin
                failed = failed + 1;
                $display("[CASE FAIL] RFC8032 test %0d", test_id);
            end
        end
    endtask

    initial begin
        rst_n  = 1'b0;
        start  = 1'b0;
        seed_be = 256'd0;
        passed = 0;
        failed = 0;
        repeat (5) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;
        repeat (3) @(posedge clk);

        // SHA-512(seed): RFC 8032 test vector 1 (empty message)
        check_case(
            1,
            256'h9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60,
            256'hd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a,
            256'h4fe94d9006f020a5a3c080d96827fffd3c010ac0f12e7a42cb33284f86837c30,
            256'h9b4f0afe280b746a778684e75442502057b7473a03f08f96f5a38e9287e01f8f
        );

        // RFC 8032 test vector 2 (one-byte message, same key expansion)
        check_case(
            2,
            256'h4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb,
            256'h3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c,
            256'h512e502eb0249a255e1c827f3b6b6c7f0a79f4ca8575a91528d58258d79ebd68,
            256'h4566848291dacaf225cc63deb348da318e2c2e17b00b8160f9ce6bfa0472911d
        );

        // RFC 8032 test vector 3 (two-byte message)
        check_case(
            3,
            256'hc5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7,
            256'hfc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025,
            256'h5ca91e9981a125131bf5c2c54e7f4dba113dc2155ba523908402d95e758b9a90,
            256'h6608c8666b9cde2325f539d7d83386fe8187c6be61d8a70c247190d64edf5f1e
        );

        $display("\n========== KEY EXPANSION SUMMARY ==========");
        $display("PASS=%0d FAIL=%0d", passed, failed);
        if (failed == 0) $display("ALL PASS");
        else             $display("SOME TESTS FAILED");
        $finish;
    end
endmodule
