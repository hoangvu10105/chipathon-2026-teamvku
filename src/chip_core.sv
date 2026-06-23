// SPDX-FileCopyrightText: 2026 TeamVKU and contributors
// SPDX-License-Identifier: MIT
//
// SSCS Chipathon 2026 workshop-slot adapter for the SFE audio frontend.
// The slot has only 20 bidirectional digital pads, so this wrapper uses an
// internal deterministic filterbank-stimulus generator and exports compact AER
// status on the bidir pads.

`default_nettype none

module chip_core #(
    parameter int NUM_INPUT_PADS  = 1,
    parameter int NUM_BIDIR_PADS  = 20,
    parameter int NUM_ANALOG_PADS = 60
) (
`ifdef USE_POWER_PINS
    inout  wire VDD,
    inout  wire VSS,
`endif

    input  wire clk,
    input  wire rst_n,

    input  wire [NUM_INPUT_PADS-1:0] input_in,
    output wire [NUM_INPUT_PADS-1:0] input_pu,
    output wire [NUM_INPUT_PADS-1:0] input_pd,

    input  wire [NUM_BIDIR_PADS-1:0] bidir_in,
    output wire [NUM_BIDIR_PADS-1:0] bidir_out,
    output wire [NUM_BIDIR_PADS-1:0] bidir_oe,
    output wire [NUM_BIDIR_PADS-1:0] bidir_cs,
    output wire [NUM_BIDIR_PADS-1:0] bidir_sl,
    output wire [NUM_BIDIR_PADS-1:0] bidir_ie,
    output wire [NUM_BIDIR_PADS-1:0] bidir_pu,
    output wire [NUM_BIDIR_PADS-1:0] bidir_pd,

    inout  wire [NUM_ANALOG_PADS-1:0] analog
);

    localparam int NUM_CHANNELS = 20;
    localparam int DATA_WIDTH   = 16;

    logic rst_meta_n;
    logic rst_core_n;
    logic run_en_q;
    logic fixed_threshold_q;
    logic decay_tick_2_q;
    logic disable_refractory_q;
    logic input_en_q;

    // Keep slow pad outputs off high-fanout core control nets. The external
    // reset remains asynchronous at the pad boundary, then releases
    // synchronously into the SFE core.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rst_meta_n <= 1'b0;
            rst_core_n <= 1'b0;
        end else begin
            rst_meta_n <= 1'b1;
            rst_core_n <= rst_meta_n;
        end
    end

    always_ff @(posedge clk or negedge rst_core_n) begin
        if (!rst_core_n) begin
            run_en_q <= 1'b0;
            fixed_threshold_q <= 1'b0;
            decay_tick_2_q <= 1'b0;
            disable_refractory_q <= 1'b0;
            input_en_q <= 1'b0;
        end else begin
            run_en_q <= bidir_in[0];
            fixed_threshold_q <= bidir_in[1];
            decay_tick_2_q <= bidir_in[2];
            disable_refractory_q <= bidir_in[3];
            input_en_q <= input_in[0];
        end
    end

    wire core_en = run_en_q | input_en_q;

    assign input_pu = '0;
    assign input_pd = '0;

    // Pads 0..3 are configuration inputs; pads 4..19 are status outputs.
    assign bidir_oe = {{(NUM_BIDIR_PADS-4){1'b1}}, 4'b0000};
    assign bidir_ie = ~bidir_oe;
    assign bidir_cs = '0;
    assign bidir_sl = '1;
    assign bidir_pu = '0;
    assign bidir_pd = '0;

    wire event_valid;
    wire event_direction;
    wire [4:0] event_channel;
    wire [31:0] event_timestamp;
    wire fifo_full;
    wire fifo_overflow;
    wire pending_overflow;
    wire [4:0] fifo_level;
    wire [NUM_CHANNELS-1:0] spike_up_debug;
    wire [NUM_CHANNELS-1:0] spike_down_debug;

    logic [7:0] phase_q;
    logic [7:0] slow_q;
    logic heartbeat_q;
    logic signed [NUM_CHANNELS*DATA_WIDTH-1:0] x_flat;

    integer ch;
    always_ff @(posedge clk) begin
        if (!rst_core_n) begin
            phase_q <= 8'd0;
            slow_q <= 8'd0;
            heartbeat_q <= 1'b0;
            x_flat <= '0;
        end else if (core_en) begin
            phase_q <= phase_q + 8'd3;
            slow_q <= slow_q + 8'd1;
            heartbeat_q <= slow_q[7];
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                x_flat[ch*DATA_WIDTH +: DATA_WIDTH] <=
                    $signed({1'b0, phase_q}) - 16'sd128 + $signed(ch[7:0]);
            end
        end
    end

    // ────────────────────────────────────────────────────────
    // Reset buffering: rst_core_n fans out to >800 loads.
    // Instead of RTL buffer tree (which Yosys optimizes away),
    // rely on SYNTH_MAX_FANOUT + MAX_FANOUT_CONSTRAINT in
    // config.yaml to tell synthesis/OpenROAD to buffer.
    // Explicit (* keep *) buffer chain prevents optimization.
    // ────────────────────────────────────────────────────────
    (* keep = "true" *) logic rst_buf_0;
    (* keep = "true" *) logic rst_buf_1;
    (* keep = "true" *) logic rst_buf_2;
    gf180mcu_fd_sc_mcu7t5v0__buf_8 u_rst_buf_0 (.I(rst_core_n),  .Z(rst_buf_0));
    gf180mcu_fd_sc_mcu7t5v0__buf_8 u_rst_buf_1 (.I(rst_buf_0),   .Z(rst_buf_1));
    gf180mcu_fd_sc_mcu7t5v0__buf_8 u_rst_buf_2 (.I(rst_buf_1),   .Z(rst_buf_2));

    sfe_audio_frontend_top #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(16),
        .REFRACTORY_LEN(4)
    ) u_sfe (
        .clk(clk),
        .rst_n(rst_buf_2),
        .en(core_en),
        .channel_en({NUM_CHANNELS{1'b1}}),
        .cfg_enable_adaptive(~fixed_threshold_q),
        .cfg_enable_leakage(~fixed_threshold_q),
        .cfg_enable_refractory(~disable_refractory_q),
        .cfg_enable_decay_tick(decay_tick_2_q),
        .cfg_decay_tick_mask(4'h1),
        .cfg_load(1'b0),
        .cfg_theta_min(16'd16),
        .cfg_theta_max(16'd1024),
        .cfg_theta_init(16'd32),
        .cfg_refractory_len(3'd4),
        .x_flat(x_flat),
        .event_ready(1'b1),
        .event_valid(event_valid),
        .event_channel(event_channel),
        .event_direction(event_direction),
        .event_timestamp(event_timestamp),
        .fifo_full(fifo_full),
        .fifo_overflow(fifo_overflow),
        .pending_overflow(pending_overflow),
        .fifo_level(fifo_level),
        .spike_up_debug(spike_up_debug),
        .spike_down_debug(spike_down_debug)
    );

    assign bidir_out[3:0]   = 4'b0000;
    assign bidir_out[4]     = event_valid;
    assign bidir_out[5]     = event_direction;
    assign bidir_out[10:6]  = event_channel;
    assign bidir_out[17:11] = event_timestamp[6:0];
    assign bidir_out[18]    = fifo_full | fifo_overflow | pending_overflow;
    assign bidir_out[19]    = heartbeat_q;

    // The workshop slot exposes analog pads, but this digital demonstration
    // wrapper does not drive or sense them.
    wire _unused;
    assign _unused = &{1'b0, spike_up_debug, spike_down_debug, fifo_level};

endmodule

`default_nettype wire
