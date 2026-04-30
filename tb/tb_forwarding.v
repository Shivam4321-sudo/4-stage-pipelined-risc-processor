// =============================================================================
// Module      : tb_forwarding.v
// Project     : 4-Stage Pipelined RISC Processor — Forwarding Unit Testbench
// Author      : Shivam Sharma
// Description : Unit testbench for forwarding unit — verifies EX-EX hazard,
//               MEM-EX hazard, and no-hazard conditions
// =============================================================================

`timescale 1ns / 1ps

module tb_forwarding;

    reg  [4:0]  ex_rs1, ex_rs2;
    reg         ex_mem_reg_write, mem_wb_reg_write;
    reg  [4:0]  ex_mem_rd, mem_wb_rd;
    wire [1:0]  forward_a, forward_b;

    integer pass_count = 0;
    integer fail_count = 0;

    forwarding_unit dut (
        .ex_rs1           (ex_rs1),
        .ex_rs2           (ex_rs2),
        .ex_mem_reg_write (ex_mem_reg_write),
        .ex_mem_rd        (ex_mem_rd),
        .mem_wb_reg_write (mem_wb_reg_write),
        .mem_wb_rd        (mem_wb_rd),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    task check_fwd;
        input [1:0] exp_a, exp_b;
        input [8*32-1:0] label;
        begin
            #5;
            if (forward_a === exp_a && forward_b === exp_b) begin
                $display("  PASS | %-35s | fwd_a=%b fwd_b=%b", label, forward_a, forward_b);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-35s | exp a=%b b=%b  got a=%b b=%b",
                          label, exp_a, exp_b, forward_a, forward_b);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("===================================================");
        $display("  Forwarding Unit Test — Shivam Sharma            ");
        $display("===================================================");

        // No hazard
        ex_rs1=5'd2; ex_rs2=5'd3;
        ex_mem_reg_write=0; ex_mem_rd=5'd0;
        mem_wb_reg_write=0; mem_wb_rd=5'd0;
        check_fwd(2'b00, 2'b00, "No hazard");

        // EX-EX hazard on RS1
        ex_rs1=5'd5; ex_rs2=5'd3;
        ex_mem_reg_write=1; ex_mem_rd=5'd5;
        mem_wb_reg_write=0; mem_wb_rd=5'd0;
        check_fwd(2'b10, 2'b00, "EX-EX hazard RS1");

        // EX-EX hazard on RS2
        ex_rs1=5'd2; ex_rs2=5'd7;
        ex_mem_reg_write=1; ex_mem_rd=5'd7;
        mem_wb_reg_write=0; mem_wb_rd=5'd0;
        check_fwd(2'b00, 2'b10, "EX-EX hazard RS2");

        // MEM-EX hazard on RS1
        ex_rs1=5'd4; ex_rs2=5'd3;
        ex_mem_reg_write=0; ex_mem_rd=5'd0;
        mem_wb_reg_write=1; mem_wb_rd=5'd4;
        check_fwd(2'b01, 2'b00, "MEM-EX hazard RS1");

        // MEM-EX hazard on RS2
        ex_rs1=5'd2; ex_rs2=5'd6;
        ex_mem_reg_write=0; ex_mem_rd=5'd0;
        mem_wb_reg_write=1; mem_wb_rd=5'd6;
        check_fwd(2'b00, 2'b01, "MEM-EX hazard RS2");

        // EX-EX takes priority over MEM-EX on RS1
        ex_rs1=5'd8; ex_rs2=5'd3;
        ex_mem_reg_write=1; ex_mem_rd=5'd8;
        mem_wb_reg_write=1; mem_wb_rd=5'd8;
        check_fwd(2'b10, 2'b00, "EX-EX priority over MEM-EX RS1");

        // R0 is hardwired zero — no forwarding to R0
        ex_rs1=5'd0; ex_rs2=5'd0;
        ex_mem_reg_write=1; ex_mem_rd=5'd0;
        mem_wb_reg_write=1; mem_wb_rd=5'd0;
        check_fwd(2'b00, 2'b00, "R0 no forwarding");

        $display("===================================================");
        $display("  Results: %0d PASSED | %0d FAILED", pass_count, fail_count);
        $display("===================================================");
        $finish;
    end

endmodule
