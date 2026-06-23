# SPDX-FileCopyrightText: 2026 TeamVKU and contributors
# SPDX-License-Identifier: MIT
#
# Wrapper around LibreLane's default pad-ring script. GF180 analog pads expose
# ASIG5V on Metal2, while OpenROAD's default terminal placement expects the
# top routing layer. Allowing non-top-layer terminals lets the official
# workshop padring use both digital PAD pins and analog ASIG5V pins.

rename place_io_terminals __sfe_orig_place_io_terminals

proc place_io_terminals {args} {
    if {[lsearch -exact $args "-allow_non_top_layer"] < 0} {
        lappend args "-allow_non_top_layer"
    }
    __sfe_orig_place_io_terminals {*}$args
}

source $::env(SCRIPTS_DIR)/openroad/common/pad_cfg.tcl
