// =============================================================================
// Module      : pc_register.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Program Counter Register with synchronous reset and branch support
// =============================================================================

`timescale 1ns / 1ps

module pc_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        pc_write,       // Stall control: 0 = freeze PC
    input  wire [31:0] pc_next,        // Next PC value (branch or PC+4)
    output reg  [31:0] pc_out          // Current PC
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h0000_0000;
        else if (pc_write)
            pc_out <= pc_next;
        // else: hold current value (stall)
    end

endmodule
