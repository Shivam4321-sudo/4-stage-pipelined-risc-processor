// =============================================================================
// Module      : forwarding_unit.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Forwarding Unit — resolves EX-EX and MEM-EX data hazards
//               by selecting correct operand source for the ALU
//
// Forwarding Priority:
//   EX hazard  (highest) : forward from EX/MEM pipeline register
//   MEM hazard (lower)   : forward from MEM/WB pipeline register
//   No hazard            : use register file output
// =============================================================================

`timescale 1ns / 1ps

module forwarding_unit (
    input  wire [4:0]  ex_rs1,
    input  wire [4:0]  ex_rs2,
    input  wire        ex_mem_reg_write,
    input  wire [4:0]  ex_mem_rd,
    input  wire        mem_wb_reg_write,
    input  wire [4:0]  mem_wb_rd,
    // 00=reg file, 01=MEM/WB forward, 10=EX/MEM forward
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);

    always @(*) begin
        // Forward A (RS1)
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == ex_rs1))
            forward_a = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == ex_rs1) &&
                 !(ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == ex_rs1)))
            forward_a = 2'b01;
        else
            forward_a = 2'b00;

        // Forward B (RS2)
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == ex_rs2))
            forward_b = 2'b10;
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == ex_rs2) &&
                 !(ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == ex_rs2)))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end

endmodule
