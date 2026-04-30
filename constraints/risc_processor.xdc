# =============================================================================
# File        : risc_processor.xdc
# Project     : 4-Stage Pipelined RISC Processor
# Author      : Shivam Sharma
# Board       : Digilent Basys3 (Artix-7 xc7a35t)
# Description : Timing and I/O constraints
# =============================================================================

# ── Clock Constraint (100 MHz onboard clock) ──────────────────────────────────
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} \
    [get_ports clk]

# ── Input Delays ──────────────────────────────────────────────────────────────
set_input_delay -clock [get_clocks sys_clk_pin] -min -add_delay 1.000 \
    [get_ports rst]
set_input_delay -clock [get_clocks sys_clk_pin] -max -add_delay 3.000 \
    [get_ports rst]

# ── Physical Pin Assignments (Basys3) ─────────────────────────────────────────
# 100 MHz system clock
set_property PACKAGE_PIN W5      [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]

# Reset button (BTNC)
set_property PACKAGE_PIN U18     [get_ports rst]
set_property IOSTANDARD  LVCMOS33 [get_ports rst]

# ── Timing Exceptions ─────────────────────────────────────────────────────────
# Relax timing on debug outputs (not on critical path)
set_false_path -from [get_clocks sys_clk_pin] \
               -to   [get_ports {debug_pc[*] debug_alu_result[*] \
                                  debug_reg_write_data[*] debug_rd[*]}]
