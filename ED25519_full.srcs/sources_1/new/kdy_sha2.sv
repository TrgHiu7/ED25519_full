/*******************************************************************************
 *    Copyright (C) 2026 by Doan Duc Duy
 *    All right reserved.
 *
 *    Copyright Notification
 *    No part may be reproduced except as authorized by written permission.
 *
 *    File Name   : kdy_sha2.svh
 *    Company     : Academy of Cryptography Techniques
 *    Project     : kdy_ed25519_accelerator
 *    Author      : ducduy
 *    Module/Class: kdy_sha2
 *    Create Date : Sept 17th 2026
 *    Last Update : Sept 17th 2026
 *    Description : SHA2-512 
 ******************************************************************************
  History:

 ******************************************************************************/

 `include "kdy_ed25519_header.svh"
 import kdy_sha_512 ::*;
 

 module kdy_sha2 (
     input                                clk,    
     input                                rst_n,  
     input                                start,
     input        [`PRIVATE_KEY - 1 : 0]  data_i,
     output logic [`HASH_WIDTH  - 1 : 0]  hash_o,
     output logic                         done
 );

    // Control signals
    logic [6 : 0] idx_sgma ;
    logic [6 : 0] idx_sche ;
    logic [6 : 0] idx_cmpr ;
    // logic         en;


    // Data signals
    logic [`MSG_WIDTH - 1 : 0] sml_sgma_1_p0, sml_sgma_1_p1;
    logic [`MSG_WIDTH - 1 : 0] sml_sgma_0_p0, sml_sgma_0_p1;
    logic [`MSG_WIDTH - 1 : 0] big_sgma_0, big_sgma_1;
    logic [`MSG_WIDTH - 1 : 0] choice, major;
    logic [`MSG_WIDTH - 1 : 0] T1, T2;

    logic [`MSG_WIDTH - 1 : 0] w [`SCHE_DEPTH];
    logic [`MSG_BLOCK - 1 : 0] msg_blk;
    logic [`MSG_WIDTH - 1 : 0] a,b,c,d,e,f,g,h;
    logic [`MSG_WIDTH - 1 : 0] h0,h1,h2,h3,h4,h5,h6,h7;


    // FSM signals
    typedef enum logic [2 : 0] {
        ST_IDLE,
        ST_DATA,
        ST_SCHE,
        ST_COMP,
        ST_TEMP,
        ST_UPDT
    }state_t;

    state_t curr_state, nxt_state;



    /**
     *  Determine message block (1024 bit)
     *  Assign message block for 16 register in message schedule (64 bit registers)
     *  */
    assign msg_blk = { data_i, 1'b1, 639'd0, 128'd256 };



    /**
     *  current state block
     *  */
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            curr_state <= ST_IDLE;
        end else begin
            curr_state <= nxt_state;
        end
    end



    /**
     *  next state block
     *  */
    always_comb begin
        nxt_state = curr_state;
        case (curr_state)
            ST_IDLE : if(start)             nxt_state = ST_DATA;
            ST_DATA :                       nxt_state = ST_SCHE;
            ST_SCHE : begin 
                if(idx_sche == 78)    
                    nxt_state = ST_COMP;
                else
                    nxt_state = ST_DATA;
            end
            ST_COMP :                       nxt_state = ST_TEMP;
            ST_TEMP :                       nxt_state = ST_UPDT;
            ST_UPDT : begin
                if(idx_cmpr == 79)
                    nxt_state = ST_IDLE;
                else
                    nxt_state = ST_COMP;
            end
            default :  nxt_state = ST_IDLE;
        endcase
    end



    /**
     *  Non-Blocking Assign
     *  */
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            idx_sgma <= 7'h1;
            idx_sche <= 7'd16;
            idx_cmpr <= 7'h0;
            a        <= `H0;
            b        <= `H1;
            c        <= `H2;
            d        <= `H3;
            e        <= `H4;
            f        <= `H5;
            g        <= `H6;
            h        <= `H7;
            // h0       <= '0;
            // h1       <= '0;
            // h2       <= '0;
            // h3       <= '0;
            // h4       <= '0;
            // h5       <= '0;
            // h6       <= '0;
            // h7       <= '0;
            sml_sgma_1_p0 <= '0;
            sml_sgma_0_p0 <= '0;
            sml_sgma_1_p1 <= '0;
            sml_sgma_0_p1 <= '0;
            choice        <= '0;
            major         <= '0;
            big_sgma_0    <= '0;
            big_sgma_1    <= '0;
            T1            <= '0;
            T2            <= '0;
            // done          <= 1'b0;
        end
        else begin
            case (curr_state)
                ST_IDLE : begin
                    idx_cmpr <= '0;
                    if(idx_cmpr == 0) begin
                        done <= 1'b0;
                    end
                    a        <= `H0;
                    b        <= `H1;
                    c        <= `H2;
                    d        <= `H3;
                    e        <= `H4;
                    f        <= `H5;
                    g        <= `H6;
                    h        <= `H7;
                    sml_sgma_1_p0 <= '0;
                    sml_sgma_0_p0 <= '0;
                    sml_sgma_1_p1 <= '0;
                    sml_sgma_0_p1 <= '0;
                    choice        <= '0;
                    major         <= '0;
                    big_sgma_0    <= '0;
                    big_sgma_1    <= '0;
                    T1            <= '0;
                    T2            <= '0;
                    done          <= 1'b0;
                    done     <= 1'b0;
                    if(start) begin
                        for(int i = 0; i < 16; i++) begin
                            w[i] <= msg_blk[(`MSG_BLOCK - 1 ) - (64*i) -: 64 ];
                        end
                    end
                end
                ST_DATA : begin    
                    sml_sgma_0_p0 <= {w[idx_sgma][0], w[idx_sgma][63 : 1]} ^ {w[idx_sgma][7 : 0], w[idx_sgma][63 : 8]} ^ (w[idx_sgma] >> 7);
                    sml_sgma_1_p0 <= {w[idx_sgma + 13][18 : 0], w[idx_sgma + 13][63 : 19]} ^ {w[idx_sgma + 13][60 : 0], w[idx_sgma + 13][63 : 61]} ^ (w[idx_sgma + 13] >> 6);
                    sml_sgma_0_p1 <= {w[idx_sgma + 1][0], w[idx_sgma + 1][63 : 1]} ^ {w[idx_sgma + 1][7 : 0], w[idx_sgma + 1][63 : 8]} ^ (w[idx_sgma + 1] >> 7);
                    sml_sgma_1_p1 <= {w[idx_sgma + 14][18 : 0], w[idx_sgma + 14][63 : 19]} ^ {w[idx_sgma + 14][60 : 0], w[idx_sgma + 14][63 : 61]} ^ (w[idx_sgma + 14] >> 6);
                end

                ST_SCHE : begin
                    w[idx_sche]      <= (w[idx_sgma - 1] + w[idx_sgma + 8]) + (sml_sgma_0_p0 + sml_sgma_1_p0);
                    w[idx_sche + 1 ] <= (w[idx_sgma] + w[idx_sgma + 9]) + (sml_sgma_0_p1 + sml_sgma_1_p1);
                    if(idx_sche != 78) begin
                        idx_sgma <= idx_sgma + 2;
                        idx_sche <= idx_sche + 2;
                    end
                    else begin
                        idx_sgma <= 7'h1;
                        idx_sche <= 7'd16;
                    end
                end

                ST_COMP : begin
                    big_sgma_0 <= {a[27 : 0],a[63 : 28]} ^ {a[33 : 0],a[63 : 34]} ^ {a[38 : 0],a[63 : 39]};
                    big_sgma_1 <= {e[13 : 0],e[63 : 14]} ^ {e[17 : 0],e[63 : 18]} ^ {e[40 : 0],e[63 : 41]};
                    choice     <= (e & f) ^ ((~e) & g);
                    major      <= (a & b) ^ (a & c) ^ (b & c);
                end

                ST_TEMP : begin
                    T1 <= (h + big_sgma_1) + (choice + K[idx_cmpr]) + w[idx_cmpr];
                    T2 <= big_sgma_0 + major;
                end

                ST_UPDT : begin
                    a           <= T1 + T2;
                    b           <= a;
                    c           <= b;
                    d           <= c;
                    e           <= d + T1;
                    f           <= e;
                    g           <= f;
                    h           <= g;
                    if(idx_cmpr == 79) begin
                        // h0   <= `H0 + a;
                        // h1   <= `H1 + b;
                        // h2   <= `H2 + c;
                        // h3   <= `H3 + d;
                        // h4   <= `H4 + e;
                        // h5   <= `H5 + f;
                        // h6   <= `H6 + g;
                        // h7   <= `H7 + h;
                        // done <= 1'b1;
                    end
                    else begin
                        idx_cmpr    <= idx_cmpr + 1;
                    end
                end
                default : begin
                    idx_sgma <= 7'h1;
                    idx_sche <= 7'd16;
                    idx_cmpr <= 7'h0;
                    a        <= `H0;
                    b        <= `H1;
                    c        <= `H2;
                    d        <= `H3;
                    e        <= `H4;
                    f        <= `H5;
                    g        <= `H6;
                    h        <= `H7;
                    // h0       <= '0;
                    // h1       <= '0;
                    // h2       <= '0;
                    // h3       <= '0;
                    // h4       <= '0;
                    // h5       <= '0;
                    // h6       <= '0;
                    // h7       <= '0;
                    sml_sgma_1_p0 <= '0;
                    sml_sgma_0_p0 <= '0;
                    sml_sgma_1_p1 <= '0;
                    sml_sgma_0_p1 <= '0;
                    choice        <= '0;
                    major         <= '0;
                    big_sgma_0    <= '0;
                    big_sgma_1    <= '0;
                    T1            <= '0;
                    T2            <= '0;
                    // done          <= 1'b0;
                end
            endcase
        end
    end



    always_ff @(posedge clk) begin
        if(~rst_n) begin
            h0       <= '0;
            h1       <= '0;
            h2       <= '0;
            h3       <= '0;
            h4       <= '0;
            h5       <= '0;
            h6       <= '0;
            h7       <= '0;
            done     <= 1'b0;
        end
        else begin
            if(idx_cmpr == 79 && curr_state == ST_IDLE) begin
                h0   <= `H0 + a;
                h1   <= `H1 + b;
                h2   <= `H2 + c;
                h3   <= `H3 + d;
                h4   <= `H4 + e;
                h5   <= `H5 + f;
                h6   <= `H6 + g;
                h7   <= `H7 + h;
                done <= 1'b1;
            end
        end
    end



    /**
     * data output
     *  */
     always_comb begin
         hash_o = {h0,h1,h2,h3,h4,h5,h6,h7};
     end
 endmodule : kdy_sha2