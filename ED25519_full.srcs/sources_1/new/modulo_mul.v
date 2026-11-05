`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2026 10:34:21 AM
// Design Name: 
// Module Name: modulo_mul
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

module modulo_mul (
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [255:0] X_in,
    input  wire [255:0] Y,
    output reg  [255:0] R,
    output reg          done
);
    localparam [255:0] P =
        256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    localparam [259:0] P_EXT = {4'b0000, P};

    localparam [4:0]
        ST_IDLE       = 5'd0,
        ST_TAB_ADD0   = 5'd1,
        ST_TAB_ADD1   = 5'd2,
        ST_TAB_ADD2   = 5'd3,
        ST_TAB_ADD3   = 5'd4,
        ST_TAB_SUB0   = 5'd5,
        ST_TAB_SUB1   = 5'd6,
        ST_TAB_SUB2   = 5'd7,
        ST_TAB_SUB3   = 5'd8,
        ST_CSA1       = 5'd9,
        ST_CSA2       = 5'd10,
        ST_UPDATE_N   = 5'd11,
        ST_ADD0       = 5'd12,
        ST_ADD1       = 5'd13,
        ST_ADD2       = 5'd14,
        ST_ADD3       = 5'd15,
        ST_FOLD0      = 5'd16,
        ST_FOLD1      = 5'd17,
        ST_FOLD2      = 5'd18,
        ST_FOLD3      = 5'd19,
        ST_SUB0       = 5'd20,
        ST_SUB1       = 5'd21,
        ST_SUB2       = 5'd22,
        ST_SUB3       = 5'd23,
        ST_OUTPUT     = 5'd24;

    reg [4:0]   state;
    reg [6:0]   counter;
    reg [254:0] X_shift;
    reg [255:0] Y_reg;
    reg [2:0]   tab_index;

    // LUT2, initialized after start (only entries 0 and 1 are immediate).
    // Six modular additions form entries 2..7 before the main loop begins.
    reg [255:0] LUT2 [0:7];

    // Algorithm registers; carry-save numbers are never added during a digit.
    reg [258:0] S, C, N;
    reg [258:0] S2, C2;

    // The one shared, segmented carry-propagate adder.
    reg  [64:0] alu_a, alu_b;
    reg         alu_cin;
    wire [65:0] alu_sum = {1'b0, alu_a} + {1'b0, alu_b} + alu_cin;
    reg         carry_bit;
    reg         no_borrow;

    // Temporary registers reused during LUT2 construction / final reduction.
    reg [259:0] tab_sum;
    reg [259:0] tab_diff;
    reg [259:0] final_sum;
    reg [259:0] fold_reg;
    reg [259:0] diff_reg;

    // ------------------------------------------------------------------------
    // LUT1: input is the SUM OF THE TWO HIGH PARTS, not (S+C)[258:255].
    // Full 5-bit index avoids accidental truncation in 4-bit arithmetic.
    // Since LUT1[k] = 152*k = 128*k + 16*k + 8*k, no wide multiplier.
    // ------------------------------------------------------------------------
    wire [4:0] index_n = {1'b0, S[258:255]} + {1'b0, C[258:255]};
    wire [12:0] lut1_small =
        ({8'b0, index_n} << 7) +
        ({8'b0, index_n} << 4) +
        ({8'b0, index_n} << 3);

    // ------------------------------------------------------------------------
    // Radix-8 digit of the 255-bit X. LUT2[d] is already reduced mod p.
    // ------------------------------------------------------------------------
    wire [2:0] digit = X_shift[254:252];
    wire [258:0] M  = {3'b000, LUT2[digit]};
    wire [258:0] S1 = {1'b0, S[254:0], 3'b000};
    wire [258:0] C1 = {1'b0, C[254:0], 3'b000};

    wire [258:0] csa1_s = S1 ^ C1 ^ M;
    wire [258:0] csa1_c =
        ((S1 & C1) | (S1 & M) | (C1 & M)) << 1;
    wire [258:0] csa2_s = S2 ^ C2 ^ N;
    wire [258:0] csa2_c =
        ((S2 & C2) | (S2 & N) | (C2 & N)) << 1;

    // LUT2 construction: lut2[k] = (lut2[k-1] + Y_reg) mod p.
    // Both terms are < p, so the sum is < 2p and subtracting p once suffices.
    wire [259:0] table_prev = {4'b0, LUT2[tab_index - 3'd1]};
    wire [259:0] y_ext = {4'b0, Y_reg};

    // At the end: A = S+C, fold A to A_low + 19*A_high.
    wire [259:0] s_ext = {1'b0, S};
    wire [259:0] c_ext = {1'b0, C};
    wire [4:0] final_hi = final_sum[259:255];
    wire [10:0] fold_small =
        ({6'b0, final_hi} << 4) +
        ({6'b0, final_hi} << 1) +
         {6'b0, final_hi};

    // ------------------------------------------------------------------------
    // 65-bit ALU operand selection; no latches inferred (defaults provided).
    // ------------------------------------------------------------------------
    always @(*) begin
        alu_a   = 65'd0;
        alu_b   = 65'd0;
        alu_cin = 1'b0;
        case (state)
            ST_TAB_ADD0: begin
                alu_a = table_prev[64:0];
                alu_b = y_ext[64:0];
            end
            ST_TAB_ADD1: begin
                alu_a = table_prev[129:65];
                alu_b = y_ext[129:65];
                alu_cin = carry_bit;
            end
            ST_TAB_ADD2: begin
                alu_a = table_prev[194:130];
                alu_b = y_ext[194:130];
                alu_cin = carry_bit;
            end
            ST_TAB_ADD3: begin
                alu_a = table_prev[259:195];
                alu_b = y_ext[259:195];
                alu_cin = carry_bit;
            end
            ST_TAB_SUB0: begin
                alu_a = tab_sum[64:0];
                alu_b = ~P_EXT[64:0];
                alu_cin = 1'b1;
            end
            ST_TAB_SUB1: begin
                alu_a = tab_sum[129:65];
                alu_b = ~P_EXT[129:65];
                alu_cin = carry_bit;
            end
            ST_TAB_SUB2: begin
                alu_a = tab_sum[194:130];
                alu_b = ~P_EXT[194:130];
                alu_cin = carry_bit;
            end
            ST_TAB_SUB3: begin
                alu_a = tab_sum[259:195];
                alu_b = ~P_EXT[259:195];
                alu_cin = carry_bit;
            end
            ST_ADD0: begin
                alu_a = s_ext[64:0];
                alu_b = c_ext[64:0];
            end
            ST_ADD1: begin
                alu_a = s_ext[129:65];
                alu_b = c_ext[129:65];
                alu_cin = carry_bit;
            end
            ST_ADD2: begin
                alu_a = s_ext[194:130];
                alu_b = c_ext[194:130];
                alu_cin = carry_bit;
            end
            ST_ADD3: begin
                alu_a = s_ext[259:195];
                alu_b = c_ext[259:195];
                alu_cin = carry_bit;
            end
            ST_FOLD0: begin
                alu_a = final_sum[64:0];
                alu_b = {54'b0, fold_small};
            end
            ST_FOLD1: begin
                alu_a = final_sum[129:65];
                alu_cin = carry_bit;
            end
            ST_FOLD2: begin
                alu_a = final_sum[194:130];
                alu_cin = carry_bit;
            end
            ST_FOLD3: begin
                alu_a = {5'b0, final_sum[254:195]};
                alu_cin = carry_bit;
            end
            ST_SUB0: begin
                alu_a = fold_reg[64:0];
                alu_b = ~P_EXT[64:0];
                alu_cin = 1'b1;
            end
            ST_SUB1: begin
                alu_a = fold_reg[129:65];
                alu_b = ~P_EXT[129:65];
                alu_cin = carry_bit;
            end
            ST_SUB2: begin
                alu_a = fold_reg[194:130];
                alu_b = ~P_EXT[194:130];
                alu_cin = carry_bit;
            end
            ST_SUB3: begin
                alu_a = fold_reg[259:195];
                alu_b = ~P_EXT[259:195];
                alu_cin = carry_bit;
            end
            default: begin end
        endcase
    end

    // ------------------------------------------------------------------------
    // FSM: synchronous active-high reset, done pulse for one cycle.
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state      <= ST_IDLE;
            done       <= 1'b0;
            R          <= 256'd0;
            counter    <= 7'd0;
            X_shift    <= 255'd0;
            Y_reg      <= 256'd0;
            tab_index  <= 3'd0;
            S          <= 259'd0;
            C          <= 259'd0;
            N          <= 259'd0;
            S2         <= 259'd0;
            C2         <= 259'd0;
            carry_bit  <= 1'b0;
            no_borrow  <= 1'b0;
            tab_sum    <= 260'd0;
            tab_diff   <= 260'd0;
            final_sum  <= 260'd0;
            fold_reg   <= 260'd0;
            diff_reg   <= 260'd0;
            // LUT2[2..7] intentionally not reset: overwritten before use.
            LUT2[0] <= 256'd0;
            LUT2[1] <= 256'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        X_shift   <= X_in[254:0];
                        Y_reg     <= Y;
                        counter   <= 7'd85;
                        tab_index <= 3'd2;
                        S         <= 259'd0;
                        C         <= 259'd0;
                        N         <= 259'd0;
                        LUT2[0]   <= 256'd0;
                        LUT2[1]   <= Y;
                        state     <= ST_TAB_ADD0;
                    end
                end

                // Precompute LUT2[2..7] with the shared 65-bit adder.
                ST_TAB_ADD0: begin
                    tab_sum[64:0] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_ADD1;
                end
                ST_TAB_ADD1: begin
                    tab_sum[129:65] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_ADD2;
                end
                ST_TAB_ADD2: begin
                    tab_sum[194:130] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_ADD3;
                end
                ST_TAB_ADD3: begin
                    tab_sum[259:195] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_SUB0;
                end
                ST_TAB_SUB0: begin
                    tab_diff[64:0] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_SUB1;
                end
                ST_TAB_SUB1: begin
                    tab_diff[129:65] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_SUB2;
                end
                ST_TAB_SUB2: begin
                    tab_diff[194:130] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_TAB_SUB3;
                end
                ST_TAB_SUB3: begin
                    // The last chunk of the difference is taken directly
                    // from alu_sum, avoiding a ninth LUT initialization cycle.
                    if (alu_sum[65])
                        LUT2[tab_index] <= {alu_sum[60:0], tab_diff[194:0]};
                    else
                        LUT2[tab_index] <= tab_sum[255:0];
                    if (tab_index == 3'd7) begin
                        state <= ST_CSA1;
                    end else begin
                        tab_index <= tab_index + 1'b1;
                        state <= ST_TAB_ADD0;
                    end
                end

                // Paper step 10..13: independent low bits of S and C, CSA1.
                ST_CSA1: begin
                    S2 <= csa1_s;
                    C2 <= csa1_c;
                    X_shift <= X_shift << 3;
                    state <= ST_CSA2;
                end
                // Paper step 14..15: second CSA adds delayed correction N.
                ST_CSA2: begin
                    S <= csa2_s;
                    C <= csa2_c;
                    state <= ST_UPDATE_N;
                end
                // Paper step 16: correction corresponding to the NEW S and C.
                // It will be used as N in the NEXT iteration.
                ST_UPDATE_N: begin
                    N <= {{246{1'b0}}, lut1_small};
                    if (counter == 7'd1) begin
                        state <= ST_ADD0;
                    end else begin
                        counter <= counter - 1'b1;
                        state <= ST_CSA1;
                    end
                end

                // Final result is (S+C) mod p; add in four 65-bit chunks.
                ST_ADD0: begin
                    final_sum[64:0] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_ADD1;
                end
                ST_ADD1: begin
                    final_sum[129:65] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_ADD2;
                end
                ST_ADD2: begin
                    final_sum[194:130] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_ADD3;
                end
                ST_ADD3: begin
                    final_sum[259:195] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_FOLD0;
                end

                // Folding: 2^255 = 19 (mod p), no 255-bit CPA in one cycle.
                ST_FOLD0: begin
                    fold_reg[64:0] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_FOLD1;
                end
                ST_FOLD1: begin
                    fold_reg[129:65] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_FOLD2;
                end
                ST_FOLD2: begin
                    fold_reg[194:130] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_FOLD3;
                end
                ST_FOLD3: begin
                    fold_reg[259:195] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_SUB0;
                end

                // Conditional subtraction of p using the same segmented ALU.
                ST_SUB0: begin
                    diff_reg[64:0] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_SUB1;
                end
                ST_SUB1: begin
                    diff_reg[129:65] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_SUB2;
                end
                ST_SUB2: begin
                    diff_reg[194:130] <= alu_sum[64:0];
                    carry_bit <= alu_sum[65];
                    state <= ST_SUB3;
                end
                ST_SUB3: begin
                    diff_reg[259:195] <= alu_sum[64:0];
                    no_borrow <= alu_sum[65];
                    state <= ST_OUTPUT;
                end
                ST_OUTPUT: begin
                    R <= no_borrow ? diff_reg[255:0] : fold_reg[255:0];
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule