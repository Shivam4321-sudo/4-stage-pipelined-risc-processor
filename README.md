# 4-Stage Pipelined RISC Processor

**Author:** Shivam Sharma | 225EC50006  
**Department:** Electronics & Communication Engineering  
**Date:** December 2025  
**Tools:** Xilinx Vivado, Verilog HDL

---

## Overview

A fully functional **4-stage pipelined RISC processor** designed in Verilog HDL using RTL design methodology. The processor implements a subset of the **RISC-V RV32I** instruction set and achieves efficient instruction throughput through pipelining, hazard detection, and data forwarding.

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────┐
│  Stage 1 │   │  Stage 2 │   │  Stage 3 │   │   Stage 4    │
│    IF    │──▶│    ID    │──▶│    EX    │──▶│   MEM / WB   │
│ Inst.    │   │ Decode + │   │ ALU +    │   │ Memory +     │
│ Fetch    │   │ Reg Read │   │ Forward  │   │ Write Back   │
└──────────┘   └──────────┘   └──────────┘   └──────────────┘
```

---

## Features

- **4-stage pipeline:** IF → ID → EX → MEM/WB
- **Full hazard handling:**
  - Load-use stall detection (1-cycle stall insertion)
  - EX–EX data forwarding
  - MEM–EX data forwarding
  - Branch flush (control hazard)
- **Supported instructions:** ADD, SUB, ADDI, AND, OR, XOR, SLT, SLL, SRL, SRA, LW, SW, BEQ, BNE, JAL, LUI, AUIPC
- **32 general-purpose registers** (R0 hardwired to 0)
- **Sign-extend immediate generator** for all instruction formats (I/S/B/U/J)
- **Verified in Xilinx Vivado** simulation with custom testbenches

---

## Repository Structure

```
risc_processor/
├── rtl/                         # RTL Source Files (Verilog)
│   ├── risc_processor.v         # Top-level integration module
│   ├── pc_register.v            # Program Counter
│   ├── instruction_memory.v     # Instruction Memory (ROM)
│   ├── register_file.v          # 32x32-bit Register File
│   ├── alu.v                    # Arithmetic Logic Unit
│   ├── alu_control.v            # ALU Control Decoder
│   ├── control_unit.v           # Main Control Unit
│   ├── imm_gen.v                # Immediate Generator
│   ├── data_memory.v            # Data Memory (RAM)
│   ├── hazard_detection.v       # Load-Use Hazard Detection
│   ├── forwarding_unit.v        # EX/MEM Forwarding Unit
│   └── pipeline_regs.v          # IF/ID, ID/EX, EX/MEM, MEM/WB Registers
│
├── tb/                          # Testbenches
│   ├── tb_risc_processor.v      # Full pipeline testbench
│   ├── tb_alu.v                 # ALU unit test
│   └── tb_forwarding.v          # Forwarding unit test
│
├── sim/                         # Simulation Files
│   ├── program.hex              # Test program (machine code)
│   └── simulate.tcl             # Vivado batch simulation script
│
├── constraints/
│   └── risc_processor.xdc       # Timing + I/O constraints (Basys3)
│
├── docs/
│   └── PIPELINE_DESIGN.md       # Detailed design documentation
│
└── README.md
```

---

## Pipeline Architecture

### Stage 1 — Instruction Fetch (IF)
- Reads instruction from instruction memory at current PC
- Computes PC+4 for sequential execution
- Supports branch/jump target redirection
- PC frozen on load-use stall

### Stage 2 — Instruction Decode (ID)
- Decodes opcode, rs1, rs2, rd, funct3, funct7
- Reads two source registers from register file
- Generates sign-extended immediate
- Main control unit produces all pipeline control signals
- Hazard detection unit monitors load-use conflicts

### Stage 3 — Execute (EX)
- Forwarding unit resolves data hazards without stalls (when possible)
- ALU control decodes funct3/funct7 to 4-bit operation select
- ALU performs the required operation
- Branch target address computed: `PC + imm`

### Stage 4 — Memory Access + Write Back (MEM/WB)
- Data memory read (LW) or write (SW)
- Branch decision: if `branch & zero` → flush IF/ID, redirect PC
- Write-back MUX: selects ALU result or memory data to write to register file

---

## Hazard Handling

### Data Hazards — Forwarding
```
Instruction 1:  ADD  x3, x1, x2      (result in EX/MEM)
Instruction 2:  ADD  x5, x3, x4      ← EX-EX forward from EX/MEM.rd
Instruction 3:  ADD  x6, x3, x7      ← MEM-EX forward from MEM/WB.rd
```
The forwarding unit checks:
- `EX/MEM.RegWrite && EX/MEM.Rd == ID/EX.Rs` → forward from EX/MEM
- `MEM/WB.RegWrite && MEM/WB.Rd == ID/EX.Rs` → forward from MEM/WB

### Load-Use Hazard — Stall
```
Instruction 1:  LW   x3, 0(x1)       (memory data not ready in EX)
Instruction 2:  ADD  x4, x3, x5      ← must stall 1 cycle
```
Hazard detection unit:
- Freezes PC and IF/ID register (stall)
- Inserts NOP bubble into ID/EX register

### Control Hazard — Branch Flush
```
BEQ  x1, x2, label    ← branch resolved in MEM stage
                       ← IF/ID flushed if branch taken
```

---

## How to Simulate in Xilinx Vivado

### Method 1: Vivado GUI

1. Open Vivado → **Create Project** → RTL Project
2. Add all files from `rtl/` as design sources
3. Add files from `tb/` as simulation sources
4. Copy `sim/program.hex` to your simulation working directory
5. Set `tb_risc_processor` as the top simulation module
6. Click **Run Simulation → Run Behavioral Simulation**
7. Add signals to waveform window and run for 1000+ ns

### Method 2: Batch Mode (TCL)
```bash
vivado -mode batch -source sim/simulate.tcl
```

### Method 3: Icarus Verilog (free, open-source)
```bash
# Compile
iverilog -o risc_sim rtl/*.v tb/tb_risc_processor.v

# Run
vvp risc_sim

# View waveforms
gtkwave tb_risc_processor.vcd
```

---

## Instruction Encoding Reference

| Instruction | Type | Opcode    | Operation                  |
|-------------|------|-----------|----------------------------|
| ADD         | R    | 0110011   | rd = rs1 + rs2             |
| SUB         | R    | 0110011   | rd = rs1 - rs2             |
| ADDI        | I    | 0010011   | rd = rs1 + imm             |
| AND/OR/XOR  | R    | 0110011   | rd = rs1 op rs2            |
| LW          | I    | 0000011   | rd = mem[rs1 + imm]        |
| SW          | S    | 0100011   | mem[rs1 + imm] = rs2       |
| BEQ         | B    | 1100011   | if rs1==rs2: PC += imm     |
| BNE         | B    | 1100011   | if rs1!=rs2: PC += imm     |
| JAL         | J    | 1101111   | rd = PC+4; PC += imm       |
| LUI         | U    | 0110111   | rd = imm << 12             |

---

## Simulation Results

The following scenarios were verified in Xilinx Vivado behavioral simulation:

| Test Case               | Result  |
|-------------------------|---------|
| Basic arithmetic (ADD, SUB, ADDI) | ✅ Pass |
| Logical ops (AND, OR, XOR) | ✅ Pass |
| EX–EX data forwarding   | ✅ Pass |
| MEM–EX data forwarding  | ✅ Pass |
| Load-use stall (LW→ADD) | ✅ Pass |
| Store + Load (SW/LW)    | ✅ Pass |
| BEQ branch taken        | ✅ Pass |
| BEQ branch not taken    | ✅ Pass |
| R0 hardwired zero       | ✅ Pass |

---

## Skills Demonstrated

- **Verilog HDL** — RTL-level design of all processor submodules
- **Pipeline Architecture** — 4-stage instruction pipeline design
- **Hazard Handling** — load-use detection, data forwarding, branch flush
- **ALU Design** — 10-operation arithmetic/logic unit
- **Testbench Writing** — self-checking Verilog testbenches
- **Xilinx Vivado** — synthesis, simulation, waveform analysis

---

## License

This project is for educational and portfolio purposes.  
© 2025 Shivam Sharma — Electronics & Communication Engineering
