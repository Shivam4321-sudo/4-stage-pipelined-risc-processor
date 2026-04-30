// =============================================================================
// Module      : register_file.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : 32 x 32-bit Register File with dual read ports and one write port
//               R0 is hardwired to zero (RISC convention)
// =============================================================================

`timescale 1ns / 1ps

module register_file (
    input  wire        clk,
    input  wire        rst,
    // Read Port A
    input  wire [4:0]  rs1,
    output wire [31:0] read_data1,
    // Read Port B
    input  wire [4:0]  rs2,
    output wire [31:0] read_data2,
    // Write Port
    input  wire        reg_write,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data
);

    reg [31:0] registers [0:31];
    integer i;

    // Synchronous write, asynchronous read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else begin
            if (reg_write && (rd != 5'b0))   // R0 always zero
                registers[rd] <= write_data;
        end
    end

    // Asynchronous reads — combinational
    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

endmodule
