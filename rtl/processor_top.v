// ============================================================
//  4-Stage Pipelined RISC Processor — Top Level
//  Author : Shivam Sharma
//  Date   : December 2025
//  Tool   : Xilinx Vivado (Verilog HDL)
//
//  Pipeline Stages:
//    IF  — Instruction Fetch
//    ID  — Instruction Decode / Register Read
//    EX  — Execute (ALU)
//    WB  — Write Back
// ============================================================

`timescale 1ns / 1ps

module processor_top (
    input  wire        clk,
    input  wire        rst
);

    // ── IF/ID Pipeline Register ──────────────────────────────
    wire [31:0] if_pc;
    wire [31:0] if_instruction;

    reg  [31:0] if_id_pc;
    reg  [31:0] if_id_instr;

    // ── ID/EX Pipeline Register ──────────────────────────────
    reg  [31:0] id_ex_pc;
    reg  [31:0] id_ex_rs1_data;
    reg  [31:0] id_ex_rs2_data;
    reg  [31:0] id_ex_imm;
    reg  [4:0]  id_ex_rs1;
    reg  [4:0]  id_ex_rs2;
    reg  [4:0]  id_ex_rd;
    reg  [3:0]  id_ex_alu_op;
    reg         id_ex_alu_src;
    reg         id_ex_reg_write;
    reg         id_ex_mem_read;
    reg         id_ex_mem_write;
    reg         id_ex_mem_to_reg;
    reg         id_ex_branch;

    // ── EX/WB Pipeline Register ──────────────────────────────
    reg  [31:0] ex_wb_alu_result;
    reg  [31:0] ex_wb_rs2_data;
    reg  [4:0]  ex_wb_rd;
    reg         ex_wb_reg_write;
    reg         ex_wb_mem_to_reg;
    reg         ex_wb_mem_read;
    reg         ex_wb_mem_write;

    // ── WB stage wires ────────────────────────────────────────
    wire [31:0] wb_write_data;
    wire [31:0] mem_read_data;

    // ── Hazard / Forwarding wires ─────────────────────────────
    wire        stall;
    wire        flush;
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire [31:0] alu_result_ex;
    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b_mux;
    wire [31:0] alu_result_wire;
    wire        zero_flag;

    // ── Branch PC ─────────────────────────────────────────────
    wire [31:0] branch_target;
    wire        branch_taken;

    // ─────────────────────────────────────────────────────────
    //  Stage 1 : IF — Instruction Fetch
    // ─────────────────────────────────────────────────────────
    if_stage u_if_stage (
        .clk            (clk),
        .rst            (rst),
        .stall          (stall),
        .branch_taken   (branch_taken),
        .branch_target  (branch_target),
        .pc_out         (if_pc),
        .instruction    (if_instruction)
    );

    // IF/ID Pipeline Register
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'b0;          // NOP
        end else if (!stall) begin
            if_id_pc    <= if_pc;
            if_id_instr <= if_instruction;
        end
    end

    // ─────────────────────────────────────────────────────────
    //  Stage 2 : ID — Instruction Decode
    // ─────────────────────────────────────────────────────────
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [31:0] id_rs1_data, id_rs2_data, id_imm;
    wire [3:0]  id_alu_op;
    wire        id_alu_src, id_reg_write;
    wire        id_mem_read, id_mem_write, id_mem_to_reg, id_branch;

    id_stage u_id_stage (
        .clk          (clk),
        .rst          (rst),
        .instruction  (if_id_instr),
        .pc_in        (if_id_pc),
        // WB write-back port
        .wb_reg_write (ex_wb_reg_write),
        .wb_rd        (ex_wb_rd),
        .wb_data      (wb_write_data),
        // Decoded outputs
        .rs1          (id_rs1),
        .rs2          (id_rs2),
        .rd           (id_rd),
        .rs1_data     (id_rs1_data),
        .rs2_data     (id_rs2_data),
        .imm          (id_imm),
        .alu_op       (id_alu_op),
        .alu_src      (id_alu_src),
        .reg_write    (id_reg_write),
        .mem_read     (id_mem_read),
        .mem_write    (id_mem_write),
        .mem_to_reg   (id_mem_to_reg),
        .branch       (id_branch)
    );

    // ID/EX Pipeline Register
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            id_ex_pc         <= 32'b0;
            id_ex_rs1_data   <= 32'b0;
            id_ex_rs2_data   <= 32'b0;
            id_ex_imm        <= 32'b0;
            id_ex_rs1        <= 5'b0;
            id_ex_rs2        <= 5'b0;
            id_ex_rd         <= 5'b0;
            id_ex_alu_op     <= 4'b0;
            id_ex_alu_src    <= 1'b0;
            id_ex_reg_write  <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_branch     <= 1'b0;
        end else if (!stall) begin
            id_ex_pc         <= if_id_pc;
            id_ex_rs1_data   <= id_rs1_data;
            id_ex_rs2_data   <= id_rs2_data;
            id_ex_imm        <= id_imm;
            id_ex_rs1        <= id_rs1;
            id_ex_rs2        <= id_rs2;
            id_ex_rd         <= id_rd;
            id_ex_alu_op     <= id_alu_op;
            id_ex_alu_src    <= id_alu_src;
            id_ex_reg_write  <= id_reg_write;
            id_ex_mem_read   <= id_mem_read;
            id_ex_mem_write  <= id_mem_write;
            id_ex_mem_to_reg <= id_mem_to_reg;
            id_ex_branch     <= id_branch;
        end
    end

    // ─────────────────────────────────────────────────────────
    //  Stage 3 : EX — Execute
    // ─────────────────────────────────────────────────────────

    // Forwarding MUX for operand A
    assign alu_operand_a = (forward_a == 2'b10) ? ex_wb_alu_result :
                           (forward_a == 2'b01) ? wb_write_data     :
                                                   id_ex_rs1_data;

    // Forwarding MUX for operand B (before ALU-src mux)
    wire [31:0] forward_b_result;
    assign forward_b_result = (forward_b == 2'b10) ? ex_wb_alu_result :
                              (forward_b == 2'b01) ? wb_write_data     :
                                                      id_ex_rs2_data;

    // ALU source mux (register vs immediate)
    assign alu_operand_b_mux = id_ex_alu_src ? id_ex_imm : forward_b_result;

    ex_stage u_ex_stage (
        .alu_op    (id_ex_alu_op),
        .operand_a (alu_operand_a),
        .operand_b (alu_operand_b_mux),
        .result    (alu_result_wire),
        .zero      (zero_flag)
    );

    // Branch target calculation
    assign branch_target = id_ex_pc + (id_ex_imm << 1);
    assign branch_taken  = id_ex_branch & zero_flag;

    // EX/WB Pipeline Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_wb_alu_result  <= 32'b0;
            ex_wb_rs2_data    <= 32'b0;
            ex_wb_rd          <= 5'b0;
            ex_wb_reg_write   <= 1'b0;
            ex_wb_mem_to_reg  <= 1'b0;
            ex_wb_mem_read    <= 1'b0;
            ex_wb_mem_write   <= 1'b0;
        end else begin
            ex_wb_alu_result  <= alu_result_wire;
            ex_wb_rs2_data    <= forward_b_result;
            ex_wb_rd          <= id_ex_rd;
            ex_wb_reg_write   <= id_ex_reg_write;
            ex_wb_mem_to_reg  <= id_ex_mem_to_reg;
            ex_wb_mem_read    <= id_ex_mem_read;
            ex_wb_mem_write   <= id_ex_mem_write;
        end
    end

    // ─────────────────────────────────────────────────────────
    //  Stage 4 : WB — Write Back  (includes Data Memory)
    // ─────────────────────────────────────────────────────────
    wb_stage u_wb_stage (
        .clk          (clk),
        .rst          (rst),
        .alu_result   (ex_wb_alu_result),
        .rs2_data     (ex_wb_rs2_data),
        .mem_read     (ex_wb_mem_read),
        .mem_write    (ex_wb_mem_write),
        .mem_to_reg   (ex_wb_mem_to_reg),
        .mem_data_out (mem_read_data),
        .write_data   (wb_write_data)
    );

    // ─────────────────────────────────────────────────────────
    //  Hazard Detection Unit
    // ─────────────────────────────────────────────────────────
    hazard_unit u_hazard (
        .id_ex_mem_read  (id_ex_mem_read),
        .id_ex_rd        (id_ex_rd),
        .if_id_rs1       (id_rs1),
        .if_id_rs2       (id_rs2),
        .stall           (stall),
        .flush           (flush)
    );

    // ─────────────────────────────────────────────────────────
    //  Forwarding Unit
    // ─────────────────────────────────────────────────────────
    forwarding_unit u_fwd (
        .ex_wb_reg_write  (ex_wb_reg_write),
        .ex_wb_rd         (ex_wb_rd),
        .wb_reg_write     (ex_wb_reg_write),   // passed through
        .wb_rd            (ex_wb_rd),
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

endmodule
