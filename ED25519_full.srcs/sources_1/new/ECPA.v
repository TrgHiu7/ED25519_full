`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2026 04:05:24 PM
// Design Name: 
// Module Name: ECPA
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


module ECPA(
//    input  wire clk,
//    input  wire rst,
//    input  wire start,
    
//    output reg  done,
//    // Control signals to ALU
//    output reg [1:0] alu_op,      // 00: ADD, 01: SUB, 10: MUL
//    output reg       alu_start,
//    input  wire      alu_done,

//    // Register bank control
//    output reg [4:0] src1_sel, src2_sel,
//    output reg       we,
//    output reg [2:0] din_sel,
//    output reg [4:0] dst_sel
//);

//localparam
//    IDLE      = 5'd0,
//    LV1_ADD   = 5'd1,
//    LV1_SUB   = 5'd2,
//    LV2_ADD   = 5'd3,
//    LV2_SUB   = 5'd4,
//    LV3_MUL   = 5'd5,
//    LV4_MUL   = 5'd6,
//    LV5_MUL   = 5'd7,
//    LV5_ADD   = 5'd8,
//    LV5_SUB   = 5'd9,
//    LV6_MUL   = 5'd10,
//    LV7_MUL   = 5'd11,
//    LV8_MUL   = 5'd12,
//    LV9_ADD   = 5'd13,
//    LV9_SUB   = 5'd14,
//    MUL_X3    = 5'd15,
//    MUL_Y3    = 5'd16,
//    MUL_Z3    = 5'd17,
//    MUL_T3    = 5'd18,
//    DONE_ST   = 5'd19,
//    LOAD_X1   = 5'd20,
//    LOAD_Y1   = 5'd21,
//    LOAD_Z1   = 5'd22,
//    LOAD_T1   = 5'd23;

//reg [4:0] state;

//always @(posedge clk or posedge rst) begin

//    if(rst) begin

//        state <= IDLE;

//        done <= 0;
//        alu_op <= 0;
//        alu_start <= 0;

//        src1_sel <= 0;
//        src2_sel <= 0;
//        dst_sel  <= 0;

//        we <= 0;
//        din_sel <= 0;

//    end
//    else begin

//        done      <= 0;
//        alu_start <= 0;

//        we        <= 0;
//        din_sel   <= 3'b000;

//        case(state)

//        //--------------------------------------------------
//        IDLE:
//        begin
//            if(start)
//                state <= LOAD_X1;
//        end

//        //--------------------------------------------------
//        LOAD_X1:
//        begin
//            we      <= 1;
//            din_sel <= 3'b001;
//            dst_sel <= 0;

//            state <= LOAD_Y1;
//        end

//        LOAD_Y1:
//        begin
//            we      <= 1;
//            din_sel <= 3'b010;
//            dst_sel <= 1;

//            state <= LOAD_Z1;
//        end

//        LOAD_Z1:
//        begin
//            we      <= 1;
//            din_sel <= 3'b011;
//            dst_sel <= 2;

//            state <= LOAD_T1;
//        end

//        LOAD_T1:
//        begin
//            we      <= 1;
//            din_sel <= 3'b100;
//            dst_sel <= 14;

//            state <= LV1_ADD;
//        end

//        //--------------------------------------------------
//        LV1_ADD:
//        begin
//            alu_op    <= 2'b00;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 1;
//            src2_sel  <= 0;
//            dst_sel   <= 16;

//            if(alu_done)
//                state <= LV1_SUB;
//        end

//        LV1_SUB:
//        begin
//            alu_op    <= 2'b01;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 1;
//            src2_sel  <= 0;
//            dst_sel   <= 17;

//            if(alu_done)
//                state <= LV2_ADD;
//        end

//        LV2_ADD:
//        begin
//            alu_op    <= 2'b00;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 4;
//            src2_sel  <= 3;
//            dst_sel   <= 18;

//            if(alu_done)
//                state <= LV2_SUB;
//        end

//        LV2_SUB:
//        begin
//            alu_op    <= 2'b01;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 4;
//            src2_sel  <= 3;
//            dst_sel   <= 19;

//            if(alu_done)
//                state <= LV3_MUL;
//        end

//        LV3_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 17;
//            src2_sel  <= 19;
//            dst_sel   <= 6;

//            if(alu_done)
//                state <= LV4_MUL;
//        end

//        LV4_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 16;
//            src2_sel  <= 18;
//            dst_sel   <= 7;

//            if(alu_done)
//                state <= LV5_MUL;
//        end

//        LV5_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 14;
//            src2_sel  <= 15;
//            dst_sel   <= 20;

//            if(alu_done)
//                state <= LV5_ADD;
//        end

//        LV5_ADD:
//        begin
//            alu_op    <= 2'b00;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 7;
//            src2_sel  <= 6;
//            dst_sel   <= 13;

//            if(alu_done)
//                state <= LV5_SUB;
//        end

//        LV5_SUB:
//        begin
//            alu_op    <= 2'b01;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 7;
//            src2_sel  <= 6;
//            dst_sel   <= 10;

//            if(alu_done)
//                state <= LV6_MUL;
//        end

//        LV6_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 20;
//            src2_sel  <= 25;
//            dst_sel   <= 8;

//            if(alu_done)
//                state <= LV7_MUL;
//        end

//        LV7_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 2;
//            src2_sel  <= 5;
//            dst_sel   <= 21;

//            if(alu_done)
//                state <= LV8_MUL;
//        end

//        LV8_MUL:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 26;
//            src2_sel  <= 21;
//            dst_sel   <= 9;

//            if(alu_done)
//                state <= LV9_ADD;
//        end

//        LV9_ADD:
//        begin
//            alu_op    <= 2'b00;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 9;
//            src2_sel  <= 8;
//            dst_sel   <= 12;

//            if(alu_done)
//                state <= LV9_SUB;
//        end

//        LV9_SUB:
//        begin
//            alu_op    <= 2'b01;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 9;
//            src2_sel  <= 8;
//            dst_sel   <= 11;

//            if(alu_done)
//                state <= MUL_X3;
//        end

//        //--------------------------------------------------
//        MUL_X3:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 11;
//            src2_sel  <= 10;
//            dst_sel   <= 22;

//            if(alu_done)
//                state <= MUL_Y3;
//        end

//        MUL_Y3:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 12;
//            src2_sel  <= 13;
//            dst_sel   <= 23;

//            if(alu_done)
//                state <= MUL_Z3;
//        end

//        MUL_Z3:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 11;
//            src2_sel  <= 12;
//            dst_sel   <= 24;

//            if(alu_done)
//                state <= MUL_T3;
//        end

//        MUL_T3:
//        begin
//            alu_op    <= 2'b10;
//            alu_start <= 1;

//            we        <= 1;
//            src1_sel  <= 10;
//            src2_sel  <= 13;
//            dst_sel   <= 27;

//            if(alu_done)
//                state <= DONE_ST;
//        end

//        //--------------------------------------------------
//        DONE_ST:
//        begin
//            done <= 1;

//            if(!start)
//                state <= IDLE;
//        end

//        //--------------------------------------------------
//        default:
//            state <= IDLE;

//        endcase
//    end
//end

//endmodule
    input wire clk, rst, start,
    output reg done,
    output reg [1:0] alu_op,
    output reg alu_start,
    input wire alu_done,
    output reg [4:0] src1_sel, src2_sel,
    output reg we,
    output reg [2:0] din_sel,
    output reg [4:0] dst_sel
);
    localparam [2:0] IDLE=3'd0, LOAD_X=3'd1, LOAD_Y=3'd2,
                     LOAD_Z=3'd3, LOAD_T=3'd4, ISSUE=3'd5,
                     WAIT_ALU=3'd6, COMMIT=3'd7;
    reg [2:0] state;
    reg [4:0] step;
    // All register-bank/ALU control signals are combinational from state.
    // They are sampled by the bank/ALU at the next rising clock edge.
    always @(*) begin
        alu_op=2'b00;
        alu_start=1'b0;
        src1_sel=5'd0; src2_sel=5'd0; dst_sel=5'd0;
        we=1'b0; din_sel=3'b000;
        case (step)
            5'd0: begin alu_op=2'b00; src1_sel=5'd1; src2_sel=5'd0; dst_sel=5'd16; end
            5'd1: begin alu_op=2'b01; src1_sel=5'd1; src2_sel=5'd0; dst_sel=5'd17; end
            5'd2: begin alu_op=2'b00; src1_sel=5'd4; src2_sel=5'd3; dst_sel=5'd18; end
            5'd3: begin alu_op=2'b01; src1_sel=5'd4; src2_sel=5'd3; dst_sel=5'd19; end
            5'd4: begin alu_op=2'b10; src1_sel=5'd17; src2_sel=5'd19; dst_sel=5'd6; end
            5'd5: begin alu_op=2'b10; src1_sel=5'd16; src2_sel=5'd18; dst_sel=5'd7; end
            5'd6: begin alu_op=2'b10; src1_sel=5'd14; src2_sel=5'd15; dst_sel=5'd20; end
            5'd7: begin alu_op=2'b00; src1_sel=5'd7; src2_sel=5'd6; dst_sel=5'd13; end
            5'd8: begin alu_op=2'b01; src1_sel=5'd7; src2_sel=5'd6; dst_sel=5'd10; end
            5'd9: begin alu_op=2'b10; src1_sel=5'd20; src2_sel=5'd25; dst_sel=5'd8; end
            5'd10: begin alu_op=2'b10; src1_sel=5'd2; src2_sel=5'd5; dst_sel=5'd21; end
            5'd11: begin alu_op=2'b10; src1_sel=5'd26; src2_sel=5'd21; dst_sel=5'd9; end
            5'd12: begin alu_op=2'b00; src1_sel=5'd9; src2_sel=5'd8; dst_sel=5'd12; end
            5'd13: begin alu_op=2'b01; src1_sel=5'd9; src2_sel=5'd8; dst_sel=5'd11; end
            5'd14: begin alu_op=2'b10; src1_sel=5'd11; src2_sel=5'd10; dst_sel=5'd22; end
            5'd15: begin alu_op=2'b10; src1_sel=5'd12; src2_sel=5'd13; dst_sel=5'd23; end
            5'd16: begin alu_op=2'b10; src1_sel=5'd11; src2_sel=5'd12; dst_sel=5'd24; end
            5'd17: begin alu_op=2'b10; src1_sel=5'd10; src2_sel=5'd13; dst_sel=5'd27; end
            default: begin alu_op=2'b00; src1_sel=0; src2_sel=0; dst_sel=0; end
        endcase
        case (state)
            LOAD_X: begin we=1'b1; din_sel=3'd1; dst_sel=5'd0; end
            LOAD_Y: begin we=1'b1; din_sel=3'd2; dst_sel=5'd1; end
            LOAD_Z: begin we=1'b1; din_sel=3'd3; dst_sel=5'd2; end
            LOAD_T: begin we=1'b1; din_sel=3'd4; dst_sel=5'd14; end
            ISSUE: alu_start=1'b1;
            COMMIT: begin we=1'b1; din_sel=3'd0; end
            default: begin end
        endcase
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state<=IDLE; step<=0; done<=0;
        end else begin
            done<=1'b0;
            case (state)
                IDLE: if (start) begin step<=0; state<=LOAD_X; end
                LOAD_X: state<=LOAD_Y;
                LOAD_Y: state<=LOAD_Z;
                LOAD_Z: state<=LOAD_T;
                LOAD_T: state<=ISSUE;
                ISSUE: state<=WAIT_ALU;
                WAIT_ALU: if (alu_done) state<=COMMIT;
                COMMIT: begin
                    if (step==5'd17) begin
                        state<=IDLE;
                        done<=1'b1;
                    end else begin
                        step<=step+1'b1;
                        state<=ISSUE;
                    end
                end
                default: state<=IDLE;
            endcase
        end
    end
endmodule
