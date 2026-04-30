// =============================================================================
// Module      : instruction_memory.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Instruction Memory (ROM) - 256 x 32-bit words
// =============================================================================

`timescale 1ns / 1ps

module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] mem [0:255];

    initial begin
        $readmemh("program.hex", mem);
    end

    // Word-aligned read (ignore lower 2 bits)
    assign instruction = mem[addr[9:2]];

endmodule
