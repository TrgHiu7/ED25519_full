`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 04:49:41 PM
// Design Name: 
// Module Name: invert
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


module invert(
input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [255:0] a,
    output wire [255:0] result,
    output reg          done
);
    localparam 
        IDLE              = 6'd0,
        CALC_A2_START     = 6'd1,  CALC_A2_WAIT      = 6'd2,
        CALC_A4_START     = 6'd3,  CALC_A4_WAIT      = 6'd4,
        CALC_A8_START     = 6'd5,  CALC_A8_WAIT      = 6'd6,
        CALC_A9_START     = 6'd7,  CALC_A9_WAIT      = 6'd8,
        CALC_A11_START    = 6'd9,  CALC_A11_WAIT     = 6'd10,
        CALC_A22_START    = 6'd11, CALC_A22_WAIT     = 6'd12,
        CALC_2_5_1_START  = 6'd13, CALC_2_5_1_WAIT   = 6'd14,
        CALC_2_10_1_START = 6'd15, CALC_2_10_1_WAIT  = 6'd16,
        CALC_2_20_1_START = 6'd17, CALC_2_20_1_WAIT  = 6'd18,
        CALC_2_40_1_START = 6'd19, CALC_2_40_1_WAIT  = 6'd20,
        CALC_2_50_1_START = 6'd21, CALC_2_50_1_WAIT  = 6'd22,
        CALC_2_100_1_START= 6'd23, CALC_2_100_1_WAIT = 6'd24,
        CALC_2_200_1_START= 6'd25, CALC_2_200_1_WAIT = 6'd26,
        CALC_2_250_1_START= 6'd27, CALC_2_250_1_WAIT = 6'd28,
        INV_A_START       = 6'd29, INV_A_WAIT        = 6'd30,
        DONE_ST           = 6'd31;

    reg [5:0]   state;
    reg [255:0] op_a, op_b;
    reg         mul_start;
    wire [255:0] mul_result;
    wire        mul_done;

    modulo_mul multiplier (
        .clk(clk),
        .rst_n(rst_n),
        .start(mul_start),
        .X_in(op_a),
        .Y(op_b),
        .R(mul_result),
        .done(mul_done)
    );

    reg [255:0] r_a2, r_a4, r_a8, r_a9, r_a11, r_a22;
    reg [255:0] r_a2_5_1, r_a2_10_1, r_a2_20_1, r_a2_40_1;
    reg [255:0] r_a2_50_1, r_a2_100_1, r_a2_200_1, r_a2_250_1;
    reg [255:0] r_t;
    reg [6:0]   counter;
    reg [255:0] result_reg;

    assign result = result_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            state      <= IDLE;
            mul_start  <= 1'b0;
            done       <= 1'b0;
            op_a       <= 256'd0; op_b <= 256'd0;
            r_a2       <= 256'd0; r_a4 <= 256'd0; r_a8 <= 256'd0;
            r_a9       <= 256'd0; r_a11 <= 256'd0; r_a22 <= 256'd0;
            r_a2_5_1   <= 256'd0; r_a2_10_1 <= 256'd0; r_a2_20_1 <= 256'd0;
            r_a2_40_1  <= 256'd0; r_a2_50_1 <= 256'd0; r_a2_100_1 <= 256'd0;
            r_a2_200_1 <= 256'd0; r_a2_250_1 <= 256'd0; r_t <= 256'd0;
            counter    <= 7'd0;
            result_reg <= 256'd0;
        end else begin
            mul_start <= 1'b0;
            done      <= 1'b0;

            case (state)
                IDLE: begin
                    counter <= 7'd0;
                    if (start) state <= CALC_A2_START;
                end

                CALC_A2_START: begin mul_start <= 1'b1; op_a <= a; op_b <= a; state <= CALC_A2_WAIT; end
                CALC_A2_WAIT:  begin if (mul_done) begin r_a2 <= mul_result; state <= CALC_A4_START; end end

                CALC_A4_START: begin mul_start <= 1'b1; op_a <= r_a2; op_b <= r_a2; state <= CALC_A4_WAIT; end
                CALC_A4_WAIT:  begin if (mul_done) begin r_a4 <= mul_result; state <= CALC_A8_START; end end

                CALC_A8_START: begin mul_start <= 1'b1; op_a <= r_a4; op_b <= r_a4; state <= CALC_A8_WAIT; end
                CALC_A8_WAIT:  begin if (mul_done) begin r_a8 <= mul_result; state <= CALC_A9_START; end end

                CALC_A9_START: begin mul_start <= 1'b1; op_a <= r_a8; op_b <= a; state <= CALC_A9_WAIT; end
                CALC_A9_WAIT:  begin if (mul_done) begin r_a9 <= mul_result; state <= CALC_A11_START; end end

                CALC_A11_START: begin mul_start <= 1'b1; op_a <= r_a9; op_b <= r_a2; state <= CALC_A11_WAIT; end
                CALC_A11_WAIT:  begin if (mul_done) begin r_a11 <= mul_result; state <= CALC_A22_START; end end

                CALC_A22_START: begin mul_start <= 1'b1; op_a <= r_a11; op_b <= r_a11; state <= CALC_A22_WAIT; end
                CALC_A22_WAIT:  begin if (mul_done) begin r_a22 <= mul_result; state <= CALC_2_5_1_START; end end

                CALC_2_5_1_START: begin mul_start <= 1'b1; op_a <= r_a22; op_b <= r_a9; state <= CALC_2_5_1_WAIT; end
                CALC_2_5_1_WAIT:  begin 
                    if (mul_done) begin 
                        r_t <= mul_result; r_a2_5_1 <= mul_result; counter <= 7'd0; 
                        state <= CALC_2_10_1_START; 
                    end 
                end

                CALC_2_10_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 5) ? r_t : r_a2_5_1; 
                    state <= CALC_2_10_1_WAIT; 
                end
                CALC_2_10_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 5) begin counter <= counter + 1'b1; state <= CALC_2_10_1_START; end 
                        else             begin r_a2_10_1 <= mul_result; counter <= 7'd0; state <= CALC_2_20_1_START; end 
                    end 
                end

                CALC_2_20_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 10) ? r_t : r_a2_10_1; 
                    state <= CALC_2_20_1_WAIT; 
                end
                CALC_2_20_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 10) begin counter <= counter + 1'b1; state <= CALC_2_20_1_START; end 
                        else              begin r_a2_20_1 <= mul_result; counter <= 7'd0; state <= CALC_2_40_1_START; end 
                    end 
                end

                CALC_2_40_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 20) ? r_t : r_a2_20_1; 
                    state <= CALC_2_40_1_WAIT; 
                end
                CALC_2_40_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 20) begin counter <= counter + 1'b1; state <= CALC_2_40_1_START; end 
                        else              begin r_a2_40_1 <= mul_result; counter <= 7'd0; state <= CALC_2_50_1_START; end 
                    end 
                end

                CALC_2_50_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 10) ? r_t : r_a2_10_1; 
                    state <= CALC_2_50_1_WAIT; 
                end
                CALC_2_50_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 10) begin counter <= counter + 1'b1; state <= CALC_2_50_1_START; end 
                        else              begin r_a2_50_1 <= mul_result; counter <= 7'd0; state <= CALC_2_100_1_START; end 
                    end 
                end

                CALC_2_100_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 50) ? r_t : r_a2_50_1; 
                    state <= CALC_2_100_1_WAIT; 
                end
                CALC_2_100_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 50) begin counter <= counter + 1'b1; state <= CALC_2_100_1_START; end 
                        else              begin r_a2_100_1 <= mul_result; counter <= 7'd0; state <= CALC_2_200_1_START; end 
                    end 
                end

                CALC_2_200_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 100) ? r_t : r_a2_100_1; 
                    state <= CALC_2_200_1_WAIT; 
                end
                CALC_2_200_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 100) begin counter <= counter + 1'b1; state <= CALC_2_200_1_START; end 
                        else               begin r_a2_200_1 <= mul_result; counter <= 7'd0; state <= CALC_2_250_1_START; end 
                    end 
                end

                CALC_2_250_1_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 50) ? r_t : r_a2_50_1; 
                    state <= CALC_2_250_1_WAIT; 
                end
                CALC_2_250_1_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 50) begin counter <= counter + 1'b1; state <= CALC_2_250_1_START; end 
                        else              begin r_a2_250_1 <= mul_result; counter <= 7'd0; state <= INV_A_START; end 
                    end 
                end

                INV_A_START: begin 
                    mul_start <= 1'b1; op_a <= r_t; op_b <= (counter < 5) ? r_t : r_a11; 
                    state <= INV_A_WAIT; 
                end
                INV_A_WAIT: begin 
                    if (mul_done) begin 
                        r_t <= mul_result; 
                        if (counter < 5) begin counter <= counter + 1'b1; state <= INV_A_START; end 
                        else             begin result_reg <= mul_result; state <= DONE_ST; end 
                    end 
                end

                DONE_ST: begin 
                    done  <= 1'b1; 
                    state <= IDLE; 
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule