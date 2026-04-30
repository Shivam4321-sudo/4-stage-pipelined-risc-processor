// ============================================================
//  Testbench — Hazard Detection Unit
//  Author : Shivam Sharma | Dec 2025
// ============================================================
`timescale 1ns / 1ps

module tb_hazard_unit;

    reg        id_ex_mem_read;
    reg  [4:0] id_ex_rd;
    reg  [4:0] if_id_rs1;
    reg  [4:0] if_id_rs2;
    wire       stall;
    wire       flush;

    hazard_unit dut (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (if_id_rs1),
        .if_id_rs2      (if_id_rs2),
        .stall          (stall),
        .flush          (flush)
    );

    initial begin
        $display("=== Hazard Detection Unit Tests ===");

        // Test 1: Load-use hazard on rs1
        id_ex_mem_read=1; id_ex_rd=5'd3; if_id_rs1=5'd3; if_id_rs2=5'd5;
        #2;
        if (stall===1 && flush===1)
            $display("PASS [LOAD_USE_RS1]: stall=1 flush=1");
        else
            $display("FAIL [LOAD_USE_RS1]: stall=%b flush=%b", stall, flush);

        // Test 2: Load-use hazard on rs2
        id_ex_mem_read=1; id_ex_rd=5'd4; if_id_rs1=5'd2; if_id_rs2=5'd4;
        #2;
        if (stall===1 && flush===1)
            $display("PASS [LOAD_USE_RS2]: stall=1 flush=1");
        else
            $display("FAIL [LOAD_USE_RS2]: stall=%b flush=%b", stall, flush);

        // Test 3: No hazard — different registers
        id_ex_mem_read=1; id_ex_rd=5'd7; if_id_rs1=5'd2; if_id_rs2=5'd3;
        #2;
        if (stall===0 && flush===0)
            $display("PASS [NO_HAZARD]: stall=0 flush=0");
        else
            $display("FAIL [NO_HAZARD]: stall=%b flush=%b", stall, flush);

        // Test 4: No hazard — not a load instruction
        id_ex_mem_read=0; id_ex_rd=5'd3; if_id_rs1=5'd3; if_id_rs2=5'd3;
        #2;
        if (stall===0 && flush===0)
            $display("PASS [NOT_LOAD]: stall=0 flush=0");
        else
            $display("FAIL [NOT_LOAD]: stall=%b flush=%b", stall, flush);

        // Test 5: No hazard — rd is r0 (zero register)
        id_ex_mem_read=1; id_ex_rd=5'd0; if_id_rs1=5'd0; if_id_rs2=5'd0;
        #2;
        if (stall===0 && flush===0)
            $display("PASS [RD_ZERO]: stall=0 flush=0");
        else
            $display("FAIL [RD_ZERO]: stall=%b flush=%b", stall, flush);

        $display("=== Hazard Unit Tests Complete ===");
        $finish;
    end

endmodule
