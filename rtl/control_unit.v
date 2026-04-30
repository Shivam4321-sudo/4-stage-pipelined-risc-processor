// =============================================================================
// Module      : control_unit.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Main Control Unit — decodes opcode and generates all control
//               signals for the pipeline stages
// =============================================================================

`timescale 1ns / 1ps

// RISC-V Base ISA Opcodes
`define OP_R_TYPE  7'b0110011   // ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT
`define OP_I_TYPE  7'b0010011   // ADDI, ANDI, ORI, XORI, SLTI, SLLI, SRLI, SRAI
`define OP_LOAD    7'b0000011   // LW, LH, LB
`define OP_STORE   7'b0100011   // SW, SH, SB
`define OP_BRANCH  7'b1100011   // BEQ, BNE, BLT, BGE
`define OP_JAL     7'b1101111   // JAL
`define OP_JALR    7'b1100111   // JALR
`define OP_LUI     7'b0110111   // LUI
`define OP_AUIPC   7'b0010111   // AUIPC

module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,    // Write to register file
    output reg        alu_src,      // 0=register, 1=immediate
    output reg        mem_write,    // Write to data memory
    output reg        mem_read,     // Read from data memory
    output reg        mem_to_reg,   // 0=ALU result, 1=memory data
    output reg        branch,       // Branch instruction
    output reg        jump,         // Jump instruction (JAL/JALR)
    output reg [1:0]  alu_op        // ALU operation type
);

    always @(*) begin
        // Default: all signals de-asserted (NOP behaviour)
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_write  = 1'b0;
        mem_read   = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            `OP_R_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;
                alu_op     = 2'b10;
            end
            `OP_I_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b0;
                alu_op     = 2'b11;
            end
            `OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            `OP_STORE: begin
                reg_write  = 1'b0;
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                alu_op     = 2'b00;
            end
            `OP_BRANCH: begin
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                branch     = 1'b1;
                alu_op     = 2'b01;
            end
            `OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_op     = 2'b00;
            end
            `OP_JALR: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                jump       = 1'b1;
                alu_op     = 2'b00;
            end
            `OP_LUI: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b00;
            end
            `OP_AUIPC: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b00;
            end
            default: begin
                // NOP / unrecognized opcode — all zeros
            end
        endcase
    end

endmodule
