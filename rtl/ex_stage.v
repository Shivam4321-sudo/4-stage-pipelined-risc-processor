// ============================================================
//  EX Stage — ALU Execute
//  Author : Shivam Sharma | Dec 2025
// ============================================================
`timescale 1ns / 1ps

module ex_stage (
    input  wire [3:0]  alu_op,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    output reg  [31:0] result,
    output wire        zero
);

    assign zero = (result == 32'b0);

    always @(*) begin
        case (alu_op)
            4'b0000: result = operand_a + operand_b;                    // ADD
            4'b0001: result = operand_a - operand_b;                    // SUB
            4'b0010: result = operand_a & operand_b;                    // AND
            4'b0011: result = operand_a | operand_b;                    // OR
            4'b0100: result = ($signed(operand_a) < $signed(operand_b)) // SLT
                              ? 32'd1 : 32'd0;
            4'b0101: result = operand_a ^ operand_b;                    // XOR
            4'b0110: result = operand_a << operand_b[4:0];             // SLL
            4'b0111: result = operand_a >> operand_b[4:0];             // SRL
            4'b1000: result = ~(operand_a | operand_b);                 // NOR
            4'b1001: result = operand_a >>> operand_b[4:0];            // SRA
            default: result = 32'b0;
        endcase
    end

endmodule
