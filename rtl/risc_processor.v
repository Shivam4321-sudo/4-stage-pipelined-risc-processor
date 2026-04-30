// =============================================================================
// Module      : risc_processor.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Top-level integration of the 4-stage RISC pipeline:
//               Stage 1: IF  — Instruction Fetch
//               Stage 2: ID  — Instruction Decode & Register Read
//               Stage 3: EX  — Execute (ALU + Forwarding)
//               Stage 4: MEM/WB — Memory Access + Write Back
// =============================================================================

`timescale 1ns / 1ps

module risc_processor (
    input  wire        clk,
    input  wire        rst,
    // Debug ports (optional — useful in simulation)
    output wire [31:0] debug_pc,
    output wire [31:0] debug_alu_result,
    output wire [31:0] debug_reg_write_data,
    output wire [4:0]  debug_rd
);

    // =========================================================================
    // WIRE DECLARATIONS
    // =========================================================================

    // --- IF Stage ---
    wire [31:0] pc_current, pc_plus4, pc_next_sel, instruction_if;
    wire        pc_write_en, if_id_write_en;

    // --- IF/ID Register Outputs ---
    wire [31:0] if_id_pc, if_id_instruction;

    // --- ID Stage ---
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [31:0] id_read_data1, id_read_data2, id_imm;
    wire [2:0]  id_funct3;
    wire [6:0]  id_funct7;
    // Control signals from ID
    wire        id_reg_write, id_alu_src, id_mem_write, id_mem_read;
    wire        id_mem_to_reg, id_branch, id_jump;
    wire [1:0]  id_alu_op;
    wire        ctrl_mux_sel;   // Hazard: insert bubble

    // --- ID/EX Register Outputs ---
    wire [31:0] ex_pc, ex_read_data1, ex_read_data2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire        ex_reg_write, ex_alu_src, ex_mem_write, ex_mem_read;
    wire        ex_mem_to_reg, ex_branch, ex_jump;
    wire [1:0]  ex_alu_op;

    // --- EX Stage ---
    wire [3:0]  alu_ctrl_sig;
    wire [31:0] alu_operand_a, alu_operand_b, alu_result_ex;
    wire [31:0] forwarded_a, forwarded_b;
    wire        alu_zero;
    wire [31:0] branch_target;
    wire [1:0]  fwd_a, fwd_b;

    // --- EX/MEM Register Outputs ---
    wire [31:0] mem_alu_result, mem_write_data, mem_branch_target;
    wire [4:0]  mem_rd;
    wire        mem_reg_write, mem_mem_write, mem_mem_read;
    wire        mem_mem_to_reg, mem_branch, mem_jump, mem_zero;

    // --- MEM Stage ---
    wire [31:0] mem_read_data_out;
    wire        branch_taken;
    wire [31:0] pc_branch_or_jump;

    // --- MEM/WB Register Outputs ---
    wire [31:0] wb_mem_data, wb_alu_result;
    wire [4:0]  wb_rd;
    wire        wb_reg_write, wb_mem_to_reg;

    // --- WB Stage ---
    wire [31:0] wb_write_data;

    // =========================================================================
    // STAGE 1 — INSTRUCTION FETCH (IF)
    // =========================================================================

    assign pc_plus4      = pc_current + 32'd4;
    assign branch_taken  = (mem_branch & mem_zero) | mem_jump;
    assign pc_branch_or_jump = mem_branch_target;
    assign pc_next_sel   = branch_taken ? pc_branch_or_jump : pc_plus4;

    pc_register u_pc (
        .clk      (clk),
        .rst      (rst),
        .pc_write (pc_write_en),
        .pc_next  (pc_next_sel),
        .pc_out   (pc_current)
    );

    instruction_memory u_imem (
        .addr        (pc_current),
        .instruction (instruction_if)
    );

    if_id_reg u_if_id (
        .clk             (clk),
        .rst             (rst),
        .if_id_write     (if_id_write_en),
        .flush           (branch_taken),
        .pc_in           (pc_current),
        .instruction_in  (instruction_if),
        .pc_out          (if_id_pc),
        .instruction_out (if_id_instruction)
    );

    // =========================================================================
    // STAGE 2 — INSTRUCTION DECODE (ID)
    // =========================================================================

    assign id_rs1   = if_id_instruction[19:15];
    assign id_rs2   = if_id_instruction[24:20];
    assign id_rd    = if_id_instruction[11:7];
    assign id_funct3 = if_id_instruction[14:12];
    assign id_funct7 = if_id_instruction[31:25];

    register_file u_regfile (
        .clk        (clk),
        .rst        (rst),
        .rs1        (id_rs1),
        .read_data1 (id_read_data1),
        .rs2        (id_rs2),
        .read_data2 (id_read_data2),
        .reg_write  (wb_reg_write),
        .rd         (wb_rd),
        .write_data (wb_write_data)
    );

    imm_gen u_immgen (
        .instruction (if_id_instruction),
        .imm_out     (id_imm)
    );

    // Control unit with bubble mux (hazard stall inserts NOP)
    wire ctrl_reg_write, ctrl_alu_src, ctrl_mem_write, ctrl_mem_read;
    wire ctrl_mem_to_reg, ctrl_branch, ctrl_jump;
    wire [1:0] ctrl_alu_op;

    control_unit u_ctrl (
        .opcode      (if_id_instruction[6:0]),
        .reg_write   (ctrl_reg_write),
        .alu_src     (ctrl_alu_src),
        .mem_write   (ctrl_mem_write),
        .mem_read    (ctrl_mem_read),
        .mem_to_reg  (ctrl_mem_to_reg),
        .branch      (ctrl_branch),
        .jump        (ctrl_jump),
        .alu_op      (ctrl_alu_op)
    );

    // Hazard: if stall, zero out all control signals (insert NOP bubble)
    assign id_reg_write  = ctrl_mux_sel ? 1'b0 : ctrl_reg_write;
    assign id_alu_src    = ctrl_mux_sel ? 1'b0 : ctrl_alu_src;
    assign id_mem_write  = ctrl_mux_sel ? 1'b0 : ctrl_mem_write;
    assign id_mem_read   = ctrl_mux_sel ? 1'b0 : ctrl_mem_read;
    assign id_mem_to_reg = ctrl_mux_sel ? 1'b0 : ctrl_mem_to_reg;
    assign id_branch     = ctrl_mux_sel ? 1'b0 : ctrl_branch;
    assign id_jump       = ctrl_mux_sel ? 1'b0 : ctrl_jump;
    assign id_alu_op     = ctrl_mux_sel ? 2'b0 : ctrl_alu_op;

    hazard_detection u_hazard (
        .id_ex_mem_read   (ex_mem_read),
        .id_ex_rd         (ex_rd),
        .if_id_rs1        (id_rs1),
        .if_id_rs2        (id_rs2),
        .pc_write         (pc_write_en),
        .if_id_write      (if_id_write_en),
        .control_mux_sel  (ctrl_mux_sel)
    );

    id_ex_reg u_id_ex (
        .clk            (clk),         .rst            (rst),
        .flush          (1'b0),
        .reg_write_in   (id_reg_write),   .reg_write_out  (ex_reg_write),
        .alu_src_in     (id_alu_src),     .alu_src_out    (ex_alu_src),
        .mem_write_in   (id_mem_write),   .mem_write_out  (ex_mem_write),
        .mem_read_in    (id_mem_read),    .mem_read_out   (ex_mem_read),
        .mem_to_reg_in  (id_mem_to_reg),  .mem_to_reg_out (ex_mem_to_reg),
        .branch_in      (id_branch),      .branch_out     (ex_branch),
        .jump_in        (id_jump),        .jump_out       (ex_jump),
        .alu_op_in      (id_alu_op),      .alu_op_out     (ex_alu_op),
        .pc_in          (if_id_pc),       .pc_out         (ex_pc),
        .read_data1_in  (id_read_data1),  .read_data1_out (ex_read_data1),
        .read_data2_in  (id_read_data2),  .read_data2_out (ex_read_data2),
        .imm_in         (id_imm),         .imm_out        (ex_imm),
        .rs1_in         (id_rs1),         .rs1_out        (ex_rs1),
        .rs2_in         (id_rs2),         .rs2_out        (ex_rs2),
        .rd_in          (id_rd),          .rd_out         (ex_rd),
        .funct3_in      (id_funct3),      .funct3_out     (ex_funct3),
        .funct7_in      (id_funct7),      .funct7_out     (ex_funct7)
    );

    // =========================================================================
    // STAGE 3 — EXECUTE (EX)
    // =========================================================================

    forwarding_unit u_fwd (
        .ex_rs1            (ex_rs1),
        .ex_rs2            (ex_rs2),
        .ex_mem_reg_write  (mem_reg_write),
        .ex_mem_rd         (mem_rd),
        .mem_wb_reg_write  (wb_reg_write),
        .mem_wb_rd         (wb_rd),
        .forward_a         (fwd_a),
        .forward_b         (fwd_b)
    );

    // Forwarding MUX for operand A
    assign forwarded_a = (fwd_a == 2'b10) ? mem_alu_result :
                         (fwd_a == 2'b01) ? wb_write_data  :
                                            ex_read_data1;

    // Forwarding MUX for operand B (before ALU src mux)
    assign forwarded_b = (fwd_b == 2'b10) ? mem_alu_result :
                         (fwd_b == 2'b01) ? wb_write_data  :
                                            ex_read_data2;

    // ALU src MUX: choose immediate or forwarded register
    assign alu_operand_a = forwarded_a;
    assign alu_operand_b = ex_alu_src ? ex_imm : forwarded_b;

    alu_control u_alu_ctrl (
        .alu_op   (ex_alu_op),
        .funct3   (ex_funct3),
        .funct7   (ex_funct7),
        .alu_ctrl (alu_ctrl_sig)
    );

    alu u_alu (
        .a        (alu_operand_a),
        .b        (alu_operand_b),
        .alu_ctrl (alu_ctrl_sig),
        .result   (alu_result_ex),
        .zero     (alu_zero),
        .overflow (),
        .negative ()
    );

    // Branch target address = PC + (imm << 1) — already shifted in imm_gen
    assign branch_target = ex_pc + ex_imm;

    ex_mem_reg u_ex_mem (
        .clk              (clk),          .rst              (rst),
        .reg_write_in     (ex_reg_write),  .reg_write_out    (mem_reg_write),
        .mem_write_in     (ex_mem_write),  .mem_write_out    (mem_mem_write),
        .mem_read_in      (ex_mem_read),   .mem_read_out     (mem_mem_read),
        .mem_to_reg_in    (ex_mem_to_reg), .mem_to_reg_out   (mem_mem_to_reg),
        .branch_in        (ex_branch),     .branch_out       (mem_branch),
        .jump_in          (ex_jump),       .jump_out         (mem_jump),
        .zero_in          (alu_zero),      .zero_out         (mem_zero),
        .alu_result_in    (alu_result_ex), .alu_result_out   (mem_alu_result),
        .write_data_in    (forwarded_b),   .write_data_out   (mem_write_data),
        .branch_target_in (branch_target), .branch_target_out(mem_branch_target),
        .rd_in            (ex_rd),         .rd_out           (mem_rd)
    );

    // =========================================================================
    // STAGE 4A — MEMORY ACCESS (MEM)
    // =========================================================================

    data_memory u_dmem (
        .clk        (clk),
        .mem_write  (mem_mem_write),
        .mem_read   (mem_mem_read),
        .addr       (mem_alu_result),
        .write_data (mem_write_data),
        .read_data  (mem_read_data_out)
    );

    mem_wb_reg u_mem_wb (
        .clk            (clk),           .rst            (rst),
        .reg_write_in   (mem_reg_write),  .reg_write_out  (wb_reg_write),
        .mem_to_reg_in  (mem_mem_to_reg), .mem_to_reg_out (wb_mem_to_reg),
        .mem_data_in    (mem_read_data_out),.mem_data_out  (wb_mem_data),
        .alu_result_in  (mem_alu_result), .alu_result_out (wb_alu_result),
        .rd_in          (mem_rd),         .rd_out         (wb_rd)
    );

    // =========================================================================
    // STAGE 4B — WRITE BACK (WB)
    // =========================================================================

    assign wb_write_data = wb_mem_to_reg ? wb_mem_data : wb_alu_result;

    // =========================================================================
    // DEBUG OUTPUTS
    // =========================================================================
    assign debug_pc             = pc_current;
    assign debug_alu_result     = mem_alu_result;
    assign debug_reg_write_data = wb_write_data;
    assign debug_rd             = wb_rd;

endmodule
