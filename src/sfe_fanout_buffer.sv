// SPDX-FileCopyrightText: 2026 TeamVKU and contributors
// SPDX-License-Identifier: MIT
//
// Fanout buffer tree for high-fanout control signals.
// Splits a single input into multiple buffered outputs,
// keeping fanout per buffer below MAX_FANOUT.
// Yosys/OpenROAD will map assign chains to buffer cells.

`default_nettype none

module sfe_fanout_buffer #(
    parameter int FANOUT = 32,
    parameter int MAX_FANOUT = 10
) (
    input  logic                 in,
    output logic [FANOUT-1:0]    out
);
    // Compute number of stages needed
    localparam int STAGE1_COUNT = (FANOUT + MAX_FANOUT - 1) / MAX_FANOUT;
    localparam int STAGE1_LOAD  = (FANOUT + STAGE1_COUNT - 1) / STAGE1_COUNT;
    
    // Stage 1: first-level buffers (drives at most MAX_FANOUT stage-2 buffers)
    (* keep *) logic [STAGE1_COUNT-1:0] stage1;
    
    genvar i, j;
    generate
        // First buffer stage
        for (i = 0; i < STAGE1_COUNT; i = i + 1) begin : gen_stage1
            assign stage1[i] = in;
        end
        
        // Second buffer stage - each drives a subset of outputs
        for (i = 0; i < STAGE1_COUNT; i = i + 1) begin : gen_stage2
            for (j = 0; j < STAGE1_LOAD; j = j + 1) begin : gen_out
                localparam int IDX = i * STAGE1_LOAD + j;
                if (IDX < FANOUT) begin : gen_valid
                    assign out[IDX] = stage1[i];
                end
            end
        end
        
        // Handle remaining outputs
        if (FANOUT <= MAX_FANOUT) begin : gen_direct
            // No buffering needed - fanout is already within limit
            assign out = {FANOUT{in}};
        end
    endgenerate
endmodule

`default_nettype wire
