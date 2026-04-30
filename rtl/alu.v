// =============================================================================
// Module      : alu.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Arithmetic Logic Unit — supports ADD, SUB, AND, OR, XOR,
//               SLT, SLL, SRL, SRA operations
// =============================================================================

`timescale 1ns / 1ps

// ALU Operation Codes
`define ALU_ADD  4'b0000
`define ALU_SUB  4'b0001
`define ALU_AND  4'b0010
`define ALU_OR   4'b0011
`define ALU_XOR  4'b0100
`define ALU_SLT  4'b0101   // Set Less Than (signed)
`define ALU_SLTU 4'b0110   // Set Less Than Unsigned
`define ALU_SLL  4'b0111   // Shift Left Logical
`define ALU_SRL  4'b1000   // Shift Right Logical
`define ALU_SRA  4'b1001   // Shift Right Arithmetic
`define ALU_LUI  4'b1010   // Load Upper Immediate (pass B)
`define ALU_NOP  4'b1111

module alu (
    input  wire [31:0] a,          // Operand A (RS1 or forwarded)
    input  wire [31:0] b,          // Operand B (RS2 / immediate)
    input  wire [3:0]  alu_ctrl,   // Operation select
    output reg  [31:0] result,     // ALU result
    output wire        zero,       // Zero flag (used for branch)
    output wire        overflow,   // Overflow flag
    output wire        negative    // Negative flag
);

    wire [31:0] add_result = a + b;
    wire [31:0] sub_result = a - b;

    always @(*) begin
        case (alu_ctrl)
            `ALU_ADD  : result = a + b;
            `ALU_SUB  : result = a - b;
            `ALU_AND  : result = a & b;
            `ALU_OR   : result = a | b;
            `ALU_XOR  : result = a ^ b;
            `ALU_SLT  : result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            `ALU_SLTU : result = (a < b) ? 32'b1 : 32'b0;
            `ALU_SLL  : result = a << b[4:0];
            `ALU_SRL  : result = a >> b[4:0];
            `ALU_SRA  : result = $signed(a) >>> b[4:0];
            `ALU_LUI  : result = b;
            default   : result = 32'b0;
        endcase
    end

    assign zero     = (result == 32'b0);
    assign negative = result[31];
    assign overflow = ((alu_ctrl == `ALU_ADD) &&
                       (a[31] == b[31]) && (result[31] != a[31])) ||
                      ((alu_ctrl == `ALU_SUB) &&
                       (a[31] != b[31]) && (result[31] != a[31]));

endmodule
