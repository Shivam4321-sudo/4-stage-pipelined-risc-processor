# Pipeline Design Documentation

**Project:** 4-Stage Pipelined RISC Processor  
**Author:** Shivam Sharma | 225EC50006  
**Date:** December 2025

---

## 1. Design Philosophy

The processor is modeled after the classic 5-stage RISC pipeline, simplified to 4 stages by merging the Memory Access and Write Back stages into a single MEM/WB stage. This reduces hardware complexity while retaining the performance benefits of pipelining.

---

## 2. Stage-by-Stage Design

### 2.1 Instruction Fetch (IF)

**Inputs:** PC register output  
**Outputs:** Instruction word, PC value → IF/ID register

The IF stage fetches one instruction per clock cycle from the instruction memory. The PC is updated to PC+4 by default. On a taken branch, the PC is redirected to the branch target and the IF/ID pipeline register is flushed to discard the incorrectly fetched instruction.

Key logic:
```
pc_next = branch_taken ? branch_target : pc + 4
```

The PC is frozen (pc_write = 0) when a load-use hazard is detected to allow the pipeline to stall correctly.

---

### 2.2 Instruction Decode (ID)

**Inputs:** IF/ID register (PC, instruction)  
**Outputs:** Control signals, register data, immediate → ID/EX register

The decode stage performs three functions simultaneously:
1. **Opcode decoding** — the control unit produces all pipeline control signals
2. **Register read** — two source registers are read from the register file
3. **Immediate generation** — the immediate generator sign-extends the appropriate field based on instruction format

The hazard detection unit compares the destination register of the instruction in EX (from the ID/EX register) against the source registers of the current instruction. If a load-use hazard is found, all control signals passed to ID/EX are zeroed (NOP bubble) and the PC + IF/ID register are frozen for one cycle.

---

### 2.3 Execute (EX)

**Inputs:** ID/EX register  
**Outputs:** ALU result, branch target, zero flag → EX/MEM register

This is the most complex stage. It includes:

**Forwarding MUX (Operand A):**
```
forward_a = 2'b10 → use EX/MEM ALU result   (EX-EX hazard)
forward_a = 2'b01 → use MEM/WB write data   (MEM-EX hazard)
forward_a = 2'b00 → use register file data  (no hazard)
```

**Forwarding MUX (Operand B):**  
Same logic as Operand A but for RS2.

**ALU Source MUX:**  
After forwarding, Operand B is further muxed to select either the forwarded register value or the sign-extended immediate, controlled by `alu_src`.

**Branch Target:**  
`branch_target = ID/EX.PC + ID/EX.imm`  
(The B-type immediate is pre-shifted left by 1 in the immediate generator.)

---

### 2.4 Memory + Write Back (MEM/WB)

**Inputs:** EX/MEM register  
**Outputs:** Write data → register file; branch decision → PC

**Memory access:**  
- Load (LW): reads 32-bit word from data memory at ALU-computed address
- Store (SW): writes RS2 value to data memory at ALU-computed address

**Branch resolution:**  
```
branch_taken = (branch & zero) | jump
```
If taken: the PC is redirected to the branch target (from EX/MEM register) and the IF/ID register is flushed.

**Write Back MUX:**
```
wb_write_data = mem_to_reg ? mem_read_data : alu_result
```
The selected value is written to the destination register in the register file.

---

## 3. Hazard Summary Table

| Hazard Type     | Detection Mechanism        | Resolution           | Penalty |
|-----------------|---------------------------|----------------------|---------|
| EX-EX data      | Forwarding unit            | Forward EX/MEM→EX   | 0 cycles |
| MEM-EX data     | Forwarding unit            | Forward MEM/WB→EX   | 0 cycles |
| Load-use        | Hazard detection unit      | Stall + NOP bubble  | 1 cycle  |
| Control (branch)| Branch resolved in MEM/WB  | Flush IF/ID         | 1 cycle  |

---

## 4. Control Signal Truth Table

| Instruction | RegWrite | ALUSrc | MemWrite | MemRead | MemToReg | Branch | Jump | ALUOp |
|-------------|----------|--------|----------|---------|----------|--------|------|-------|
| R-type      | 1        | 0      | 0        | 0       | 0        | 0      | 0    | 10    |
| I-type      | 1        | 1      | 0        | 0       | 0        | 0      | 0    | 11    |
| LW          | 1        | 1      | 0        | 1       | 1        | 0      | 0    | 00    |
| SW          | 0        | 1      | 1        | 0       | X        | 0      | 0    | 00    |
| BEQ/BNE     | 0        | 0      | 0        | 0       | X        | 1      | 0    | 01    |
| JAL         | 1        | X      | 0        | 0       | 0        | 0      | 1    | 00    |
| LUI         | 1        | 1      | 0        | 0       | 0        | 0      | 0    | 00    |

---

## 5. Module Hierarchy

```
risc_processor (top)
├── pc_register
├── instruction_memory
├── if_id_reg
├── register_file
├── control_unit
├── imm_gen
├── hazard_detection
├── id_ex_reg
├── forwarding_unit
├── alu_control
├── alu
├── ex_mem_reg
├── data_memory
├── mem_wb_reg
└── (write-back logic — combinational in top)
```

---

## 6. Timing Analysis

At 100 MHz (10 ns clock period), the critical path runs through:

```
Register File Read → Forwarding MUX → ALU → EX/MEM Register
```

Estimated critical path delay (Artix-7, -1 speed grade): ~7.2 ns  
Timing slack: ~2.8 ns (meets timing at 100 MHz)

---

## 7. Resource Utilization (Estimated — Artix-7 xc7a35t)

| Resource   | Used  | Available | Utilization |
|------------|-------|-----------|-------------|
| LUTs       | ~380  | 20,800    | ~1.8%       |
| FFs        | ~260  | 41,600    | ~0.6%       |
| BRAM       | 0     | 50        | 0%          |
| DSP48      | 0     | 90        | 0%          |

---

## 8. Known Limitations

1. **No interrupt/exception support** — the current implementation does not handle traps or CSR instructions.
2. **Single-cycle memory** — both instruction and data memories are modeled as synchronous BRAM with no latency. Real DRAM would require additional stall logic.
3. **Branch resolved in MEM stage** — causes a 1-cycle flush penalty. A more aggressive implementation would resolve branches in ID.
4. **No cache** — direct memory access only.

These are intentional simplifications for a student project targeting RTL design and pipelining concepts.
