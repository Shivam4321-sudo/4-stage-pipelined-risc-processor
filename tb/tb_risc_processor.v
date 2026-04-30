// =============================================================================
// Module      : tb_risc_processor.v
// Project     : 4-Stage Pipelined RISC Processor — Testbench
// Author      : Shivam Sharma
// Description : Top-level testbench for the full pipeline processor.
//               Tests: ADD, SUB, ADDI, LW, SW, BEQ, forwarding, stall.
// Simulator   : Xilinx Vivado XSim / ModelSim / Icarus Verilog
// =============================================================================

`timescale 1ns / 1ps

module tb_risc_processor;

    // ── DUT signals ──────────────────────────────────────────────────────────
    reg         clk, rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_reg_write_data;
    wire [4:0]  debug_rd;

    // ── Instantiate DUT ──────────────────────────────────────────────────────
    risc_processor dut (
        .clk                  (clk),
        .rst                  (rst),
        .debug_pc             (debug_pc),
        .debug_alu_result     (debug_alu_result),
        .debug_reg_write_data (debug_reg_write_data),
        .debug_rd             (debug_rd)
    );

    // ── Clock Generation: 10 ns period (100 MHz) ─────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Waveform Dump ─────────────────────────────────────────────────────────
    initial begin
        $dumpfile("tb_risc_processor.vcd");
        $dumpvars(0, tb_risc_processor);
    end

    // ── Test Sequence ─────────────────────────────────────────────────────────
    integer cycle_count;

    initial begin
        $display("=======================================================");
        $display("  4-Stage Pipelined RISC Processor — Simulation Start  ");
        $display("  Author: Shivam Sharma                                 ");
        $display("=======================================================");

        // Reset for 4 cycles
        rst = 1;
        repeat(4) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset de-asserted. Pipeline starting.", $time);

        // Run for 100 cycles and monitor
        for (cycle_count = 0; cycle_count < 100; cycle_count = cycle_count + 1) begin
            @(posedge clk);
            #1; // Small delay to let outputs settle
            $display("[Cycle %3d | PC=0x%08h] ALU=0x%08h  WB: R%0d <= 0x%08h",
                     cycle_count, debug_pc,
                     debug_alu_result,
                     debug_rd, debug_reg_write_data);
        end

        $display("=======================================================");
        $display("  Simulation Complete — Check waveforms in Vivado       ");
        $display("=======================================================");
        $finish;
    end

    // ── Timeout watchdog ──────────────────────────────────────────────────────
    initial begin
        #10000;
        $display("[ERROR] Simulation timeout!");
        $finish;
    end

endmodule
