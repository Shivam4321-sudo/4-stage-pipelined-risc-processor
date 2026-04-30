// ============================================================
//  Testbench — processor_top
//  Author : Shivam Sharma | Dec 2025
//  Tool   : Xilinx Vivado Simulator
//
//  Test Program loaded via imem_init.hex:
//    1. ADDI  r1, r0, 5      ; r1 = 5
//    2. ADDI  r2, r0, 3      ; r2 = 3
//    3. ADD   r3, r1, r2     ; r3 = 8   (forwarding test)
//    4. SUB   r4, r3, r1     ; r4 = 3   (forwarding test)
//    5. SW    r3, 0(r0)      ; mem[0] = 8
//    6. LW    r5, 0(r0)      ; r5 = 8   (load-use hazard test)
//    7. ADD   r6, r5, r2     ; r6 = 11
//    8. BEQ   r1, r2, +2     ; not taken (5 != 3)
//    9. ADDI  r7, r0, 99     ; r7 = 99
// ============================================================
`timescale 1ns / 1ps

module tb_processor_top;

    // ── DUT signals ──────────────────────────────────────────
    reg  clk;
    reg  rst;

    // ── Instantiate DUT ──────────────────────────────────────
    processor_top dut (
        .clk (clk),
        .rst (rst)
    );

    // ── Clock generation (10 ns period) ──────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Waveform dump ─────────────────────────────────────────
    initial begin
        $dumpfile("processor_top.vcd");
        $dumpvars(0, tb_processor_top);
    end

    // ── Stimulus ──────────────────────────────────────────────
    initial begin
        $display("========================================");
        $display(" 4-Stage Pipelined RISC Processor Test ");
        $display(" Author: Shivam Sharma | Dec 2025       ");
        $display("========================================");

        // Assert reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset de-asserted. Pipeline starting.", $time);

        // Run for enough cycles to complete all instructions
        repeat(30) @(posedge clk);

        $display("[%0t] Simulation complete.", $time);
        $display("========================================");

        // ── Register file readout via hierarchical path ──────
        $display("--- Register File Snapshot ---");
        $display("r0  = %0d (expected:  0)", dut.u_id_stage.regfile[0]);
        $display("r1  = %0d (expected:  5)", dut.u_id_stage.regfile[1]);
        $display("r2  = %0d (expected:  3)", dut.u_id_stage.regfile[2]);
        $display("r3  = %0d (expected:  8)", dut.u_id_stage.regfile[3]);
        $display("r4  = %0d (expected:  3)", dut.u_id_stage.regfile[4]);
        $display("r5  = %0d (expected:  8)", dut.u_id_stage.regfile[5]);
        $display("r6  = %0d (expected: 11)", dut.u_id_stage.regfile[6]);
        $display("r7  = %0d (expected: 99)", dut.u_id_stage.regfile[7]);

        $display("--- Data Memory Snapshot ---");
        $display("mem[0] = %0d (expected: 8)", dut.u_wb_stage.dmem[0]);

        // ── Pass/Fail checks ─────────────────────────────────
        $display("--- Verification ---");
        if (dut.u_id_stage.regfile[1] === 32'd5)
            $display("PASS: r1 = 5");
        else
            $display("FAIL: r1 = %0d (expected 5)", dut.u_id_stage.regfile[1]);

        if (dut.u_id_stage.regfile[3] === 32'd8)
            $display("PASS: r3 = 8 (forwarding verified)");
        else
            $display("FAIL: r3 = %0d (expected 8)", dut.u_id_stage.regfile[3]);

        if (dut.u_id_stage.regfile[5] === 32'd8)
            $display("PASS: r5 = 8 (load-use hazard verified)");
        else
            $display("FAIL: r5 = %0d (expected 8)", dut.u_id_stage.regfile[5]);

        if (dut.u_id_stage.regfile[6] === 32'd11)
            $display("PASS: r6 = 11");
        else
            $display("FAIL: r6 = %0d (expected 11)", dut.u_id_stage.regfile[6]);

        if (dut.u_id_stage.regfile[7] === 32'd99)
            $display("PASS: r7 = 99 (BEQ not-taken verified)");
        else
            $display("FAIL: r7 = %0d (expected 99)", dut.u_id_stage.regfile[7]);

        if (dut.u_wb_stage.dmem[0] === 32'd8)
            $display("PASS: mem[0] = 8 (store/load verified)");
        else
            $display("FAIL: mem[0] = %0d (expected 8)", dut.u_wb_stage.dmem[0]);

        $display("========================================");
        $finish;
    end

    // ── Timeout watchdog ─────────────────────────────────────
    initial begin
        #10000;
        $display("TIMEOUT — simulation exceeded 10000 ns");
        $finish;
    end

endmodule
