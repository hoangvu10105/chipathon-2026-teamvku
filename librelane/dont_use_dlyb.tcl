# Build #12: Prevent dlyb_* delay buffers.
# This script is sourced during OpenROAD initialization (before resizer).
# dlyb cells add ~2ns delay/stage and create antenna-prone long Metal2 routes.
# Ban them so the resizer uses buf_4 / buf_8 which are faster and route shorter.

set dlyb_pattern "gf180mcu_fd_sc_mcu7t5v0__dlyb_*"
set dlyb_count 0

# Try to exclude dlyb cells from resizer consideration
if { [llength [get_lib_cells -quiet $dlyb_pattern]] > 0 } {
    foreach cell [get_lib_cells $dlyb_pattern] {
        catch { set_dont_use $cell }
        incr dlyb_count
    }
    puts "\[INFO\] Build12: Set dont_use on $dlyb_count dlyb cells"
} else {
    puts "\[INFO\] Build12: No dlyb cells found to exclude"
}
