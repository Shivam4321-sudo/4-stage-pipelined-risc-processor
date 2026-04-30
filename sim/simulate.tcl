# =============================================================================
# Script      : simulate.tcl
# Project     : 4-Stage Pipelined RISC Processor
# Author      : Shivam Sharma
# Description : Vivado XSim batch simulation script
# Usage       : vivado -mode batch -source sim/simulate.tcl
# =============================================================================

# Create project
create_project risc_processor ./vivado_project -part xc7a35tcpg236-1 -force

# Add RTL sources
add_files -norecurse {
    rtl/pc_register.v
    rtl/instruction_memory.v
    rtl/register_file.v
    rtl/alu.v
    rtl/alu_control.v
    rtl/control_unit.v
    rtl/imm_gen.v
    rtl/data_memory.v
    rtl/hazard_detection.v
    rtl/forwarding_unit.v
    rtl/pipeline_regs.v
    rtl/risc_processor.v
}

# Add testbenches
add_files -fileset sim_1 -norecurse {
    tb/tb_risc_processor.v
    tb/tb_alu.v
    tb/tb_forwarding.v
}

# Copy hex file to simulation directory
file copy -force sim/program.hex ./vivado_project/risc_processor.sim/sim_1/behav/xsim/program.hex

# Set top module for simulation
set_property top tb_risc_processor [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch simulation
launch_simulation

# Run for 2000 ns
run 2000ns

# Log all signals
log_wave -recursive *

puts "Simulation complete. Open Vivado GUI to inspect waveforms."
