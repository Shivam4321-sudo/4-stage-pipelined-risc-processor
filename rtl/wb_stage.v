// ============================================================
//  WB Stage — Write Back (includes Data Memory)
//  Author : Shivam Sharma | Dec 2025
// ============================================================
`timescale 1ns / 1ps

module wb_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] alu_result,
    input  wire [31:0] rs2_data,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire        mem_to_reg,
    output wire [31:0] mem_data_out,
    output wire [31:0] write_data
);

    // ── Data Memory (256 words × 32-bit) ─────────────────────
    reg [31:0] dmem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            dmem[i] = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            dmem[alu_result[9:2]] <= rs2_data;
    end

    // Asynchronous read
    assign mem_data_out = mem_read ? dmem[alu_result[9:2]] : 32'b0;

    // WB mux: memory data or ALU result
    assign write_data = mem_to_reg ? mem_data_out : alu_result;

endmodule
