// =============================================================================
// Module      : alu_control.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : ALU Control Unit — decodes funct3, funct7, and ALUOp to
//               generate 4-bit ALU operation select signal
// =============================================================================

`timescale 1ns / 1ps

module alu_control (
    input  wire [1:0] alu_op,     // From main control unit
    input  wire [2:0] funct3,     // From instruction [14:12]
    input  wire [6:0] funct7,     // From instruction [31:25]
    output reg  [3:0] alu_ctrl    // To ALU
);

    // ALUOp encoding:
    // 00 = Load/Store (ADD)
    // 01 = Branch    (SUB)
    // 10 = R-type    (use funct3/funct7)
    // 11 = I-type    (use funct3 only)

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000;   // ADD (lw/sw)
            2'b01: alu_ctrl = 4'b0001;   // SUB (beq/bne)
            2'b10: begin                  // R-type
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB / ADD
                    3'b001: alu_ctrl = 4'b0111;  // SLL
                    3'b010: alu_ctrl = 4'b0101;  // SLT
                    3'b011: alu_ctrl = 4'b0110;  // SLTU
                    3'b100: alu_ctrl = 4'b0100;  // XOR
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b1001 : 4'b1000; // SRA / SRL
                    3'b110: alu_ctrl = 4'b0011;  // OR
                    3'b111: alu_ctrl = 4'b0010;  // AND
                    default: alu_ctrl = 4'b1111;
                endcase
            end
            2'b11: begin                  // I-type
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000;  // ADDI
                    3'b001: alu_ctrl = 4'b0111;  // SLLI
                    3'b010: alu_ctrl = 4'b0101;  // SLTI
                    3'b011: alu_ctrl = 4'b0110;  // SLTIU
                    3'b100: alu_ctrl = 4'b0100;  // XORI
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b1001 : 4'b1000; // SRAI/SRLI
                    3'b110: alu_ctrl = 4'b0011;  // ORI
                    3'b111: alu_ctrl = 4'b0010;  // ANDI
                    default: alu_ctrl = 4'b1111;
                endcase
            end
            default: alu_ctrl = 4'b1111;
        endcase
    end

endmodule
