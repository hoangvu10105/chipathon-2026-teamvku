// SPDX-FileCopyrightText: 2026 TeamVKU and contributors
// SPDX-License-Identifier: MIT
//
// Lightweight GF180 IO-cell blackboxes for LibreLane/Verilator front-end lint.
// Physical implementation still uses the GF180 PDK LEF/GDS/lib views.

`default_nettype none

(* blackbox *) module gf180mcu_fd_io__asig_5p0 (
    inout wire ASIG5V,
    inout wire DVDD,
    inout wire DVSS,
    inout wire VDD,
    inout wire VSS
);
endmodule

(* blackbox *) module gf180mcu_fd_io__bi_24t (
    input  wire CS,
    input  wire SL,
    input  wire IE,
    input  wire OE,
    input  wire PU,
    input  wire PD,
    input  wire A,
    inout  wire PAD,
    output wire Y,
    inout  wire DVDD,
    inout  wire DVSS,
    inout  wire VDD,
    inout  wire VSS
);
endmodule

(* blackbox *) module gf180mcu_fd_io__cor (
    inout wire DVDD,
    inout wire DVSS,
    inout wire VDD,
    inout wire VSS
);
endmodule

(* blackbox *) module gf180mcu_fd_io__dvdd (
    inout wire DVDD,
    inout wire DVSS,
    inout wire VSS
);
endmodule

(* blackbox *) module gf180mcu_fd_io__dvss (
    inout wire DVDD,
    inout wire DVSS,
    inout wire VDD
);
endmodule

(* blackbox *) module gf180mcu_fd_io__in_c (
    input  wire PU,
    input  wire PD,
    inout  wire PAD,
    output wire Y,
    inout  wire DVDD,
    inout  wire DVSS,
    inout  wire VDD,
    inout  wire VSS
);
endmodule

(* blackbox *) module gf180mcu_fd_io__in_s (
    input  wire PU,
    input  wire PD,
    inout  wire PAD,
    output wire Y,
    inout  wire DVDD,
    inout  wire DVSS,
    inout  wire VDD,
    inout  wire VSS
);
endmodule

`default_nettype wire
