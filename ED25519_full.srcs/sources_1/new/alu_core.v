`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2026 08:12:09 AM
// Design Name: 
// Module Name: alu_core
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


module alu_core (
    input  wire              clk,
    input  wire              rst,
    input  wire              start,
    
    input  wire [1:0]        op,       // 00: ADD, 01: SUB, 10: MUL
    input  wire [255:0]      a,
    input  wire [255:0]      b,
    
    output reg  [255:0]      result,
    output reg               done
);
    localparam [255:0] P = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    reg             start_add, start_sub, start_mul;
    wire [255:0]    result_add, result_sub, result_mul;
    wire            done_add, done_sub, done_mul;
    
    localparam S_IDLE = 2'd0, S_LAUNCH = 2'd1,
               S_WAIT = 2'd2, S_FINISH = 2'd3;

    reg [1:0] state;
    reg [1:0] op_reg;
    reg [255:0] a_reg, b_reg;
    wire selected_done = (op_reg == 2'd0) ? done_add :
                         (op_reg == 2'd1) ? done_sub : done_mul;
    wire [255:0] selected_value = (op_reg == 2'd0) ? result_add :
                                  (op_reg == 2'd1) ? result_sub : result_mul;
    
    modulo_add  mod_add (
        .clk(clk),
        .rst(rst),
        .start(start_add),
        .A(a_reg),
        .B(b_reg),
        .result(result_add),
        .done(done_add)
    );

    modulo_sub  mod_sub (
        .clk(clk),
        .rst(rst),
        .start(start_sub),
        .A(a_reg),
        .B(b_reg),
        .result(result_sub),
        .done(done_sub)
    );

    modulo_mul mod_mul (
        .clk(clk),
        .rst(rst),
        .start(start_mul),
        .X_in(a_reg),
        .Y(b_reg),
        .R(result_mul),
        .done(done_mul)
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            result <= 256'd0;
            done <= 1'b0;
            op_reg <= 2'd0;
            a_reg <= 256'd0;
            b_reg <= 256'd0;
            start_add <= 1'b0;
            start_sub <= 1'b0;
            start_mul <= 1'b0;
        end else begin
            done <= 1'b0;
            start_add <= 1'b0;
            start_sub <= 1'b0;
            start_mul <= 1'b0;
            case (state)
                S_IDLE: if (start) begin
                    op_reg <= op;
                    a_reg <= a;
                    b_reg <= b;
                    state <= S_LAUNCH;
                end
                S_LAUNCH: begin
                    case (op_reg)
                        2'd0: start_add <= 1'b1;
                        2'd1: start_sub <= 1'b1;
                        2'd2: start_mul <= 1'b1;
                        default: start_add <= 1'b1;
                    endcase
                    state <= S_WAIT;
                end
                S_WAIT: if (selected_done) begin
                    result <= selected_value;
                    done <= 1'b1;
                    state <= S_FINISH;
                end
                S_FINISH: state <= S_IDLE;
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
