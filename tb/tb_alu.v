// =============================================================================
// Module      : tb_alu.v
// Project     : 4-Stage Pipelined RISC Processor — ALU Testbench
// Author      : Shivam Sharma
// Description : Unit testbench for ALU — verifies all operations with
//               pass/fail checking
// =============================================================================

`timescale 1ns / 1ps

module tb_alu;

    reg  [31:0] a, b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero, overflow, negative;

    integer pass_count = 0;
    integer fail_count = 0;

    alu dut (
        .a        (a),
        .b        (b),
        .alu_ctrl (alu_ctrl),
        .result   (result),
        .zero     (zero),
        .overflow (overflow),
        .negative (negative)
    );

    task check;
        input [31:0] expected;
        input [63:0] test_name; // simplified label
        begin
            #10;
            if (result === expected) begin
                $display("  PASS | %-20s | result=0x%08h", test_name, result);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-20s | expected=0x%08h got=0x%08h",
                          test_name, expected, result);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("===================================================");
        $display("  ALU Unit Test — Shivam Sharma                   ");
        $display("===================================================");

        // ADD
        a=32'd15;      b=32'd10;     alu_ctrl=4'b0000; check(32'd25,      "ADD 15+10");
        a=32'hFFFFFFFF; b=32'd1;     alu_ctrl=4'b0000; check(32'd0,       "ADD overflow wrap");

        // SUB
        a=32'd20;      b=32'd8;      alu_ctrl=4'b0001; check(32'd12,      "SUB 20-8");
        a=32'd5;       b=32'd10;     alu_ctrl=4'b0001; check(32'hFFFFFFFB,"SUB negative");

        // AND
        a=32'hFF00FF00; b=32'hF0F0F0F0; alu_ctrl=4'b0010; check(32'hF000F000,"AND");

        // OR
        a=32'h0F0F0F0F; b=32'hF0F0F0F0; alu_ctrl=4'b0011; check(32'hFFFFFFFF,"OR");

        // XOR
        a=32'hAAAAAAAA; b=32'h55555555; alu_ctrl=4'b0100; check(32'hFFFFFFFF,"XOR");

        // SLT
        a=32'd5;       b=32'd10;     alu_ctrl=4'b0101; check(32'd1,       "SLT 5<10");
        a=32'd10;      b=32'd5;      alu_ctrl=4'b0101; check(32'd0,       "SLT 10<5 false");

        // SLL
        a=32'd1;       b=32'd4;      alu_ctrl=4'b0111; check(32'd16,      "SLL <<4");

        // SRL
        a=32'd32;      b=32'd2;      alu_ctrl=4'b1000; check(32'd8,       "SRL >>2");

        // SRA (sign-extending)
        a=32'h80000000; b=32'd1;     alu_ctrl=4'b1001; check(32'hC0000000,"SRA signed");

        // Zero flag
        a=32'd10;      b=32'd10;     alu_ctrl=4'b0001;
        #10;
        if (zero) $display("  PASS | ZERO flag (10-10=0)");
        else      $display("  FAIL | ZERO flag not set");

        $display("===================================================");
        $display("  Results: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display("===================================================");
        $finish;
    end

endmodule
