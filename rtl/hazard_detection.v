// =============================================================================
// Module      : hazard_detection.v
// Project     : 4-Stage Pipelined RISC Processor
// Author      : Shivam Sharma
// Description : Hazard Detection Unit — detects load-use data hazards and
//               generates stall signals to freeze IF/ID and insert bubble
// =============================================================================

`timescale 1ns / 1ps

module hazard_detection (
    // From ID/EX pipeline register
    input  wire        id_ex_mem_read,   // Is EX stage doing a load?
    input  wire [4:0]  id_ex_rd,         // Destination register in EX stage
    // From IF/ID pipeline register (current instruction being decoded)
    input  wire [4:0]  if_id_rs1,        // Source register 1 of instruction in ID
    input  wire [4:0]  if_id_rs2,        // Source register 2 of instruction in ID
    // Stall outputs
    output wire        pc_write,         // 0 = stall PC (freeze)
    output wire        if_id_write,      // 0 = stall IF/ID register (freeze)
    output wire        control_mux_sel   // 1 = insert NOP bubble into ID/EX
);

    // Load-use hazard:
    // If the instruction in EX is a load AND its destination matches
    // a source of the instruction currently in ID → must stall 1 cycle
    wire load_use_hazard;
    assign load_use_hazard = id_ex_mem_read &&
                             ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) &&
                             (id_ex_rd != 5'b0);

    assign pc_write        = ~load_use_hazard;   // Freeze PC on hazard
    assign if_id_write     = ~load_use_hazard;   // Freeze IF/ID on hazard
    assign control_mux_sel =  load_use_hazard;   // Insert bubble (NOP) into ID/EX

endmodule
