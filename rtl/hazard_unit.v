// ============================================================
//  Hazard Detection Unit
//  Author : Shivam Sharma | Dec 2025
//
//  Detects Load-Use hazard:
//    If EX stage is a LW and its destination matches
//    a source register in ID stage → stall 1 cycle + flush EX
// ============================================================
`timescale 1ns / 1ps

module hazard_unit (
    input  wire       id_ex_mem_read,   // EX stage is a load
    input  wire [4:0] id_ex_rd,         // EX stage destination
    input  wire [4:0] if_id_rs1,        // ID stage source 1
    input  wire [4:0] if_id_rs2,        // ID stage source 2
    output reg        stall,            // Freeze IF + ID registers
    output reg        flush             // Insert bubble into EX
);

    always @(*) begin
        if (id_ex_mem_read &&
           ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
        begin
            stall = 1'b1;
            flush = 1'b1;
        end else begin
            stall = 1'b0;
            flush = 1'b0;
        end
    end

endmodule
