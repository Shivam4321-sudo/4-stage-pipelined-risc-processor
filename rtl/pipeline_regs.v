// =============================================================================
// Module      : pipeline_regs.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : All four pipeline stage registers:
//               IF/ID  — Instruction Fetch  → Decode
//               ID/EX  — Decode             → Execute
//               EX/MEM — Execute            → Memory
//               MEM/WB — Memory             → Writeback
// =============================================================================

`timescale 1ns / 1ps

// ─────────────────────────────────────────────────────────────────────────────
// IF/ID Pipeline Register
// ─────────────────────────────────────────────────────────────────────────────
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        if_id_write,    // 0 = stall (freeze)
    input  wire        flush,          // 1 = flush on branch taken
    input  wire [31:0] pc_in,
    input  wire [31:0] instruction_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instruction_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out          <= 32'b0;
            instruction_out <= 32'b0;   // NOP
        end else if (if_id_write) begin
            pc_out          <= pc_in;
            instruction_out <= instruction_in;
        end
        // else: hold (stall)
    end
endmodule


// ─────────────────────────────────────────────────────────────────────────────
// ID/EX Pipeline Register
// ─────────────────────────────────────────────────────────────────────────────
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,          // 1 = insert NOP bubble
    // Control signals
    input  wire        reg_write_in,
    input  wire        alu_src_in,
    input  wire        mem_write_in,
    input  wire        mem_read_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire [1:0]  alu_op_in,
    // Data
    input  wire [31:0] pc_in,
    input  wire [31:0] read_data1_in,
    input  wire [31:0] read_data2_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,
    // Outputs
    output reg         reg_write_out,
    output reg         alu_src_out,
    output reg         mem_write_out,
    output reg         mem_read_out,
    output reg         mem_to_reg_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg  [1:0]  alu_op_out,
    output reg  [31:0] pc_out,
    output reg  [31:0] read_data1_out,
    output reg  [31:0] read_data2_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  funct7_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            reg_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            alu_op_out     <= 2'b0;
            pc_out         <= 32'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            imm_out        <= 32'b0;
            rs1_out        <= 5'b0;
            rs2_out        <= 5'b0;
            rd_out         <= 5'b0;
            funct3_out     <= 3'b0;
            funct7_out     <= 7'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            alu_src_out    <= alu_src_in;
            mem_write_out  <= mem_write_in;
            mem_read_out   <= mem_read_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            alu_op_out     <= alu_op_in;
            pc_out         <= pc_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            imm_out        <= imm_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            funct7_out     <= funct7_in;
        end
    end
endmodule


// ─────────────────────────────────────────────────────────────────────────────
// EX/MEM Pipeline Register
// ─────────────────────────────────────────────────────────────────────────────
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    // Control
    input  wire        reg_write_in,
    input  wire        mem_write_in,
    input  wire        mem_read_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        zero_in,
    // Data
    input  wire [31:0] alu_result_in,
    input  wire [31:0] write_data_in,
    input  wire [31:0] branch_target_in,
    input  wire [4:0]  rd_in,
    // Outputs
    output reg         reg_write_out,
    output reg         mem_write_out,
    output reg         mem_read_out,
    output reg         mem_to_reg_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg         zero_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] write_data_out,
    output reg  [31:0] branch_target_out,
    output reg  [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out     <= 1'b0;
            mem_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            branch_out        <= 1'b0;
            jump_out          <= 1'b0;
            zero_out          <= 1'b0;
            alu_result_out    <= 32'b0;
            write_data_out    <= 32'b0;
            branch_target_out <= 32'b0;
            rd_out            <= 5'b0;
        end else begin
            reg_write_out     <= reg_write_in;
            mem_write_out     <= mem_write_in;
            mem_read_out      <= mem_read_in;
            mem_to_reg_out    <= mem_to_reg_in;
            branch_out        <= branch_in;
            jump_out          <= jump_in;
            zero_out          <= zero_in;
            alu_result_out    <= alu_result_in;
            write_data_out    <= write_data_in;
            branch_target_out <= branch_target_in;
            rd_out            <= rd_in;
        end
    end
endmodule


// ─────────────────────────────────────────────────────────────────────────────
// MEM/WB Pipeline Register
// ─────────────────────────────────────────────────────────────────────────────
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    // Control
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    // Data
    input  wire [31:0] mem_data_in,
    input  wire [31:0] alu_result_in,
    input  wire [4:0]  rd_in,
    // Outputs
    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg  [31:0] mem_data_out,
    output reg  [31:0] alu_result_out,
    output reg  [4:0]  rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            mem_data_out   <= 32'b0;
            alu_result_out <= 32'b0;
            rd_out         <= 5'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_data_out   <= mem_data_in;
            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;
        end
    end
endmodule
