`timescale 1ns/1ps

module tb_Point_Multi_ED25519;
//    parameter integer RUN_LONG = 0;
//    // 0: concise ALU trace; 1: log every ALU request with operands.
//    parameter integer VERBOSE_ALU = 0;
//    reg clk = 0;
//    always #5 clk = ~clk;

//    reg rst_n, start, valid;
//    reg [255:0] k, px, py;
//    wire [255:0] qx, qy;
//    wire done, ready;

//    Point_Multi_ED25519 dut (
//        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid),
//        .k(k), .px(px), .py(py), .qx(qx), .qy(qy),
//        .done(done), .ready(ready)
//    );

//    localparam [255:0] P = 256'h7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed;
//    localparam [255:0] BX = 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
//    localparam [255:0] BY = 256'h6666666666666666666666666666666666666666666666666666666666666658;
//    localparam [255:0] X1 = BX, Y1 = BY;
//    localparam [255:0] X2 = 256'h36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e;
//    localparam [255:0] Y2 = 256'h2260cdf3092329c21da25ee8c9a21f5697390f51643851560e5f46ae6af8a3c9;
//    localparam [255:0] X3 = 256'h67ae9c4a22928f491ff4ae743edac83a6343981981624886ac62485fd3f8e25c;
//    localparam [255:0] Y3 = 256'h1267b1d177ee69aba126a18e60269ef79f16ec176724030402c3684878f5b4d4;

//    // Independently computed twisted-Edwards affine point multiplication vectors.
//    // Reference uses d = -121665/121666 (mod p) and NO scalar clamping.
//    // Cross-checked by two independent formulas: affine and extended Edwards.
//    localparam [255:0] X_4 = 256'h203da8db56cff1468325d4b87a3520f91a739ec193ce1547493aa657c4c9f870;
//    localparam [255:0] Y_4 = 256'h47d0e827cb1595e1470eb88580d5716c4cf22832ea2f0ff0df38ab61ca32112f;
//    localparam [255:0] X_5 = 256'h49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233;
//    localparam [255:0] Y_5 = 256'h5f4825b298feae6fe02c6e148992466631282eca89430b5d10d21f83d676c8ed;
//    localparam [255:0] X_7 = 256'h14568685fcf4bd4ee9e3ee194b1d810783e809f3bbf1ce955855981af50e4107;
//    localparam [255:0] Y_7 = 256'h31c563e32b47d52f87ce6468dd36ad41f0882b46f7abf23d12c4c4b59f4062b8;
//    localparam [255:0] X_15 = 256'h4f162deaec2ec435dc5ac6f95d20419ed9631374770189cb90617f3e66a18dc1;
//    localparam [255:0] Y_15 = 256'h12cbfb2d04ff22f55162f70164d29331ace5af18a19a9aa1946d4cc4ad2e5cdf;
//    localparam [255:0] X_16 = 256'h23a4860627e53aeeb8e22b1508249c9109578d33e7bf237459b2596d6c28f9f8;
//    localparam [255:0] Y_16 = 256'h709696f2827fc3729f980f2e3aad6e78b06a11ff8e079c27d87aab37c16727eb;
//    localparam [255:0] X_31 = 256'h38085391a0e2831f59c33fcce7591515784d359925f11ff958e0e4658efac0e9;
//    localparam [255:0] Y_31 = 256'h42918001a829f49b5634e34ab7fac21b30e24660669ed91955cc31944a19e62a;
//    localparam [255:0] X_127 = 256'h735b64bb872606510e4e7d57833eb7ffdc4aa0dbaa242439806be68379f77cdd;
//    localparam [255:0] Y_127 = 256'h384aaaee3ca7ba2436fcb65910859ca5ec30c10af11df7d777d287bc1a2bce2c;
//    localparam [255:0] X_255 = 256'h5174e33ffdf28a87184a4d6427d821cbaa3b88ac293a90ca7e1eeae8c5050b16;
//    localparam [255:0] Y_255 = 256'h315ca6bc8e35e4a3d06f89e1db1575b16197963ee8e64746fa998ccd403561cc;
//    localparam [255:0] X_128PLUS1 = 256'h6e64e5552b88e48f8ab3c1be8cc36053b0e6ec0831ecbce6fbe2fd29680c969a;
//    localparam [255:0] Y_128PLUS1 = 256'h383c510fa4cb58be6a9dfc9339b85145363911589ec5521025352a647bafd09b;
//    localparam [255:0] X_255PLUS1 = 256'h7a8553ada43394466e33b2b9f230812e993de3e3428bf08a322a0846b2fbc6d8;
//    localparam [255:0] Y_255PLUS1 = 256'h274a7f39b56dff94e87f869f877141b34e840e6fe1b465f6345051588f3f7abe;
//    localparam [255:0] X_RANDOM = 256'h36af09c84576fb3db536f12634f5d00c211340759276f884c7199f497c9f033e;
//    localparam [255:0] Y_RANDOM = 256'h39ade05477439623c9ba85a70da775e23c45a56eb1dfcf577e35c8556671ef24;
//    localparam [255:0] K_128PLUS1 = 256'h0000000000000000000000000000000100000000000000000000000000000001;
//    localparam [255:0] K_255PLUS1 = 256'h8000000000000000000000000000000000000000000000000000000000000001;
//    localparam [255:0] K_RANDOM = 256'ha108569174dda9adb4887ac243fe786042a74ace34e5278a1aedaac2f439ad6a;

//    localparam [3:0] IDLE=0, CALC_P_START=1, CALC_P_WAIT=2,
//        CALC_Q_START=3, CALC_Q_WAIT=4, INV_Z_START=5,
//        INV_Z_WAIT=6, CALC_QX_START=7, CALC_QX_WAIT=8,
//        CALC_QY_START=9, CALC_QY_WAIT=10, DONE_ST=11;

//    // Limits are in clock cycles (10 ns each). Increase only if your IP is slower.
//    localparam integer MUL_LIMIT  = 200000;
//    localparam integer SMSM_LIMIT = 5000000;
//    localparam integer INV_LIMIT  = 2000000;
//    localparam integer TOTAL_LIMIT = 12000000;

//    // Reference arithmetic: chỉ dùng trong testbench, KHÔNG synthesizable.
//    function [255:0] mod_mul;
//        input [255:0] a;
//        input [255:0] b;
//        reg [511:0] product;
//        begin
//            product = a * b;
//            mod_mul = product % {256'd0, P};
//        end
//    endfunction

//    function [8*16-1:0] state_name;
//        input [3:0] s;
//        case (s)
//            IDLE:          state_name="IDLE";
//            CALC_P_START:  state_name="CALC_P_START";
//            CALC_P_WAIT:   state_name="CALC_P_WAIT";
//            CALC_Q_START:  state_name="CALC_Q_START";
//            CALC_Q_WAIT:   state_name="CALC_Q_WAIT";
//            INV_Z_START:   state_name="INV_Z_START";
//            INV_Z_WAIT:    state_name="INV_Z_WAIT";
//            CALC_QX_START: state_name="CALC_QX_START";
//            CALC_QX_WAIT:  state_name="CALC_QX_WAIT";
//            CALC_QY_START: state_name="CALC_QY_START";
//            CALC_QY_WAIT:  state_name="CALC_QY_WAIT";
//            DONE_ST:       state_name="DONE_ST";
//            default:       state_name="UNKNOWN";
//        endcase
//    endfunction

//    // ===== ALU handshake flight recorder (top-level interface only) =====
//    integer alu_start_count, alu_done_count, alu_reset_cycles;
//    integer alu_double_count, alu_add_count;
//    integer expected_double, expected_add;
//    integer alu_start_while_reset, alu_reset_during_operation;
//    integer alu_last_start_cycle, alu_last_done_cycle;
//    integer alu_consecutive_pending, alu_max_pending;
//    reg alu_previous_start, alu_previous_done, alu_previous_rst;
//    reg alu_pending;
//    reg [255:0] last_alu_qx, last_alu_qy, last_alu_qz, last_alu_qt;
//    reg [255:0] last_alu_px, last_alu_py, last_alu_pz, last_alu_pt;
//    reg [255:0] last_alu_bx, last_alu_by, last_alu_bz, last_alu_bt;
//    reg last_alu_op;

//    integer test_id, checks, errors, passed_cases, failed_cases;
//    integer cycle_no, stage_cycles;
//    reg [3:0] prev_state;
//    reg active_case;
//    reg [255:0] golden_x, golden_y, golden_pt;
//    reg warned_reset_mul, warned_reset_smsm, warned_reset_inv;
//    reg [255:0] tmp_x, tmp_y;
//    integer active_high_bit, active_ones;

//    task automatic check_eq;
//        input [8*64-1:0] label;
//        input [255:0] got;
//        input [255:0] expected;
//        begin
//            checks = checks + 1;
//            if (got !== expected) begin
//                errors = errors + 1;
//                $display("[FAIL] T%0d %0s", test_id, label);
//                $display("       GOT=%064h", got);
//                $display("       EXP=%064h", expected);
//            end else begin
//                $display("[PASS] T%0d %0s = %064h", test_id, label, got);
//            end
//        end
//    endtask

//    task automatic check_bool;
//        input [8*64-1:0] label;
//        input ok;
//        begin
//            checks = checks + 1;
//            if (ok !== 1'b1) begin
//                errors = errors + 1;
//                $display("[FAIL] T%0d %0s", test_id, label);
//            end else
//                $display("[PASS] T%0d %0s", test_id, label);
//        end
//    endtask

//    task automatic show_debug;
//        begin
//            $display("----- SNAPSHOT @ cycle %0d -----", cycle_no);
//            $display("state=%0s (%0d) stage_cycles=%0d ready=%b done=%b",
//                state_name(dut.state), dut.state, stage_cycles, ready, done);
//            $display("MUL : rst_n=%b start=%b done=%b X=%064h Y=%064h R=%064h",
//                dut.rst_n_mul, dut.start_mul, dut.mul_done, dut.X, dut.Y, dut.Z);
//            $display("SMSM: rst_n=%b start=%b done=%b k=%064h",
//                dut.rst_n_SMSM, dut.start_SMSM, dut.SMSM_done, dut.k_latched);
//            $display("ALU : rst_n=%b start=%b done=%b op=%b",
//                dut.rst_n_alu, dut.start_alu, dut.alu_done, dut.op_alu);
//            $display("INV : rst_n=%b start=%b done=%b a=%064h a_inv=%064h",
//                dut.rst_n_inv, dut.start_inv, dut.inv_done, dut.a, dut.a_inv);
//            $display("SMSM result: X=%064h Y=%064h Z=%064h T=%064h",
//                dut.result_x, dut.result_y, dut.result_z, dut.result_t);
//            $display("pt=%064h Z_qx=%064h Z_qy=%064h", dut.pt, dut.Z_qx, dut.Z_qy);
//            $display("----------------------------------");
//        end
//    endtask

//    // Theo doi luong SMSM -> ALU. Khong can biet state noi bo cua 2 module.
//    // Lay mau sau NBA (#1), nen mot xung start_dang=1 se duoc ALU
//    // nhin thay tai canh posedge ke tiep (neu reset khong assert).
//    task show_alu_diagnosis;
//        begin
//            $display("----------- ALU FLIGHT RECORDER T%0d -----------", test_id);
//            $display("Expected DOUBLE/ADD     = %0d / %0d", expected_double, expected_add);
//            $display("Actual DOUBLE/ADD       = %0d / %0d", alu_double_count, alu_add_count);
//            $display("ALU start pulses        = %0d", alu_start_count);
//            $display("ALU done pulses         = %0d", alu_done_count);
//            $display("ALU reset-low cycles    = %0d", alu_reset_cycles);
//            $display("start while reset low   = %0d", alu_start_while_reset);
//            $display("reset during operation  = %0d", alu_reset_during_operation);
//            $display("last start cycle        = %0d", alu_last_start_cycle);
//            $display("last done cycle         = %0d", alu_last_done_cycle);
//            $display("ALU in-flight           = %b", alu_pending);
//            $display("max cycles in-flight    = %0d", alu_max_pending);
//            if (alu_start_count == 0) begin
//                $display("[DIAG A] SMSM never asserted start_alu.");
//                $display("         Inspect SMSM FSM, scalar bit=1 logic and ALU launch states.");
//            end else if (alu_start_while_reset > 0) begin
//                $display("[DIAG B] SMSM asserted start_alu with rst_n_alu=0.");
//                $display("         Check SMSM reset pulse generation and start ordering.");
//            end else if (alu_reset_during_operation > 0) begin
//                $display("[DIAG C] rst_n_alu went low before matching alu_done.");
//                $display("         Check unintended resets during arithmetic.");
//            end else if (alu_start_count > alu_done_count) begin
//                $display("[DIAG D] ALU start observed, but one/more ALU done missing.");
//                $display("         Inspect alu_point_core and arithmetic submodule handshakes.");
//            end else if (alu_done_count > 0 && dut.SMSM_done !== 1'b1) begin
//                $display("[DIAG E] ALU completed, but SMSM has not completed.");
//                $display("         Inspect SMSM state transitions, alu_done sampling, bit counter.");
//            end else begin
//                $display("[DIAG F] Check SMSM control flow and unexpected return to idle.");
//            end
//            if (alu_start_count != 0) begin
//                $display("Last ALU request: op=%b", last_alu_op);
//                $display("    Q=(%064h, %064h, %064h, %064h)",
//                    last_alu_qx, last_alu_qy, last_alu_qz, last_alu_qt);
//                $display("    P=(%064h, %064h, %064h, %064h)",
//                    last_alu_px, last_alu_py, last_alu_pz, last_alu_pt);
//                $display("    B=(%064h, %064h, %064h, %064h)",
//                    last_alu_bx, last_alu_by, last_alu_bz, last_alu_bt);
//            end
//            $display("------------------------------------------------");
//        end
//    endtask

//    // Monitor lấy mẫu sau cạnh clock để thấy giá trị cập nhật qua <=.
//    // Checkpoint tại lần đầu VÀO trạng thái kế tiếp, khi dữ liệu đã latch.
//    always @(posedge clk) begin
//        #1;
//        if (!rst_n) begin
//            prev_state = 4'hf;
//            stage_cycles = 0;
//        end else if (active_case) begin
//            cycle_no = cycle_no + 1;
//            if (dut.state !== prev_state) begin
//                $display("[FSM ] T%0d cycle=%0d %0s -> %0s",
//                    test_id, cycle_no, state_name(prev_state), state_name(dut.state));
//                stage_cycles = 0;

//                case (dut.state)
//                    CALC_P_START: begin
//                        check_eq("k_latched", dut.k_latched, k);
//                        check_eq("px_latched", dut.px_latched, px);
//                        check_eq("py_latched", dut.py_latched, py);
//                    end
//                    CALC_Q_START: begin
//                        // CALC_P_WAIT vừa nhận mul_done và latch pt.
//                        check_eq("[P] pt=px*py mod p", dut.pt, golden_pt);
//                    end
//                    INV_Z_START: begin
//                        // SMSM vừa báo done; kiểm tra theo tọa độ projective.
//                        check_bool("[Q] result_z nonzero",
//                                   (dut.result_z !== 256'd0) &&
//                                   (^dut.result_z !== 1'bx));
//                        tmp_x = mod_mul(golden_x, dut.result_z);
//                        tmp_y = mod_mul(golden_y, dut.result_z);
//                        check_eq("[Q] result_x == expected_x*Z", dut.result_x, tmp_x);
//                        check_eq("[Q] result_y == expected_y*Z", dut.result_y, tmp_y);
//                        check_eq("[Q] X*Y == Z*T (extended coordinates)",
//                                 mod_mul(dut.result_x, dut.result_y),
//                                 mod_mul(dut.result_z, dut.result_t));
//                    end
//                    CALC_QX_START: begin
//                        // INV_Z_WAIT vừa nhận inv_done.
//                        check_eq("[INV] Z * Z_inv == 1",
//                                 mod_mul(dut.result_z, dut.a_inv), 256'd1);
//                    end
//                    CALC_QY_START: begin
//                        // CALC_QX_WAIT vừa latch Z_qx.
//                        check_eq("[QX] Z_qx", dut.Z_qx, golden_x);
//                    end
//                    DONE_ST: begin
//                        // CALC_QY_WAIT vừa latch Z_qy.
//                        check_eq("[QY] Z_qy", dut.Z_qy, golden_y);
//                    end
//                    IDLE: if (prev_state == DONE_ST) begin
//                        check_bool("[TOP] done asserted", done === 1'b1);
//                        check_eq("[TOP] qx", qx, golden_x);
//                        check_eq("[TOP] qy", qy, golden_y);
//                    end
//                endcase
//            end else begin
//                stage_cycles = stage_cycles + 1;
//            end

//            // ===== ALU handshake recorder =====
//            // Count rising edges, not signal levels.
//            if (dut.state == CALC_Q_WAIT && dut.rst_n_alu !== 1'b1)
//                alu_reset_cycles = alu_reset_cycles + 1;

//            if (dut.start_alu === 1'b1 && !alu_previous_start) begin
//                alu_start_count = alu_start_count + 1;
//                alu_last_start_cycle = cycle_no;
//                alu_pending = 1'b1;
//                alu_consecutive_pending = 0;
//                last_alu_op = dut.op_alu;
//                last_alu_qx = dut.qx_alu;
//                last_alu_qy = dut.qy_alu;
//                last_alu_qz = dut.qz_alu;
//                last_alu_qt = dut.qt_alu;
//                last_alu_px = dut.px_alu;
//                last_alu_py = dut.py_alu;
//                last_alu_pz = dut.pz_alu;
//                last_alu_pt = dut.pt_alu;
//                last_alu_bx = dut.bx_alu;
//                last_alu_by = dut.by_alu;
//                last_alu_bz = dut.bz_alu;
//                last_alu_bt = dut.bt_alu;
//                if (dut.op_alu === 1'b1) alu_double_count = alu_double_count + 1;
//                else if (dut.op_alu === 1'b0) alu_add_count = alu_add_count + 1;
//                else begin
//                    errors = errors + 1;
//                    $display("[ALU ERROR] op_alu is X/Z at ALU start");
//                end
//                if (VERBOSE_ALU || alu_start_count <= 4 ||
//                    (alu_start_count % 32) == 0 || dut.rst_n_alu !== 1'b1) begin
//                    $display("[ALU START] T%0d cycle=%0d req=%0d op=%b rst_n_alu=%b",
//                        test_id, cycle_no, alu_start_count, dut.op_alu, dut.rst_n_alu);
//                    if (VERBOSE_ALU) begin
//                        $display("            p=(%064h,%064h,%064h,%064h)",
//                            dut.px_alu, dut.py_alu, dut.pz_alu, dut.pt_alu);
//                        $display("            b=(%064h,%064h,%064h,%064h)",
//                            dut.bx_alu, dut.by_alu, dut.bz_alu, dut.bt_alu);
//                    end
//                end
//                if (dut.rst_n_alu !== 1'b1) begin
//                    alu_start_while_reset = alu_start_while_reset + 1;
//                    errors = errors + 1;
//                    $display("[ALU ERROR] START asserted while ALU held in reset!");
//                end
//            end
//            if (dut.alu_done === 1'b1 && !alu_previous_done) begin
//                alu_done_count = alu_done_count + 1;
//                alu_last_done_cycle = cycle_no;
//                if (VERBOSE_ALU || alu_done_count <= 4 || (alu_done_count % 32) == 0)
//                    $display("[ALU DONE ] T%0d cycle=%0d completed=%0d latency=%0d",
//                        test_id, cycle_no, alu_done_count,
//                        (alu_last_start_cycle >= 0) ? cycle_no - alu_last_start_cycle : -1);
//                if (alu_pending !== 1'b1) begin
//                    errors = errors + 1;
//                    $display("[ALU ERROR] alu_done without preceding pending ALU start");
//                end
//                alu_pending = 1'b0;
//            end
//            if (alu_pending && alu_previous_rst === 1'b1 &&
//                dut.rst_n_alu !== 1'b1) begin
//                alu_reset_during_operation = alu_reset_during_operation + 1;
//                $display("[ALU ERROR] Reset asserted DURING pending ALU operation at cycle=%0d", cycle_no);
//                alu_pending = 1'b0;
//            end
//            if (dut.rst_n_alu !== alu_previous_rst &&
//                (alu_start_count < 12 || alu_pending)) begin
//                $display("[ALU RESET] T%0d cycle=%0d rst_n_alu %b -> %b",
//                    test_id, cycle_no, alu_previous_rst, dut.rst_n_alu);
//            end
//            if (alu_pending) begin
//                alu_consecutive_pending = alu_consecutive_pending + 1;
//                if (alu_consecutive_pending > alu_max_pending)
//                    alu_max_pending = alu_consecutive_pending;
//            end
//            alu_previous_start = (dut.start_alu === 1'b1);
//            alu_previous_done  = (dut.alu_done === 1'b1);
//            alu_previous_rst   = dut.rst_n_alu;

//            // Compact heartbeat so no need to wait for 5 million cycles.
//            if (dut.state == CALC_Q_WAIT &&
//               (stage_cycles == 1000 || stage_cycles == 10000 ||
//                stage_cycles == 100000 || stage_cycles == 1000000)) begin
//                $display("[Q HEARTBEAT] cycles=%0d ALU starts=%0d dones=%0d reset-low=%0d pending=%b",
//                     stage_cycles, alu_start_count, alu_done_count,
//                     alu_reset_cycles, alu_pending);
//                if (stage_cycles == 10000 && alu_start_count == 0)
//                    $display("[Q HINT] No start_alu in first 10000 CALC_Q_WAIT cycles.");
//            end

//            // Log xung bắt đầu/hoàn tất của IP, không truy cập state nội bộ IP.
//            if (dut.start_mul)  $display("[PULSE] MUL.start at %0s", state_name(dut.state));
//            if (dut.start_SMSM) $display("[PULSE] SMSM.start at %0s", state_name(dut.state));
//            if (dut.start_inv)  $display("[PULSE] INV.start at %0s", state_name(dut.state));
//            if (dut.mul_done)   $display("[PULSE] MUL.done at %0s", state_name(dut.state));
//            if (dut.SMSM_done)  $display("[PULSE] SMSM.done at %0s", state_name(dut.state));
//            if (dut.inv_done)   $display("[PULSE] INV.done at %0s", state_name(dut.state));

//            // Kiểm tra reset đang bị assert trong lúc chờ IP hoàn tất.
//            if ((dut.state == CALC_P_WAIT || dut.state == CALC_QX_WAIT ||
//                 dut.state == CALC_QY_WAIT) && dut.rst_n_mul !== 1'b1 &&
//                 !warned_reset_mul) begin
//                warned_reset_mul = 1;
//                errors = errors + 1;
//                $display("[ROOT CAUSE] rst_n_mul=0 while waiting MUL! Submodule is held in reset.");
//                show_debug();
//            end
//            if (dut.state == CALC_Q_WAIT && dut.rst_n_SMSM !== 1'b1 &&
//                !warned_reset_smsm) begin
//                warned_reset_smsm = 1;
//                errors = errors + 1;
//                $display("[ROOT CAUSE] rst_n_SMSM=0 while waiting SMSM!");
//                show_debug();
//            end
//            if (dut.state == INV_Z_WAIT && dut.rst_n_inv !== 1'b1 &&
//                !warned_reset_inv) begin
//                warned_reset_inv = 1;
//                errors = errors + 1;
//                $display("[ROOT CAUSE] rst_n_inv=0 while waiting INV!");
//                show_debug();
//            end

//            if (((dut.state == CALC_P_WAIT || dut.state == CALC_QX_WAIT ||
//                  dut.state == CALC_QY_WAIT) && stage_cycles > MUL_LIMIT) ||
//                (dut.state == CALC_Q_WAIT && stage_cycles > SMSM_LIMIT) ||
//                (dut.state == INV_Z_WAIT && stage_cycles > INV_LIMIT) ||
//                cycle_no > TOTAL_LIMIT) begin
//                $display("[TIMEOUT] T%0d stuck at %0s for %0d cycles",
//                    test_id, state_name(dut.state), stage_cycles);
//                case (dut.state)
//                    CALC_P_WAIT:  $display("[HINT] Check modulo_mul pt=px*py, reset/start/done.");
//                    CALC_Q_WAIT:  $display("[HINT] Check Scalar_multi_SM + alu_point_core handshake.");
//                    INV_Z_WAIT:  $display("[HINT] Check invert reset/start/done.");
//                    CALC_QX_WAIT: $display("[HINT] Check modulo_mul result_x*a_inv.");
//                    CALC_QY_WAIT: $display("[HINT] Check modulo_mul result_y*a_inv.");
//                    default:      $display("[HINT] Inspect state transition/control logic.");
//                endcase
//                show_debug();
//                if (dut.state == CALC_Q_WAIT) show_alu_diagnosis();
//                $display("[SUMMARY] Checks=%0d Errors=%0d, terminated at first hang.",
//                    checks, errors+1);
//                $finish;
//            end
//            prev_state = dut.state;
//        end
//    end

//    task automatic run_case;
//        input integer id;
//        input [255:0] scalar;
//        input [255:0] exp_x;
//        input [255:0] exp_y;
//        integer timeout_ready;
//        integer errors_before;
//        integer integer_i;
//        begin
//            test_id = id;
//            alu_start_count = 0;
//            alu_done_count = 0;
//            alu_double_count = 0;
//            alu_add_count = 0;
//            expected_double = 0;
//            expected_add = 0;
//            active_high_bit = -1;
//            active_ones = 0;
//            // For MSB-first double-and-add with leading-1 optimization:
//            // double operations = bit_length(k)-1; additions = popcount(k)-1.
//            for (integer_i = 0; integer_i < 256; integer_i = integer_i + 1) begin
//                if (scalar[integer_i]) begin
//                    active_ones = active_ones + 1;
//                    active_high_bit = integer_i;
//                end
//            end
//            expected_double = active_high_bit;
//            expected_add = active_ones - 1;
//            alu_reset_cycles = 0;
//            alu_start_while_reset = 0;
//            alu_reset_during_operation = 0;
//            alu_last_start_cycle = -1;
//            alu_last_done_cycle = -1;
//            alu_consecutive_pending = 0;
//            alu_max_pending = 0;
//            alu_pending = 0;
//            alu_previous_start = 0;
//            alu_previous_done = 0;
//            alu_previous_rst = dut.rst_n_alu;
//            golden_x = exp_x;
//            golden_y = exp_y;
//            golden_pt = mod_mul(BX, BY);
//            warned_reset_mul = 0;
//            warned_reset_smsm = 0;
//            warned_reset_inv = 0;
//            cycle_no = 0;
//            stage_cycles = 0;
//            errors_before = errors;
//            prev_state = 4'hf;
//            $display("\n========== TEST %0d: k=%0d =========", id, scalar);

//            @(negedge clk);
//            k = scalar; px = BX; py = BY;
//            valid = 1; start = 0;
//            timeout_ready = 0;
//            // ready là output registered: chờ tới khi nhận ready=1.
//            while (ready !== 1'b1 && timeout_ready < 20) begin
//                @(negedge clk);
//                timeout_ready = timeout_ready + 1;
//            end
//            if (ready !== 1'b1) begin
//                $display("[FAIL] ready never asserted with valid nonzero inputs");
//                show_debug();
//                $finish;
//            end
//            active_case = 1;
//            @(negedge clk);
//            start = 1;
//            @(negedge clk);
//            start = 0;
//            valid = 0;

//            // done pulse occurs when state becomes IDLE after DONE_ST.
//            while (done !== 1'b1) @(negedge clk);
//            // Monitor already sampled post-NBA values at preceding posedge.
//            check_bool("[OPS] DOUBLE count", alu_double_count == expected_double);
//            check_bool("[OPS] ADD count", alu_add_count == expected_add);
//            check_bool("[OPS] ALU start/done matched", alu_start_count == alu_done_count);
//            check_bool("[OPS] ALU reset never active at START", alu_start_while_reset == 0);
//            check_bool("[OPS] ALU reset never interrupted operation", alu_reset_during_operation == 0);
//            if (errors == errors_before) begin
//                passed_cases = passed_cases + 1;
//                $display("[CASE PASS] T%0d, total cycles=%0d", id, cycle_no);
//            end else begin
//                failed_cases = failed_cases + 1;
//                $display("[CASE FAIL] T%0d, additional errors=%0d", id,
//                    errors-errors_before);
//            end
//            $display("[ALU SUMMARY] T%0d doubles=%0d/%0d adds=%0d/%0d starts=%0d dones=%0d resets-at-start=%0d",
//                test_id, alu_double_count, expected_double,
//                alu_add_count, expected_add,
//                alu_start_count, alu_done_count, alu_start_while_reset);
//            active_case = 0;
//            repeat (3) @(negedge clk);
//        end
//    endtask

//    initial begin
//        rst_n=0; start=0; valid=0; k=0; px=0; py=0;
//        test_id=0; checks=0; errors=0; passed_cases=0; failed_cases=0;
//        active_case=0; cycle_no=0; stage_cycles=0; prev_state=4'hf;
//        warned_reset_mul=0; warned_reset_smsm=0; warned_reset_inv=0;
//        // Enable only when your simulator supports $dumpfile/$dumpvars.
//        // $dumpfile("Point_Multi_ED25519_extended.vcd");
//        // $dumpvars(0, tb_Point_Multi_ED25519_extended);
//        repeat (5) @(negedge clk);
//        rst_n=1;
//        // Regression: k=1,2,3 used to PASS before the extension.
//        // Execute consecutive transactions with NO global reset between cases.
//        run_case(2,   256'd2,   X2, Y2);
//        run_case(1,   256'd1,   X1, Y1);
//        run_case(3,   256'd3,   X3, Y3);

//        // Required extension: consecutive doubles / adds.
//        run_case(4,   256'd4,   X_4,   Y_4);
//        run_case(5,   256'd5,   X_5,   Y_5);
//        run_case(7,   256'd7,   X_7,   Y_7);
//        run_case(15,  256'd15,  X_15,  Y_15);

//        // Further coverage: powers of two and long runs of 1 bits.
//        run_case(16,  256'd16,  X_16,  Y_16);
//        run_case(31,  256'd31,  X_31,  Y_31);
//        run_case(127, 256'd127, X_127, Y_127);
//        run_case(255, 256'd255, X_255, Y_255);

//        // Large scalars can increase XSim runtime substantially.
//        // To enable: set RUN_LONG=1 at top of this file.
//        if (RUN_LONG != 0) begin
//            run_case(1281, K_128PLUS1, X_128PLUS1, Y_128PLUS1);
//            run_case(2551, K_255PLUS1, X_255PLUS1, Y_255PLUS1);
//            run_case(999, K_RANDOM, X_RANDOM, Y_RANDOM);
//        end
//        $display("\n========== FINAL ==========");
//        $display("cases PASS=%0d FAIL=%0d; checkpoints=%0d errors=%0d",
//            passed_cases, failed_cases, checks, errors);
//        if ((failed_cases == 0) && (errors == 0))
//            $display("[ALL PASS] Extended Ed25519 point multiplication regression passed.");
//        else
//            $display("[FAIL] Extended Ed25519 point multiplication regression FAILED.");
//        $finish;
//    end
//endmodule
    reg clk=0, rst_n=0, start=0, valid=0;
    reg [255:0] k=0, px=0, py=0;
    wire [255:0] qx, qy;
    wire done, ready;
    integer total=0, pass=0, fail=0;
    localparam integer MAX_CYCLES = 2000000; // max wait per case
    localparam integer RUN_LONG = 1;         // 0: 19 quick tests; 1: +5 long tests

    localparam [255:0] BX = 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a;
    localparam [255:0] BY = 256'h6666666666666666666666666666666666666666666666666666666666666658;
    localparam [255:0] B2X = 256'h36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e;
    localparam [255:0] B2Y = 256'h2260cdf3092329c21da25ee8c9a21f5697390f51643851560e5f46ae6af8a3c9;
    localparam [255:0] B3X = 256'h67ae9c4a22928f491ff4ae743edac83a6343981981624886ac62485fd3f8e25c;
    localparam [255:0] B3Y = 256'h1267b1d177ee69aba126a18e60269ef79f16ec176724030402c3684878f5b4d4;

    Point_Multi_ED25519 dut (
        .clk(clk), .rst_n(rst_n), .start(start), .valid(valid),
        .k(k), .px(px), .py(py), .qx(qx), .qy(qy),
        .done(done), .ready(ready)
    );
    always #5 clk=~clk;

    // Only check final affine output qx/qy (no internal DUT probes).
    task run_case;
        input [8*24-1:0] label;
        input [255:0] kk, xx, yy, expx, expy;
        integer cycles;
        begin
            total=total+1;
            @(negedge clk); k=kk; px=xx; py=yy; valid=1; start=0;
            cycles=0;
            while (ready !== 1'b1 && cycles < 30) begin
                @(posedge clk); #1; cycles=cycles+1;
            end
            if (ready !== 1'b1) begin
                $display("[FAIL] %0s: ready timeout", label);
                $finish;
            end
            @(negedge clk); start=1;
            @(negedge clk); start=0; valid=0;
            cycles=0;
            while (done !== 1'b1 && cycles < MAX_CYCLES) begin
                @(posedge clk); #1; cycles=cycles+1;
            end
            if (done !== 1'b1) begin
                $display("[TIMEOUT] %0s after %0d cycles", label, cycles);
                $finish;
            end
            if (qx === expx && qy === expy) begin
                pass=pass+1;
                $display("[PASS] %0s (%0d cycles)", label, cycles);
            end else begin
                fail=fail+1;
                $display("[FAIL] %0s",label);
                $display("   qx got=%064h exp=%064h",qx,expx);
                $display("   qy got=%064h exp=%064h",qy,expy);
            end
        end
    endtask

    initial begin
        repeat (5) @(negedge clk);
        rst_n=1;
        // Expected coordinates generated with independent Ed25519 arithmetic.
        run_case("B, k=1", 256'd1, BX, BY,
                 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a, 256'h6666666666666666666666666666666666666666666666666666666666666658);
        run_case("B, k=2", 256'd2, BX, BY,
                 256'h36ab384c9f5a046c3d043b7d1833e7ac080d8e4515d7a45f83c5a14e2843ce0e, 256'h2260cdf3092329c21da25ee8c9a21f5697390f51643851560e5f46ae6af8a3c9);
        run_case("B, k=3", 256'd3, BX, BY,
                 256'h67ae9c4a22928f491ff4ae743edac83a6343981981624886ac62485fd3f8e25c, 256'h1267b1d177ee69aba126a18e60269ef79f16ec176724030402c3684878f5b4d4);
        run_case("B, k=4", 256'd4, BX, BY,
                 256'h203da8db56cff1468325d4b87a3520f91a739ec193ce1547493aa657c4c9f870, 256'h47d0e827cb1595e1470eb88580d5716c4cf22832ea2f0ff0df38ab61ca32112f);
        run_case("B, k=5", 256'd5, BX, BY,
                 256'h49fda73eade3587bfcef7cf7d12da5de5c2819f93e1be1a591409cc0322ef233, 256'h5f4825b298feae6fe02c6e148992466631282eca89430b5d10d21f83d676c8ed);
        run_case("B, k=7", 256'd7, BX, BY,
                 256'h14568685fcf4bd4ee9e3ee194b1d810783e809f3bbf1ce955855981af50e4107, 256'h31c563e32b47d52f87ce6468dd36ad41f0882b46f7abf23d12c4c4b59f4062b8);
        run_case("B, k=15", 256'd15, BX, BY,
                 256'h4f162deaec2ec435dc5ac6f95d20419ed9631374770189cb90617f3e66a18dc1, 256'h12cbfb2d04ff22f55162f70164d29331ace5af18a19a9aa1946d4cc4ad2e5cdf);
        run_case("B, k=16", 256'd16, BX, BY,
                 256'h23a4860627e53aeeb8e22b1508249c9109578d33e7bf237459b2596d6c28f9f8, 256'h709696f2827fc3729f980f2e3aad6e78b06a11ff8e079c27d87aab37c16727eb);
        run_case("B, k=31", 256'd31, BX, BY,
                 256'h38085391a0e2831f59c33fcce7591515784d359925f11ff958e0e4658efac0e9, 256'h42918001a829f49b5634e34ab7fac21b30e24660669ed91955cc31944a19e62a);
        run_case("B, k=127", 256'd127, BX, BY,
                 256'h735b64bb872606510e4e7d57833eb7ffdc4aa0dbaa242439806be68379f77cdd, 256'h384aaaee3ca7ba2436fcb65910859ca5ec30c10af11df7d777d287bc1a2bce2c);
        run_case("B, k=255", 256'd255, BX, BY,
                 256'h5174e33ffdf28a87184a4d6427d821cbaa3b88ac293a90ca7e1eeae8c5050b16, 256'h315ca6bc8e35e4a3d06f89e1db1575b16197963ee8e64746fa998ccd403561cc);
        run_case("B, k=256", 256'd256, BX, BY,
                 256'h5e7e07ed4e1decbfe6e9cbc126905449d4b578fbb561576d20b8bcdd0cc2a556, 256'h0f55755c51f102796bf5ebaa81d3260e7d1b3d9ac127d9a80e142031566cf6c7);
        run_case("B, k=257", 256'd257, BX, BY,
                 256'h6e8ce4ff435b7f78fd959b956096f7b9dda31809cd4e948377ee6f3f24c4d7ce, 256'h20ab65593c0c68857a0a0cb0a22f1625fb81e49ff0bef0b2ccabc8e4eaba452c);
        run_case("B, k=65535", 256'd65535, BX, BY,
                 256'h7e1caa750b8a2c0bd9ab26648727c8a0e9e1bc7f0ac8749b64a4e88a8ab86a2f, 256'h5c94b49d07988829958f8f4d16acc498e4b5ba72cf51adad7a19c41aa238037c);
        run_case("B, k=2^32+5", 256'h0000000000000000000000000000000000000000000000000000000100000005, BX, BY,
                 256'h609e3ad44df3746e19ef63f755060241e22bc96fa643578bb1b8965eff8162f9, 256'h146f8d59ea42e33fc0243e075cf00ef499ef81b23758020a1ad6a22020fed583);
        run_case("B, k=2^64+7", 256'h0000000000000000000000000000000000000000000000010000000000000007, BX, BY,
                 256'h019ea9e5805c484100949afefb883936326063923f34b8ce6e88455468b53914, 256'h2b3c70de03ca054f0f50cfa172c2aa40415fbb016fbe6b0715df3e1212edd70e);
        run_case("2B, k=3", 256'd3, B2X, B2Y,
                 256'h4c9797ba7a45601c62aeacc0dd0a29bea1e599826c7b4427783a741a7dcbf23d, 256'h054de3fc2886d8a11db709a7fd4f7d77f9417c06944d6b60c1d27ad0f9497ef4);
        run_case("2B, k=15", 256'd15, B2X, B2Y,
                 256'h7e40e656adbd6aa0cb203f337dd19d441336400f59e341c837ebd71b7881e1e4, 256'h342740ff1d2cc47aefed1e9b1c1b387cad3ff6f842729e20a414557407d2f3e4);
        run_case("3B, k=7", 256'd7, B3X, B3Y,
                 256'h6f0ac78e5eb90e87958588f9d47541edf252cb1dde3d073cc45e3e7ef9365716, 256'h6628d116b7975ae5f323e5ddf4f8cc35ae06d5c5c7d8a56effc66051336d289e);
        if (RUN_LONG) begin
        run_case("B, k=2^128+1", 256'h0000000000000000000000000000000100000000000000000000000000000001, BX, BY,
                 256'h6e64e5552b88e48f8ab3c1be8cc36053b0e6ec0831ecbce6fbe2fd29680c969a, 256'h383c510fa4cb58be6a9dfc9339b85145363911589ec5521025352a647bafd09b);
        run_case("B, k=2^255+1", 256'h8000000000000000000000000000000000000000000000000000000000000001, BX, BY,
                 256'h7a8553ada43394466e33b2b9f230812e993de3e3428bf08a322a0846b2fbc6d8, 256'h274a7f39b56dff94e87f869f877141b34e840e6fe1b465f6345051588f3f7abe);
        run_case("B, random 256b", 256'hf5a90c1d7e2b6f439ac0d812ee470b35c6f1a8d29b7e54c03a9fd682105ceb77, BX, BY,
                 256'h02802fef02294a2450f9ad3690265f6333963d9fabe76d61ef8d746d771ca55d, 256'h60f2433a8e4ca70e6a31f6817d2749fc977e466182f96eb63d2001301859b09f);
        run_case("B, k=group_order", 256'h1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed, BX, BY,
                 256'h0000000000000000000000000000000000000000000000000000000000000000, 256'h0000000000000000000000000000000000000000000000000000000000000001);
        run_case("B, k=order+1", 256'h1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ee, BX, BY,
                 256'h216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a, 256'h6666666666666666666666666666666666666666666666666666666666666658);
        end
        $display("\n========== RESULT: %0d/%0d PASS, %0d FAIL ==========",pass,total,fail);
        $finish;
    end
endmodule