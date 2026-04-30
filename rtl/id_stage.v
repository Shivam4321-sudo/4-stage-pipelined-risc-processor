// ============================================================
//  ID Stage — Instruction Decode + Register File
//  Author : Shivam Sharma | Dec 2025
//
//  Supported Instruction Encoding (32-bit RISC-like):
//    [31:26] opcode  [25:21] rs1  [20:16] rs2
//    [15:11] rd      [15:0]  imm (I-type)
//
//  Opcodes:
//    000000 = R-type  (ADD, SUB, AND, OR, SLT by funct)
//    000010 = ADDI
//    000100 = LW
//    000101 = SW
//    000110 = BEQ
//    000111 = BNE
// ============================================================
`timescale 1ns / 1ps

module id_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] instruction,
    input  wire [31:0] pc_in,
    // Write-back port
    input  wire        wb_reg_write,
    input  wire [4:0]  wb_rd,
    input  wire [31:0] wb_data,
    // Decoded outputs
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output reg  [31:0] imm,
    output reg  [3:0]  alu_op,
    output reg         alu_src,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         branch
);

    // ── Register File (32 × 32-bit) ──────────────────────────
    reg [31:0] regfile [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regfile[i] = 32'b0;
    end

    // Synchronous write, asynchronous read
    always @(posedge clk) begin
        if (wb_reg_write && (wb_rd != 5'b0))
            regfile[wb_rd] <= wb_data;
    end

    // Field extraction
    wire [5:0] opcode = instruction[31:26];
    wire [5:0] funct  = instruction[5:0];

    assign rs1 = instruction[25:21];
    assign rs2 = instruction[20:16];
    assign rd  = (opcode == 6'b000000) ? instruction[15:11] : instruction[20:16];

    assign rs1_data = (rs1 == 5'b0) ? 32'b0 : regfile[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'b0 : regfile[rs2];

    // Sign-extended immediate
    wire [31:0] sign_ext_imm = {{16{instruction[15]}}, instruction[15:0]};

    // ── Control Unit ─────────────────────────────────────────
    // ALU operation encoding:
    //   4'b0000 = ADD    4'b0001 = SUB
    //   4'b0010 = AND    4'b0011 = OR
    //   4'b0100 = SLT    4'b0101 = XOR
    //   4'b0110 = SLL    4'b0111 = SRL
    //   4'b1000 = NOR

    always @(*) begin
        // Defaults (NOP)
        imm        = sign_ext_imm;
        alu_op     = 4'b0000;
        alu_src    = 1'b0;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;

        case (opcode)
            // ── R-type ──────────────────────────────────────
            6'b000000: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct)
                    6'b100000: alu_op = 4'b0000; // ADD
                    6'b100010: alu_op = 4'b0001; // SUB
                    6'b100100: alu_op = 4'b0010; // AND
                    6'b100101: alu_op = 4'b0011; // OR
                    6'b101010: alu_op = 4'b0100; // SLT
                    6'b100110: alu_op = 4'b0101; // XOR
                    6'b000000: alu_op = 4'b0110; // SLL
                    6'b000010: alu_op = 4'b0111; // SRL
                    6'b100111: alu_op = 4'b1000; // NOR
                    default:   alu_op = 4'b0000;
                endcase
            end
            // ── ADDI ────────────────────────────────────────
            6'b001000: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0000; // ADD
            end
            // ── ANDI ────────────────────────────────────────
            6'b001100: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0010; // AND
                imm       = {16'b0, instruction[15:0]}; // zero extend
            end
            // ── ORI ─────────────────────────────────────────
            6'b001101: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0011; // OR
                imm       = {16'b0, instruction[15:0]};
            end
            // ── SLTI ────────────────────────────────────────
            6'b001010: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 4'b0100; // SLT
            end
            // ── LW ──────────────────────────────────────────
            6'b100011: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 4'b0000; // ADD (addr calc)
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
            end
            // ── SW ──────────────────────────────────────────
            6'b101011: begin
                alu_src   = 1'b1;
                alu_op    = 4'b0000; // ADD (addr calc)
                mem_write = 1'b1;
            end
            // ── BEQ ─────────────────────────────────────────
            6'b000100: begin
                alu_op = 4'b0001; // SUB → zero flag
                branch = 1'b1;
            end
            // ── BNE ─────────────────────────────────────────
            6'b000101: begin
                alu_op = 4'b0001; // SUB → zero flag (inverted in top)
                branch = 1'b1;
            end
            default: begin /* NOP */ end
        endcase
    end

endmodule
