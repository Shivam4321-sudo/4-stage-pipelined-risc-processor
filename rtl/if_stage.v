// ============================================================
//  IF Stage — Instruction Fetch
//  Author : Shivam Sharma | Dec 2025
// ============================================================
`timescale 1ns / 1ps

module if_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        branch_taken,
    input  wire [31:0] branch_target,
    output reg  [31:0] pc_out,
    output wire [31:0] instruction
);

    // ── Program Counter ──────────────────────────────────────
    reg [31:0] pc;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0000_0000;
        else if (!stall) begin
            if (branch_taken)
                pc <= branch_target;
            else
                pc <= pc + 32'd4;
        end
    end

    always @(*) pc_out = pc;

    // ── Instruction Memory (ROM — 256 words) ─────────────────
    reg [31:0] imem [0:255];

    initial begin
        $readmemh("../sim/imem_init.hex", imem);
    end

    assign instruction = imem[pc[9:2]];   // word-addressed

endmodule
