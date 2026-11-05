`timescale 1ns/1ps

module tb_Point_Multi_ED25519;
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n, start, valid;
    reg [255:0] k, px, py;
    wire [255:0] qx, qy;
    wire done, ready;

    Point_Multi_ED25519 dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid),
        .k(k), .px(px), .py(py), .qx(qx), .qy(qy),
        .done(done), .ready(ready)
    );

    localparam [255:0] P = 256'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
    localparam [255:0] BX = 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BY = 256'h6666666666666666666666666666666666666666666666666666666666666658;
    localparam [255:0] X1 = BX, Y1 = BY;
    localparam [255:0] X2 = 256'h36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e;
    localparam [255:0] Y2 = 256'h2260cdf3092329c21da25ee8c9a21f5697390f51643851560e5f46ae6af8a3c9;
    localparam [255:0] X3 = 256'h67ae9c4a22928f491ff4ae743edac83a6343981981624886ac62485fd3f8e25c;
    localparam [255:0] Y3 = 256'h1267b1d177ee69aba126a18e60269ef79f16ec176724030402c3684878f5b4d4;

    localparam [3:0] IDLE=0, CALC_P_START=1, CALC_P_WAIT=2,
        CALC_Q_START=3, CALC_Q_WAIT=4, INV_Z_START=5,
        INV_Z_WAIT=6, CALC_QX_START=7, CALC_QX_WAIT=8,
        CALC_QY_START=9, CALC_QY_WAIT=10, DONE_ST=11;

    // Các giới hạn là số chu kỳ; điều chỉnh phù hợp độ trễ IP thực tế.
    localparam integer MUL_LIMIT  = 200000;
    localparam integer SMSM_LIMIT = 5000000;
    localparam integer INV_LIMIT  = 2000000;
    localparam integer TOTAL_LIMIT = 12000000;

    // Reference arithmetic: chỉ dùng trong testbench, KHÔNG synthesizable.
    function [255:0] mod_mul;
        input [255:0] a;
        input [255:0] b;
        reg [511:0] product;
        begin
            product = a * b;
            mod_mul = product % {256'd0, P};
        end
    endfunction

    function [8*16-1:0] state_name;
        input [3:0] s;
        case (s)
            IDLE:          state_name="IDLE";
            CALC_P_START:  state_name="CALC_P_START";
            CALC_P_WAIT:   state_name="CALC_P_WAIT";
            CALC_Q_START:  state_name="CALC_Q_START";
            CALC_Q_WAIT:   state_name="CALC_Q_WAIT";
            INV_Z_START:   state_name="INV_Z_START";
            INV_Z_WAIT:    state_name="INV_Z_WAIT";
            CALC_QX_START: state_name="CALC_QX_START";
            CALC_QX_WAIT:  state_name="CALC_QX_WAIT";
            CALC_QY_START: state_name="CALC_QY_START";
            CALC_QY_WAIT:  state_name="CALC_QY_WAIT";
            DONE_ST:       state_name="DONE_ST";
            default:       state_name="UNKNOWN";
        endcase
    endfunction

    // ===== ALU handshake flight recorder (top-level interface only) =====
    integer alu_start_count, alu_done_count, alu_reset_cycles;
    integer alu_start_while_reset, alu_reset_during_operation;
    integer alu_last_start_cycle, alu_last_done_cycle;
    integer alu_consecutive_pending, alu_max_pending;
    reg alu_previous_start, alu_previous_done, alu_previous_rst;
    reg alu_pending;
    reg [255:0] last_alu_qx, last_alu_qy, last_alu_qz, last_alu_qt;
    reg [255:0] last_alu_px, last_alu_py, last_alu_pz, last_alu_pt;
    reg [255:0] last_alu_bx, last_alu_by, last_alu_bz, last_alu_bt;
    reg last_alu_op;

    integer test_id, checks, errors, passed_cases, failed_cases;
    integer cycle_no, stage_cycles;
    reg [3:0] prev_state;
    reg active_case;
    reg [255:0] golden_x, golden_y, golden_pt;
    reg warned_reset_mul, warned_reset_smsm, warned_reset_inv;
    reg [255:0] tmp_x, tmp_y;

    task automatic check_eq;
        input [8*64-1:0] label;
        input [255:0] got;
        input [255:0] expected;
        begin
            checks = checks + 1;
            if (got !== expected) begin
                errors = errors + 1;
                $display("[FAIL] T%0d %0s", test_id, label);
                $display("       GOT=%064h", got);
                $display("       EXP=%064h", expected);
            end else begin
                $display("[PASS] T%0d %0s = %064h", test_id, label, got);
            end
        end
    endtask

    task automatic check_bool;
        input [8*64-1:0] label;
        input ok;
        begin
            checks = checks + 1;
            if (ok !== 1'b1) begin
                errors = errors + 1;
                $display("[FAIL] T%0d %0s", test_id, label);
            end else
                $display("[PASS] T%0d %0s", test_id, label);
        end
    endtask

    task automatic show_debug;
        begin
            $display("----- SNAPSHOT @ cycle %0d -----", cycle_no);
            $display("state=%0s (%0d) stage_cycles=%0d ready=%b done=%b",
                state_name(dut.state), dut.state, stage_cycles, ready, done);
            $display("MUL : rst_n=%b start=%b done=%b X=%064h Y=%064h R=%064h",
                dut.rst_n_mul, dut.start_mul, dut.mul_done, dut.X, dut.Y, dut.Z);
            $display("SMSM: rst_n=%b start=%b done=%b k=%064h",
                dut.rst_n_SMSM, dut.start_SMSM, dut.SMSM_done, dut.k_latched);
            $display("ALU : rst_n=%b start=%b done=%b op=%b",
                dut.rst_n_alu, dut.start_alu, dut.alu_done, dut.op_alu);
            $display("INV : rst_n=%b start=%b done=%b a=%064h a_inv=%064h",
                dut.rst_n_inv, dut.start_inv, dut.inv_done, dut.a, dut.a_inv);
            $display("SMSM result: X=%064h Y=%064h Z=%064h T=%064h",
                dut.result_x, dut.result_y, dut.result_z, dut.result_t);
            $display("pt=%064h Z_qx=%064h Z_qy=%064h", dut.pt, dut.Z_qx, dut.Z_qy);
            $display("----------------------------------");
        end
    endtask

    // Theo doi luong SMSM -> ALU. Khong can biet state noi bo cua 2 module.
    // Lay mau sau NBA (#1), nen mot xung start_dang=1 se duoc ALU
    // nhin thay tai canh posedge ke tiep (neu reset khong assert).
    task show_alu_diagnosis;
        begin
            $display("----------- ALU FLIGHT RECORDER T%0d -----------", test_id);
            $display("ALU start pulses        = %0d", alu_start_count);
            $display("ALU done pulses         = %0d", alu_done_count);
            $display("ALU reset-low cycles    = %0d", alu_reset_cycles);
            $display("start while reset low   = %0d", alu_start_while_reset);
            $display("reset during operation  = %0d", alu_reset_during_operation);
            $display("last start cycle        = %0d", alu_last_start_cycle);
            $display("last done cycle         = %0d", alu_last_done_cycle);
            $display("ALU in-flight           = %b", alu_pending);
            $display("max cycles in-flight    = %0d", alu_max_pending);
            if (alu_start_count == 0) begin
                $display("[DIAG A] SMSM never asserted start_alu.");
                $display("         Inspect SMSM FSM, scalar bit=1 logic and ALU launch states.");
            end else if (alu_start_while_reset > 0) begin
                $display("[DIAG B] SMSM asserted start_alu with rst_n_alu=0.");
                $display("         Check SMSM reset pulse generation and start ordering.");
            end else if (alu_reset_during_operation > 0) begin
                $display("[DIAG C] rst_n_alu went low before matching alu_done.");
                $display("         Check unintended resets during arithmetic.");
            end else if (alu_start_count > alu_done_count) begin
                $display("[DIAG D] ALU start observed, but one/more ALU done missing.");
                $display("         Inspect alu_point_core and arithmetic submodule handshakes.");
            end else if (alu_done_count > 0 && dut.SMSM_done !== 1'b1) begin
                $display("[DIAG E] ALU completed, but SMSM has not completed.");
                $display("         Inspect SMSM state transitions, alu_done sampling, bit counter.");
            end else begin
                $display("[DIAG F] Check SMSM control flow and unexpected return to idle.");
            end
            if (alu_start_count != 0) begin
                $display("Last ALU request: op=%b", last_alu_op);
                $display("    Q=(%064h, %064h, %064h, %064h)",
                    last_alu_qx, last_alu_qy, last_alu_qz, last_alu_qt);
                $display("    P=(%064h, %064h, %064h, %064h)",
                    last_alu_px, last_alu_py, last_alu_pz, last_alu_pt);
                $display("    B=(%064h, %064h, %064h, %064h)",
                    last_alu_bx, last_alu_by, last_alu_bz, last_alu_bt);
            end
            $display("------------------------------------------------");
        end
    endtask

    // Monitor lấy mẫu sau cạnh clock để thấy giá trị cập nhật qua <=.
    // Checkpoint tại lần đầu VÀO trạng thái kế tiếp, khi dữ liệu đã latch.
    always @(posedge clk) begin
        #1;
        if (!rst_n) begin
            prev_state = 4'hf;
            stage_cycles = 0;
        end else if (active_case) begin
            cycle_no = cycle_no + 1;
            if (dut.state !== prev_state) begin
                $display("[FSM ] T%0d cycle=%0d %0s -> %0s",
                    test_id, cycle_no, state_name(prev_state), state_name(dut.state));
                stage_cycles = 0;

                case (dut.state)
                    CALC_P_START: begin
                        check_eq("k_latched", dut.k_latched, k);
                        check_eq("px_latched", dut.px_latched, px);
                        check_eq("py_latched", dut.py_latched, py);
                    end
                    CALC_Q_START: begin
                        // CALC_P_WAIT vừa nhận mul_done và latch pt.
                        check_eq("[P] pt=px*py mod p", dut.pt, golden_pt);
                    end
                    INV_Z_START: begin
                        // SMSM vừa báo done; kiểm tra theo tọa độ projective.
                        check_bool("[Q] result_z nonzero",
                                   (dut.result_z !== 256'd0) &&
                                   (^dut.result_z !== 1'bx));
                        tmp_x = mod_mul(golden_x, dut.result_z);
                        tmp_y = mod_mul(golden_y, dut.result_z);
                        check_eq("[Q] result_x == expected_x*Z", dut.result_x, tmp_x);
                        check_eq("[Q] result_y == expected_y*Z", dut.result_y, tmp_y);
                        check_eq("[Q] X*Y == Z*T (extended coordinates)",
                                 mod_mul(dut.result_x, dut.result_y),
                                 mod_mul(dut.result_z, dut.result_t));
                    end
                    CALC_QX_START: begin
                        // INV_Z_WAIT vừa nhận inv_done.
                        check_eq("[INV] Z * Z_inv == 1",
                                 mod_mul(dut.result_z, dut.a_inv), 256'd1);
                    end
                    CALC_QY_START: begin
                        // CALC_QX_WAIT vừa latch Z_qx.
                        check_eq("[QX] Z_qx", dut.Z_qx, golden_x);
                    end
                    DONE_ST: begin
                        // CALC_QY_WAIT vừa latch Z_qy.
                        check_eq("[QY] Z_qy", dut.Z_qy, golden_y);
                    end
                    IDLE: if (prev_state == DONE_ST) begin
                        check_bool("[TOP] done asserted", done === 1'b1);
                        check_eq("[TOP] qx", qx, golden_x);
                        check_eq("[TOP] qy", qy, golden_y);
                    end
                endcase
            end else begin
                stage_cycles = stage_cycles + 1;
            end

            // ===== ALU handshake recorder =====
            // Count rising edges, not signal levels.
            if (dut.state == CALC_Q_WAIT && dut.rst_n_alu !== 1'b1)
                alu_reset_cycles = alu_reset_cycles + 1;

            if (dut.start_alu === 1'b1 && !alu_previous_start) begin
                alu_start_count = alu_start_count + 1;
                alu_last_start_cycle = cycle_no;
                alu_pending = 1'b1;
                alu_consecutive_pending = 0;
                last_alu_op = dut.op_alu;
                last_alu_qx = dut.qx_alu;
                last_alu_qy = dut.qy_alu;
                last_alu_qz = dut.qz_alu;
                last_alu_qt = dut.qt_alu;
                last_alu_px = dut.px_alu;
                last_alu_py = dut.py_alu;
                last_alu_pz = dut.pz_alu;
                last_alu_pt = dut.pt_alu;
                last_alu_bx = dut.bx_alu;
                last_alu_by = dut.by_alu;
                last_alu_bz = dut.bz_alu;
                last_alu_bt = dut.bt_alu;
                $display("[ALU START] T%0d cycle=%0d req=%0d op=%b rst_n_alu=%b",
                    test_id, cycle_no, alu_start_count, dut.op_alu, dut.rst_n_alu);
                if (dut.rst_n_alu !== 1'b1) begin
                    alu_start_while_reset = alu_start_while_reset + 1;
                    $display("[ALU ERROR] START asserted while ALU held in reset!");
                end
                $display("            q=(%064h,%064h,%064h,%064h)",
                    dut.qx_alu, dut.qy_alu, dut.qz_alu, dut.qt_alu);
                $display("            p=(%064h,%064h,%064h,%064h)",
                    dut.px_alu, dut.py_alu, dut.pz_alu, dut.pt_alu);
                $display("            b=(%064h,%064h,%064h,%064h)",
                    dut.bx_alu, dut.by_alu, dut.bz_alu, dut.bt_alu);
            end
            if (dut.alu_done === 1'b1 && !alu_previous_done) begin
                alu_done_count = alu_done_count + 1;
                alu_last_done_cycle = cycle_no;
                $display("[ALU DONE ] T%0d cycle=%0d completed=%0d latency=%0d",
                    test_id, cycle_no, alu_done_count,
                    (alu_last_start_cycle >= 0) ? cycle_no - alu_last_start_cycle : -1);
                alu_pending = 1'b0;
            end
            if (alu_pending && alu_previous_rst === 1'b1 &&
                dut.rst_n_alu !== 1'b1) begin
                alu_reset_during_operation = alu_reset_during_operation + 1;
                $display("[ALU ERROR] Reset asserted DURING pending ALU operation at cycle=%0d", cycle_no);
                alu_pending = 1'b0;
            end
            if (dut.rst_n_alu !== alu_previous_rst &&
                (alu_start_count < 12 || alu_pending)) begin
                $display("[ALU RESET] T%0d cycle=%0d rst_n_alu %b -> %b",
                    test_id, cycle_no, alu_previous_rst, dut.rst_n_alu);
            end
            if (alu_pending) begin
                alu_consecutive_pending = alu_consecutive_pending + 1;
                if (alu_consecutive_pending > alu_max_pending)
                    alu_max_pending = alu_consecutive_pending;
            end
            alu_previous_start = (dut.start_alu === 1'b1);
            alu_previous_done  = (dut.alu_done === 1'b1);
            alu_previous_rst   = dut.rst_n_alu;

            // Compact heartbeat so no need to wait for 5 million cycles.
            if (dut.state == CALC_Q_WAIT &&
               (stage_cycles == 1000 || stage_cycles == 10000 ||
                stage_cycles == 100000 || stage_cycles == 1000000)) begin
                $display("[Q HEARTBEAT] cycles=%0d ALU starts=%0d dones=%0d reset-low=%0d pending=%b",
                     stage_cycles, alu_start_count, alu_done_count,
                     alu_reset_cycles, alu_pending);
                if (stage_cycles == 10000 && alu_start_count == 0)
                    $display("[Q HINT] No start_alu in first 10000 CALC_Q_WAIT cycles.");
            end

            // Log xung bắt đầu/hoàn tất của IP, không truy cập state nội bộ IP.
            if (dut.start_mul)  $display("[PULSE] MUL.start at %0s", state_name(dut.state));
            if (dut.start_SMSM) $display("[PULSE] SMSM.start at %0s", state_name(dut.state));
            if (dut.start_inv)  $display("[PULSE] INV.start at %0s", state_name(dut.state));
            if (dut.mul_done)   $display("[PULSE] MUL.done at %0s", state_name(dut.state));
            if (dut.SMSM_done)  $display("[PULSE] SMSM.done at %0s", state_name(dut.state));
            if (dut.inv_done)   $display("[PULSE] INV.done at %0s", state_name(dut.state));

            // Kiểm tra reset đang bị assert trong lúc chờ IP hoàn tất.
            if ((dut.state == CALC_P_WAIT || dut.state == CALC_QX_WAIT ||
                 dut.state == CALC_QY_WAIT) && dut.rst_n_mul !== 1'b1 &&
                 !warned_reset_mul) begin
                warned_reset_mul = 1;
                errors = errors + 1;
                $display("[ROOT CAUSE] rst_n_mul=0 while waiting MUL! Submodule is held in reset.");
                show_debug();
            end
            if (dut.state == CALC_Q_WAIT && dut.rst_n_SMSM !== 1'b1 &&
                !warned_reset_smsm) begin
                warned_reset_smsm = 1;
                errors = errors + 1;
                $display("[ROOT CAUSE] rst_n_SMSM=0 while waiting SMSM!");
                show_debug();
            end
            if (dut.state == INV_Z_WAIT && dut.rst_n_inv !== 1'b1 &&
                !warned_reset_inv) begin
                warned_reset_inv = 1;
                errors = errors + 1;
                $display("[ROOT CAUSE] rst_n_inv=0 while waiting INV!");
                show_debug();
            end

            if (((dut.state == CALC_P_WAIT || dut.state == CALC_QX_WAIT ||
                  dut.state == CALC_QY_WAIT) && stage_cycles > MUL_LIMIT) ||
                (dut.state == CALC_Q_WAIT && stage_cycles > SMSM_LIMIT) ||
                (dut.state == INV_Z_WAIT && stage_cycles > INV_LIMIT) ||
                cycle_no > TOTAL_LIMIT) begin
                $display("[TIMEOUT] T%0d stuck at %0s for %0d cycles",
                    test_id, state_name(dut.state), stage_cycles);
                case (dut.state)
                    CALC_P_WAIT:  $display("[HINT] Check modulo_mul pt=px*py, reset/start/done.");
                    CALC_Q_WAIT:  $display("[HINT] Check Scalar_multi_SM + alu_point_core handshake.");
                    INV_Z_WAIT:  $display("[HINT] Check invert reset/start/done.");
                    CALC_QX_WAIT: $display("[HINT] Check modulo_mul result_x*a_inv.");
                    CALC_QY_WAIT: $display("[HINT] Check modulo_mul result_y*a_inv.");
                    default:      $display("[HINT] Inspect state transition/control logic.");
                endcase
                show_debug();
                if (dut.state == CALC_Q_WAIT) show_alu_diagnosis();
                $display("[SUMMARY] Checks=%0d Errors=%0d, terminated at first hang.",
                    checks, errors+1);
                $finish;
            end
            prev_state = dut.state;
        end
    end

    task automatic run_case;
        input integer id;
        input [255:0] scalar;
        input [255:0] exp_x;
        input [255:0] exp_y;
        integer timeout_ready;
        integer errors_before;
        begin
            test_id = id;
            alu_start_count = 0;
            alu_done_count = 0;
            alu_reset_cycles = 0;
            alu_start_while_reset = 0;
            alu_reset_during_operation = 0;
            alu_last_start_cycle = -1;
            alu_last_done_cycle = -1;
            alu_consecutive_pending = 0;
            alu_max_pending = 0;
            alu_pending = 0;
            alu_previous_start = 0;
            alu_previous_done = 0;
            alu_previous_rst = dut.rst_n_alu;
            golden_x = exp_x;
            golden_y = exp_y;
            golden_pt = mod_mul(BX, BY);
            warned_reset_mul = 0;
            warned_reset_smsm = 0;
            warned_reset_inv = 0;
            cycle_no = 0;
            stage_cycles = 0;
            errors_before = errors;
            prev_state = 4'hf;
            $display("\n========== TEST %0d: k=%0d =========", id, scalar);

            @(negedge clk);
            k = scalar; px = BX; py = BY;
            valid = 1; start = 0;
            timeout_ready = 0;
            // ready là output registered: chờ tới khi nhận ready=1.
            while (ready !== 1'b1 && timeout_ready < 20) begin
                @(negedge clk);
                timeout_ready = timeout_ready + 1;
            end
            if (ready !== 1'b1) begin
                $display("[FAIL] ready never asserted with valid nonzero inputs");
                show_debug();
                $finish;
            end
            active_case = 1;
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            valid = 0;

            // done pulse occurs when state becomes IDLE after DONE_ST.
            while (done !== 1'b1) @(negedge clk);
            // monitor đã chạy #1 tại posedge trước đó.
            if (errors == errors_before) begin
                passed_cases = passed_cases + 1;
                $display("[CASE PASS] T%0d, total cycles=%0d", id, cycle_no);
            end else begin
                failed_cases = failed_cases + 1;
                $display("[CASE FAIL] T%0d, additional errors=%0d", id,
                    errors-errors_before);
            end
            $display("[ALU SUMMARY] T%0d starts=%0d dones=%0d reset-on-start=%0d reset-during-run=%0d",
                test_id, alu_start_count, alu_done_count,
                alu_start_while_reset, alu_reset_during_operation);
            active_case = 0;
            repeat (3) @(negedge clk);
        end
    endtask

    initial begin
        rst_n=0; start=0; valid=0; k=0; px=0; py=0;
        test_id=0; checks=0; errors=0; passed_cases=0; failed_cases=0;
        active_case=0; cycle_no=0; stage_cycles=0; prev_state=4'hf;
        warned_reset_mul=0; warned_reset_smsm=0; warned_reset_inv=0;
        $dumpfile("Point_Multi_ED25519_alu_debug.vcd");
        $dumpvars(0, tb_Point_Multi_ED25519);
        repeat (5) @(negedge clk);
        rst_n=1;
        // IMPORTANT: Run k=2 FIRST immediately after top-level reset.
        // This isolates a k=2 ALU bug from a re-arm bug after k=1.
        // If k=2 fails here, investigate ALU/SMSM itself.
        // If k=2 passes first, but fails after k=1, investigate restart.
        run_case(2, 256'd2, X2, Y2);
        run_case(1, 256'd1, X1, Y1);
        run_case(2, 256'd2, X2, Y2);
        run_case(3, 256'd3, X3, Y3);
        $display("\n========== FINAL ==========");
        $display("cases PASS=%0d FAIL=%0d; checkpoints=%0d errors=%0d",
            passed_cases, failed_cases, checks, errors);
        $finish;
    end
endmodule