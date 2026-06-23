# Standalone OpenROAD repair script for SFE chip_top
# Fixes max_slew, max_cap, max_fanout violations
# Run AFTER LibreLane flow completes
# Usage: openroad -exit -no_splash this_script.tcl

puts "\[INFO] SFE-REPAIR: Loading design..."

# Read design
read_lef { /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef/gf180mcu_fd_sc_mcu7t5v0__nom.tlef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lef/gf180mcu_fd_sc_mcu7t5v0.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__asig_5p0.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__bi_24t.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__cor.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__dvdd.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__dvss.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__fill1.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__fill5.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__fill10.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__in_c.lef /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_io/lef/gf180mcu_fd_io__in_s.lef }
read_def final/def/chip_top.def

# Read liberty files
read_liberty -corner ss_125C_4v50 /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib/gf180mcu_fd_sc_mcu7t5v0__ss_125C_4v50.lib
read_liberty -corner tt_025C_5v00 /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib/gf180mcu_fd_sc_mcu7t5v0__tt_025C_5v00.lib
read_liberty -corner ff_n40C_5v50 /foss/pdks/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib/gf180mcu_fd_sc_mcu7t5v0__ff_n40C_5v50.lib

# Link design
link_design chip_top

# Read SDC
read_sdc librelane/chip_top.sdc

# Set MODERATE constraints (tighter than default but won't OOM)
set_max_transition 2.0 [current_design]
set_max_capacitance 0.15 [current_design]
set_max_fanout 10 [current_design]

puts "\[INFO] SFE-REPAIR: Initial violations..."
report_checks -fields {slew cap fanout} -format full_clock_expanded -group_count 5

# Run repair in stages to avoid OOM
puts "\[INFO] SFE-REPAIR: Stage 1 - Buffer high-fanout nets..."
repair_tie_fanout -separation 20 [get_nets -hierarchical *]

puts "\[INFO] SFE-REPAIR: Stage 2 - Repair design..."
repair_design

puts "\[INFO] SFE-REPAIR: Stage 3 - Repair timing (upsize for slew)..."
repair_timing -setup -hold -repair_tns 0

puts "\[INFO] SFE-REPAIR: Stage 4 - Legalize..."
detailed_placement

puts "\[INFO] SFE-REPAIR: Stage 5 - Final cleanup..."
repair_design

puts "\[INFO] SFE-REPAIR: Final violations..."
report_checks -fields {slew cap fanout} -format full_clock_expanded -group_count 5

# Write fixed DEF
puts "\[INFO] SFE-REPAIR: Writing fixed DEF..."
write_def final/def/chip_top_fixed.def

# Report area
report_design_area

puts "\[INFO] SFE-REPAIR: Done."
