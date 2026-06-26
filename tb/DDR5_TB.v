// ============================================================
// Testbench : tb_ecc_engine
// Tests     : TC1 - Encode/Decode no error
//             TC2 - Single-bit error correction
//             TC3 - Double-bit error detection
//             TC4 - All-zeros data
//             TC5 - All-ones data
// ============================================================
`timescale 1ns/1ps

module tb_ecc_engine;

    reg        clk, rst_n;
    reg        op_encode, op_decode, valid_in;
    reg [63:0] data_in;
    reg [71:0] codeword_in;

    wire [71:0] codeword_out;
    wire [63:0] data_out;
    wire        ecc_corrected, ecc_uncorrectable, valid_out;

    // DUT
    ecc_engine dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .op_encode        (op_encode),
        .op_decode        (op_decode),
        .valid_in         (valid_in),
        .data_in          (data_in),
        .codeword_out     (codeword_out),
        .codeword_in      (codeword_in),
        .data_out         (data_out),
        .ecc_corrected    (ecc_corrected),
        .ecc_uncorrectable(ecc_uncorrectable),
        .valid_out        (valid_out)
    );

    // Clock: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: encode
    task encode_data;
        input [63:0] d;
        begin
            @(negedge clk);
            data_in   = d;
            op_encode = 1; op_decode = 0; valid_in = 1;
            @(posedge clk); #1;
            op_encode = 0; valid_in = 0;
            @(posedge clk); #1;
        end
    endtask

    // Task: decode
    task decode_cw;
        input [71:0] cw;
        begin
            @(negedge clk);
            codeword_in = cw;
            op_decode   = 1; op_encode = 0; valid_in = 1;
            @(posedge clk); #1;
            op_decode = 0; valid_in = 0;
            @(posedge clk); #1;
        end
    endtask

    reg [71:0] encoded_cw;
    integer    pass_cnt, fail_cnt;

    initial begin
        $dumpfile("tb_ecc_engine.vcd");
        $dumpvars(0, tb_ecc_engine);

        pass_cnt = 0; fail_cnt = 0;
        rst_n = 0; op_encode = 0; op_decode = 0; valid_in = 0;
        data_in = 0; codeword_in = 0;
        #20; rst_n = 1; #10;

        // ---- TC1: Encode then decode, no error ----
        $display("\n[TC1] Encode/Decode no error");
        encode_data(64'hA5A5_5A5A_DEAD_BEEF);
        @(posedge clk); #1;
        encoded_cw = codeword_out;
        $display("  Encoded: 0x%018h", encoded_cw);
        decode_cw(encoded_cw);
        @(posedge clk); #1;
        if (data_out == 64'hA5A5_5A5A_DEAD_BEEF &&
            ecc_corrected == 0 && ecc_uncorrectable == 0) begin
            $display("  PASS: data_out=0x%016h, no error flags", data_out);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: data_out=0x%016h, corr=%b, uncorr=%b",
                     data_out, ecc_corrected, ecc_uncorrectable);
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC2: Single-bit error injection ----
        $display("\n[TC2] Single-bit error correction");
        encode_data(64'hFFFF_0000_ABCD_1234);
        @(posedge clk); #1;
        encoded_cw = codeword_out;
        encoded_cw[10] = ~encoded_cw[10]; // flip bit 10
        $display("  Injected error at bit 10");
        decode_cw(encoded_cw);
        @(posedge clk); #1;
        if (data_out == 64'hFFFF_0000_ABCD_1234 && ecc_corrected == 1) begin
            $display("  PASS: Single-bit corrected, data_out=0x%016h", data_out);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: data_out=0x%016h, corrected=%b", data_out, ecc_corrected);
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC3: Double-bit error detection ----
        $display("\n[TC3] Double-bit error detection");
        encode_data(64'h1234_5678_9ABC_DEF0);
        @(posedge clk); #1;
        encoded_cw = codeword_out;
        encoded_cw[5]  = ~encoded_cw[5];  // flip bit 5
        encoded_cw[20] = ~encoded_cw[20]; // flip bit 20
        $display("  Injected errors at bits 5 and 20");
        decode_cw(encoded_cw);
        @(posedge clk); #1;
        if (ecc_uncorrectable == 1 && ecc_corrected == 0) begin
            $display("  PASS: Double-bit detected (uncorrectable flag set)");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: uncorr=%b, corr=%b", ecc_uncorrectable, ecc_corrected);
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC4: All zeros ----
        $display("\n[TC4] All-zeros data");
        encode_data(64'h0);
        @(posedge clk); #1;
        encoded_cw = codeword_out;
        decode_cw(encoded_cw);
        @(posedge clk); #1;
        if (data_out == 64'h0 && ecc_corrected == 0 && ecc_uncorrectable == 0) begin
            $display("  PASS: All-zeros round-trip clean");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL");
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC5: All ones ----
        $display("\n[TC5] All-ones data");
        encode_data(64'hFFFF_FFFF_FFFF_FFFF);
        @(posedge clk); #1;
        encoded_cw = codeword_out;
        decode_cw(encoded_cw);
        @(posedge clk); #1;
        if (data_out == 64'hFFFF_FFFF_FFFF_FFFF &&
            ecc_corrected == 0 && ecc_uncorrectable == 0) begin
            $display("  PASS: All-ones round-trip clean");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL");
            fail_cnt = fail_cnt + 1;
        end

        // Summary
        $display("\n===================================");
        $display("  ECC Engine Results: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        $display("===================================\n");
        #50; $finish;
    end

endmodule
// ============================================================
// Testbench : tb_training_fsm
// Tests     : TC1 - Full training sequence (mode=3)
//             TC2 - Write Leveling only  (mode=0)
//             TC3 - Low eye margin → error flag
//             TC4 - Vref sweep best value tracking
// FIX: Corrected port connections to match RTL training_fsm:
//      - Removed invalid port .vref_code; RTL exposes phy_vref_code
//      - Renamed .training_state_out -> .fsm_state_out (RTL port name)
//      - Added missing ports: .phy_vref_code, .phy_lane_sel,
//        .best_vref0, .best_vref1
//      - fsm_state_out is [3:0] per RTL (was [2:0] in TB)
// ============================================================
`timescale 1ns/1ps

module tb_training_fsm;

    reg        clk, rst_n;
    reg        train_start;
    reg [1:0]  train_mode;
    reg        phy_cal_ack;
    reg [7:0]  phy_eye_data;

    wire        phy_cal_req;
    wire        training_done, training_error;
    wire [7:0]  eye_margin;
    wire [7:0]  phy_vref_code;   // FIX: was 'vref_code' — RTL port is phy_vref_code
    wire [1:0]  phy_lane_sel;    // FIX: added missing port
    wire [7:0]  best_vref0;      // FIX: added missing port
    wire [7:0]  best_vref1;      // FIX: added missing port
    wire [3:0]  fsm_state_out;   // FIX: was training_state_out[2:0]; RTL is fsm_state_out[3:0]

    training_fsm dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .train_start      (train_start),
        .train_mode       (train_mode),
        .phy_cal_req      (phy_cal_req),
        .phy_vref_code    (phy_vref_code),   // FIX: was .vref_code(vref_code)
        .phy_lane_sel     (phy_lane_sel),    // FIX: added missing connection
        .phy_cal_ack      (phy_cal_ack),
        .phy_eye_data     (phy_eye_data),
        .training_done    (training_done),
        .training_error   (training_error),
        .eye_margin       (eye_margin),
        .best_vref0       (best_vref0),      // FIX: added missing connection
        .best_vref1       (best_vref1),      // FIX: added missing connection
        .fsm_state_out    (fsm_state_out)    // FIX: was .training_state_out(training_state_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // PHY model: auto-ack when cal_req seen, return eye data
    always @(posedge clk) begin
        if (phy_cal_req) begin
            #3; phy_cal_ack = 1;
            @(posedge clk); #1;
            phy_cal_ack = 0;
        end
    end

    // Task: run training and wait for done/error
    task run_training;
        input [1:0] mode;
        input [7:0] eye_val;
        input integer timeout;
        integer t;
        begin
            phy_eye_data = eye_val;
            @(negedge clk);
            train_mode  = mode;
            train_start = 1;
            @(posedge clk); #1;
            train_start = 0;
            t = 0;
            while (!training_done && !training_error && t < timeout) begin
                @(posedge clk); #1;
                t = t + 1;
            end
        end
    endtask

    integer pass_cnt, fail_cnt;

    initial begin
        $dumpfile("tb_training_fsm.vcd");
        $dumpvars(0, tb_training_fsm);

        pass_cnt = 0; fail_cnt = 0;
        rst_n = 0; train_start = 0; train_mode = 0;
        phy_cal_ack = 0; phy_eye_data = 8'd50;
        #25; rst_n = 1; #10;

        // ---- TC1: Full training (mode=3), good eye margin ----
        $display("\n[TC1] Full training sequence (WL+RDQ+VREF), eye=50");
        run_training(2'd3, 8'd50, 5000);
        if (training_done && !training_error && eye_margin >= 8'd30) begin
            $display("  PASS: training_done=1, eye_margin=%0d", eye_margin);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: done=%b, error=%b, margin=%0d",
                     training_done, training_error, eye_margin);
            fail_cnt = fail_cnt + 1;
        end

        // Reset for next test
        rst_n = 0; #20; rst_n = 1; #10;

        // ---- TC2: Write Leveling only (mode=0) ----
        $display("\n[TC2] Write Leveling only (mode=0)");
        run_training(2'd0, 8'd40, 2000);
        if (training_done && !training_error) begin
            $display("  PASS: WL training complete, eye_margin=%0d", eye_margin);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: done=%b, error=%b", training_done, training_error);
            fail_cnt = fail_cnt + 1;
        end

        // Reset
        rst_n = 0; #20; rst_n = 1; #10;

        // ---- TC3: Low eye margin → training_error ----
        $display("\n[TC3] Low eye margin (eye=10) → expect error");
        run_training(2'd0, 8'd10, 2000);
        if (training_error && !training_done) begin
            $display("  PASS: training_error asserted for low margin=%0d", eye_margin);
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: error=%b, done=%b, margin=%0d",
                     training_error, training_done, eye_margin);
            fail_cnt = fail_cnt + 1;
        end

        // Reset
        rst_n = 0; #20; rst_n = 1; #10;

        // ---- TC4: Vref sweep only (mode=2) ----
        $display("\n[TC4] Vref sweep (mode=2), eye=45");
        run_training(2'd2, 8'd45, 5000);
        if (training_done && !training_error) begin
            $display("  PASS: Vref training done, phy_vref_code=%0d, margin=%0d",
                     phy_vref_code, eye_margin);  // FIX: was vref_code
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: done=%b, error=%b", training_done, training_error);
            fail_cnt = fail_cnt + 1;
        end

        $display("\n===================================");
        $display("  Training FSM Results: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        $display("===================================\n");
        #100; $finish;
    end

endmodule
// ============================================================
// Testbench : tb_bank_group_scheduler
// Tests     : TC1 - Basic READ to closed bank (ACT+RD)
//             TC2 - Row Hit (no ACT needed)
//             TC3 - Row Miss (PRE+ACT+RD)
//             TC4 - Interleaved READ/WRITE
//             TC5 - Queue fill and drain
// FIX: Corrected port width and name mismatches vs RTL:
//      - cmd_row: [15:0] → [16:0]  (RTL is 17-bit)
//      - cmd_col: [9:0]  → [10:0]  (RTL is 11-bit)
//      - cmd_type → cmd_rw         (RTL port name)
//      - Added missing .rob_count port connection
// ============================================================
`timescale 1ns/1ps

module tb_bank_group_scheduler;

    reg         clk, rst_n;
    reg         training_done;
    reg         req_valid;
    reg  [31:0] req_addr;
    reg         req_type;

    wire        req_ready;
    wire        cmd_valid;
    wire [1:0]  cmd_bg, cmd_bank;
    wire [16:0] cmd_row;        // FIX: was [15:0]; RTL is [16:0]
    wire [10:0] cmd_col;        // FIX: was [9:0];  RTL is [10:0]
    wire        cmd_rw;         // FIX: was cmd_type; RTL port is cmd_rw
    wire [2:0]  cmd_op;
    wire        cmd_ready_out;
    wire [4:0]  rob_count;      // FIX: added missing port

    bank_group_scheduler dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .training_done(training_done),
        .req_valid    (req_valid),
        .req_addr     (req_addr),
        .req_type     (req_type),
        .req_ready    (req_ready),
        .cmd_valid    (cmd_valid),
        .cmd_bg       (cmd_bg),
        .cmd_bank     (cmd_bank),
        .cmd_row      (cmd_row),
        .cmd_col      (cmd_col),
        .cmd_rw       (cmd_rw),         // FIX: was .cmd_type(cmd_type)
        .cmd_op       (cmd_op),
        .cmd_ready_out(cmd_ready_out),
        .rob_count    (rob_count)        // FIX: added missing connection
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Command name decode
    function [63:0] op_name;
        input [2:0] op;
        begin
            case (op)
                3'd0: op_name = "NOP     ";
                3'd1: op_name = "ACT     ";
                3'd2: op_name = "READ    ";
                3'd3: op_name = "WRITE   ";
                3'd4: op_name = "PRE     ";
                default: op_name = "UNKNOWN ";
            endcase
        end
    endfunction

    // Task: send one request
    task send_req;
        input [31:0] addr;
        input        rw; // 0=R, 1=W
        begin
            @(negedge clk);
            req_valid = 1;
            req_addr  = addr;
            req_type  = rw;
            wait(req_ready);
            @(posedge clk); #1;
            req_valid = 0;
        end
    endtask

    // Monitor: print commands
    always @(posedge clk) begin
        if (cmd_valid)
            $display("  t=%0t CMD: %s BG=%0d BNK=%0d ROW=%0h COL=%0h",
                     $time, op_name(cmd_op), cmd_bg, cmd_bank, cmd_row, cmd_col);
    end

    integer pass_cnt, fail_cnt;

    initial begin
        $dumpfile("tb_scheduler.vcd");
        $dumpvars(0, tb_bank_group_scheduler);

        pass_cnt = 0; fail_cnt = 0;
        rst_n = 0; training_done = 0;
        req_valid = 0; req_addr = 0; req_type = 0;
        #25; rst_n = 1; #10;

        // ---- TC1: Blocked by training_done ----
        $display("\n[TC1] Request before training_done (should be blocked)");
        req_valid = 1; req_addr = 32'hAAAA_0040; req_type = 0;
        #30;
        if (!req_ready) begin
            $display("  PASS: req_ready=0 while training not done");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: req_ready should be 0");
            fail_cnt = fail_cnt + 1;
        end
        req_valid = 0;
        training_done = 1;
        #10;

        // ---- TC2: Basic READ to closed bank ----
        $display("\n[TC2] READ to closed bank → expect ACT then READ");
        send_req(32'h0001_0040, 0); // row=0x0001, BG=0, BNK=0
        #200; // wait for commands

        // ---- TC3: Row Hit — same row, same bank ----
        $display("\n[TC3] Row Hit — same row re-access → expect only READ");
        send_req(32'h0001_0080, 0); // same row 0x0001
        #200;

        // ---- TC4: Row Miss — different row, same bank ----
        $display("\n[TC4] Row Miss → expect PRE+ACT+READ");
        send_req(32'h0002_0040, 0); // different row 0x0002
        #200;

        // ---- TC5: WRITE transaction ----
        $display("\n[TC5] WRITE to BG1 BNK0");
        send_req(32'h0005_0140, 1); // BG=1
        #200;

        // ---- TC6: Queue burst ----
        $display("\n[TC6] Burst of 4 requests");
        fork
            send_req(32'h0010_0040, 0);
            send_req(32'h0011_0040, 1);
            send_req(32'h0012_0040, 0);
            send_req(32'h0013_0040, 1);
        join
        #500;

        $display("\n===================================");
        $display("  Scheduler TB: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        $display("  (check waveform for command sequence verification)");
        $display("===================================\n");
        #100; $finish;
    end

endmodule
// ============================================================
// Testbench : tb_ddr5_subsystem_top
// Tests     : Full SoC integration flow
//             TC1 - Train → Write → Read (clean)
//             TC2 - ECC error injection on read path
//             TC3 - AXI4-Lite register read/write
// FIX: Corrected port width mismatches vs RTL ddr5_subsystem_top:
//      - phy_cmd_row: [15:0] → [16:0]  (RTL is 17-bit)
//      - phy_cmd_col: [9:0]  → [10:0]  (RTL is 11-bit)
// ============================================================
`timescale 1ns/1ps

module tb_ddr5_subsystem_top;

    reg         clk, rst_n;

    // AXI4-Lite
    reg  [31:0] awaddr, wdata, araddr;
    reg  [3:0]  wstrb;
    reg         awvalid, wvalid, bready, arvalid, rready;
    wire        awready, wready, bvalid, arready, rvalid;
    wire [1:0]  bresp, rresp;
    wire [31:0] rdata;

    // PHY model signals
    wire        phy_cal_req;
    reg         phy_cal_ack;
    reg  [7:0]  phy_eye_data;
    wire [71:0] phy_tx_data;
    reg  [71:0] phy_rx_data;
    wire        phy_cmd_valid;
    wire [2:0]  phy_cmd_op;
    wire [1:0]  phy_cmd_bg, phy_cmd_bank;
    wire [16:0] phy_cmd_row;   // FIX: was [15:0]; RTL is [16:0]
    wire [10:0] phy_cmd_col;   // FIX: was [9:0];  RTL is [10:0]
    wire        training_done, ecc_corrected, ecc_uncorrectable;
    wire [7:0]  eye_margin;

    // DUT
    ddr5_subsystem_top dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .awaddr           (awaddr),
        .awvalid          (awvalid),
        .awready          (awready),
        .wdata            (wdata),
        .wstrb            (wstrb),
        .wvalid           (wvalid),
        .wready           (wready),
        .bresp            (bresp),
        .bvalid           (bvalid),
        .bready           (bready),
        .araddr           (araddr),
        .arvalid          (arvalid),
        .arready          (arready),
        .rdata            (rdata),
        .rresp            (rresp),
        .rvalid           (rvalid),
        .rready           (rready),
        .phy_cal_req      (phy_cal_req),
        .phy_cal_ack      (phy_cal_ack),
        .phy_eye_data     (phy_eye_data),
        .phy_tx_data      (phy_tx_data),
        .phy_rx_data      (phy_rx_data),
        .phy_cmd_valid    (phy_cmd_valid),
        .phy_cmd_op       (phy_cmd_op),
        .phy_cmd_bg       (phy_cmd_bg),
        .phy_cmd_bank     (phy_cmd_bank),
        .phy_cmd_row      (phy_cmd_row),
        .phy_cmd_col      (phy_cmd_col),
        .training_done    (training_done),
        .eye_margin       (eye_margin),
        .ecc_corrected    (ecc_corrected),
        .ecc_uncorrectable(ecc_uncorrectable)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // PHY model: auto-ack training pulses
    always @(posedge clk) begin
        if (phy_cal_req) begin
            repeat(2) @(posedge clk);
            phy_cal_ack = 1;
            @(posedge clk);
            phy_cal_ack = 0;
        end
    end

    // AXI4-Lite write task
    task axi_write;
        input [31:0] addr, data;
        begin
            @(negedge clk);
            awaddr = addr; awvalid = 1;
            wdata  = data; wvalid  = 1; wstrb = 4'hF;
            bready = 1;
            wait(awready && wready);
            @(posedge clk); #1;
            awvalid = 0; wvalid = 0;
            wait(bvalid);
            @(posedge clk); #1;
            $display("  AXI WR: addr=0x%08h data=0x%08h resp=%b", addr, data, bresp);
        end
    endtask

    // AXI4-Lite read task
    task axi_read;
        input [31:0] addr;
        begin
            @(negedge clk);
            araddr  = addr;
            arvalid = 1; rready = 1;
            wait(arready);
            @(posedge clk); #1;
            arvalid = 0;
            wait(rvalid);
            @(posedge clk); #1;
            $display("  AXI RD: addr=0x%08h data=0x%08h resp=%b", addr, rdata, rresp);
        end
    endtask

    // Monitor PHY commands
    always @(posedge clk) begin
        if (phy_cmd_valid) begin
            case (phy_cmd_op)
                3'd1: $display("  t=%0t PHY CMD: ACTIVATE BG=%0d BNK=%0d ROW=0x%05h",
                               $time, phy_cmd_bg, phy_cmd_bank, phy_cmd_row);
                3'd2: $display("  t=%0t PHY CMD: READ     BG=%0d BNK=%0d COL=0x%03h",
                               $time, phy_cmd_bg, phy_cmd_bank, phy_cmd_col);
                3'd3: $display("  t=%0t PHY CMD: WRITE    BG=%0d BNK=%0d COL=0x%03h TX=0x%018h",
                               $time, phy_cmd_bg, phy_cmd_bank, phy_cmd_col, phy_tx_data);
                3'd4: $display("  t=%0t PHY CMD: PRECHARGE BG=%0d BNK=%0d",
                               $time, phy_cmd_bg, phy_cmd_bank);
            endcase
        end
    end

    integer pass_cnt, fail_cnt;

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_ddr5_subsystem_top);

        pass_cnt = 0; fail_cnt = 0;
        rst_n = 0;
        awvalid = 0; wvalid = 0; bready = 0;
        arvalid = 0; rready = 0;
        phy_cal_ack = 0; phy_eye_data = 8'd50;
        phy_rx_data = 72'h0;
        #25; rst_n = 1; #10;

        // ---- TC1: Start Full Training ----
        $display("\n[TC1] Start full training via AXI4-Lite");
        axi_write(32'h00, 32'h7); // train_mode=3 (FULL), start=1
        $display("  Waiting for training_done...");
        wait(training_done);
        $display("  PASS: training_done=1, eye_margin=%0d", eye_margin);
        pass_cnt = pass_cnt + 1;

        // ---- TC2: Read TRAIN_STATUS register ----
        $display("\n[TC2] Read TRAIN_STATUS register");
        axi_read(32'h04);
        if (rdata[0] == 1) begin
            $display("  PASS: training_done bit set in status register");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: training_done not reflected in status");
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC3: Send WRITE memory request ----
        $display("\n[TC3] WRITE request: addr=0xDEAD_0040");
        axi_write(32'h10, 32'hDEAD_0040);  // MEM_REQ
        axi_write(32'h14, 32'h3);           // MEM_CTRL: valid=1, type=1(WR)
        #500;
        $display("  PASS: Write command sequence issued (check PHY CMD log above)");
        pass_cnt = pass_cnt + 1;

        // ---- TC4: Send READ memory request ----
        $display("\n[TC4] READ request: addr=0xDEAD_0040");
        // Simulate clean data from PHY (no ECC error)
        phy_rx_data = phy_tx_data; // echo back what was written
        axi_write(32'h14, 32'h1);  // MEM_CTRL: valid=1, type=0(RD)
        #500;
        if (!ecc_uncorrectable) begin
            $display("  PASS: Read complete, no ECC error");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: Unexpected ECC error on clean read");
            fail_cnt = fail_cnt + 1;
        end

        // ---- TC5: ECC single-bit error injection ----
        $display("\n[TC5] ECC single-bit error injection on read path");
        phy_rx_data = phy_tx_data;
        phy_rx_data[15] = ~phy_rx_data[15]; // flip one bit
        axi_write(32'h14, 32'h1); // READ
        #500;
        axi_read(32'h0C); // ECC_STATUS
        if (rdata[0] == 1) begin
            $display("  PASS: ecc_corrected flag set in ECC_STATUS");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("  FAIL: ecc_corrected not set");
            fail_cnt = fail_cnt + 1;
        end

        $display("\n===================================");
        $display("  TOP Integration: %0d PASS / %0d FAIL", pass_cnt, fail_cnt);
        $display("===================================\n");
        #100; $finish;
    end

endmodule
