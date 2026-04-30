// =============================================================================
// Module      : data_memory.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Data Memory — 256 x 32-bit words, synchronous write,
//               asynchronous read. Supports LW/SW word access.
// =============================================================================

`timescale 1ns / 1ps

module data_memory (
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[9:2]] <= write_data;
    end

    // Asynchronous read
    assign read_data = mem_read ? mem[addr[9:2]] : 32'b0;

endmodule
