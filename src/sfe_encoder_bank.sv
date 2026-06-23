// SPDX-FileCopyrightText: 2026 TeamVKU and contributors
// SPDX-License-Identifier: MIT
//
// SFE Encoder Bank - 32-channel wrapper with fanout buffering.
// High-fanout control signals are buffered through sfe_fanout_buffer
// to keep per-buffer fanout within 10, eliminating max_fanout violations.

`timescale 1ns/1ps
`default_nettype none

module sfe_encoder_bank #(
    parameter int NUM_CHANNELS      = 32,
    parameter int DATA_WIDTH        = 16,
    parameter int THETA_WIDTH       = 16,
    parameter int LEAK_SHIFT        = 4,
    parameter int THETA_DEC_SHIFT   = 6,
    parameter int REFRACTORY_LEN    = 4,
    parameter int REFRACTORY_WIDTH  = (REFRACTORY_LEN <= 1) ? 1 : $clog2(REFRACTORY_LEN + 1),
    parameter int DECAY_TICK_WIDTH  = 4,
    parameter int THETA_MIN         = 16,
    parameter int THETA_MAX         = 1024,
    parameter int THETA_INIT        = 32,
    parameter bit ENABLE_ADAPTIVE   = 1'b1,
    parameter bit ENABLE_LEAKAGE    = 1'b1,
    parameter bit ENABLE_REFRACTORY = 1'b1,
    // Fanout buffer control
    parameter int MAX_FANOUT        = 10
) (
    input  logic                                      clk,
    input  logic                                      rst_n,
    input  logic                                      en,
    input  logic        [NUM_CHANNELS-1:0]            channel_en,
    input  logic                                      cfg_enable_adaptive,
    input  logic                                      cfg_enable_leakage,
    input  logic                                      cfg_enable_refractory,
    input  logic                                      cfg_enable_decay_tick,
    input  logic        [DECAY_TICK_WIDTH-1:0]        cfg_decay_tick_mask,
    input  logic                                      cfg_load,
    input  logic        [THETA_WIDTH-1:0]             cfg_theta_min,
    input  logic        [THETA_WIDTH-1:0]             cfg_theta_max,
    input  logic        [THETA_WIDTH-1:0]             cfg_theta_init,
    input  logic        [REFRACTORY_WIDTH-1:0]        cfg_refractory_len,
    input  logic signed [NUM_CHANNELS*DATA_WIDTH-1:0] x_flat,
    output logic        [NUM_CHANNELS-1:0]            spike_up,
    output logic        [NUM_CHANNELS-1:0]            spike_down
);

    // ============================================================
    // Fanout-buffered copies of high-fanout control signals
    // Each buffer drives at most MAX_FANOUT loads
    // ============================================================
    
    // 1-bit control signals (fanout = NUM_CHANNELS = 32)
    logic [NUM_CHANNELS-1:0] en_buf;
    logic [NUM_CHANNELS-1:0] rst_n_buf;
    logic [NUM_CHANNELS-1:0] cfg_enable_adaptive_buf;
    logic [NUM_CHANNELS-1:0] cfg_enable_leakage_buf;
    logic [NUM_CHANNELS-1:0] cfg_enable_refractory_buf;
    logic [NUM_CHANNELS-1:0] decay_tick_buf;
    logic [NUM_CHANNELS-1:0] cfg_load_buf;
    
    // Multi-bit control signals
    logic [THETA_WIDTH-1:0]       cfg_theta_min_buf   [0:NUM_CHANNELS-1];
    logic [THETA_WIDTH-1:0]       cfg_theta_max_buf   [0:NUM_CHANNELS-1];
    logic [THETA_WIDTH-1:0]       cfg_theta_init_buf  [0:NUM_CHANNELS-1];
    logic [REFRACTORY_WIDTH-1:0]  cfg_refractory_len_buf [0:NUM_CHANNELS-1];
    
    // Buffer trees for 1-bit signals
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_en                 (.in(en),                    .out(en_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_rst_n             (.in(rst_n),                 .out(rst_n_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_cfg_enable_adaptive(.in(cfg_enable_adaptive),  .out(cfg_enable_adaptive_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_cfg_enable_leakage (.in(cfg_enable_leakage),   .out(cfg_enable_leakage_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_cfg_enable_refractory(.in(cfg_enable_refractory), .out(cfg_enable_refractory_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_decay_tick        (.in(decay_tick),           .out(decay_tick_buf));
    sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf_cfg_load           (.in(cfg_load),             .out(cfg_load_buf));

    // Buffer trees for multi-bit signals (each bit gets its own tree)
    genvar bit_idx;
    generate
        for (bit_idx = 0; bit_idx < THETA_WIDTH; bit_idx = bit_idx + 1) begin : gen_theta_min_buf
            logic [NUM_CHANNELS-1:0] bit_out;
            sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf (.in(cfg_theta_min[bit_idx]), .out(bit_out));
            genvar ch;
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_assign
                assign cfg_theta_min_buf[ch][bit_idx] = bit_out[ch];
            end
        end
        for (bit_idx = 0; bit_idx < THETA_WIDTH; bit_idx = bit_idx + 1) begin : gen_theta_max_buf
            logic [NUM_CHANNELS-1:0] bit_out;
            sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf (.in(cfg_theta_max[bit_idx]), .out(bit_out));
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_assign
                assign cfg_theta_max_buf[ch][bit_idx] = bit_out[ch];
            end
        end
        for (bit_idx = 0; bit_idx < THETA_WIDTH; bit_idx = bit_idx + 1) begin : gen_theta_init_buf
            logic [NUM_CHANNELS-1:0] bit_out;
            sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf (.in(cfg_theta_init[bit_idx]), .out(bit_out));
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_assign
                assign cfg_theta_init_buf[ch][bit_idx] = bit_out[ch];
            end
        end
        for (bit_idx = 0; bit_idx < REFRACTORY_WIDTH; bit_idx = bit_idx + 1) begin : gen_refractory_len_buf
            logic [NUM_CHANNELS-1:0] bit_out;
            sfe_fanout_buffer #(.FANOUT(NUM_CHANNELS), .MAX_FANOUT(MAX_FANOUT)) u_buf (.in(cfg_refractory_len[bit_idx]), .out(bit_out));
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_assign
                assign cfg_refractory_len_buf[ch][bit_idx] = bit_out[ch];
            end
        end
    endgenerate

    // ============================================================
    // Decay tick generator (unchanged logic)
    // ============================================================
    logic [DECAY_TICK_WIDTH-1:0] decay_counter_q;
    logic                        decay_tick;

    assign decay_tick = !cfg_enable_decay_tick ||
                        ((decay_counter_q & cfg_decay_tick_mask) == cfg_decay_tick_mask);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decay_counter_q <= '0;
        end else if (!en || !cfg_enable_decay_tick || cfg_load) begin
            decay_counter_q <= '0;
        end else begin
            decay_counter_q <= decay_counter_q + 1'b1;
        end
    end

    // ============================================================
    // Channel instances (using buffered signals)
    // ============================================================
    genvar ch;
    generate
        for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin : gen_sfe_channel
            sfe_channel #(
                .DATA_WIDTH(DATA_WIDTH),
                .THETA_WIDTH(THETA_WIDTH),
                .REF_WIDTH(DATA_WIDTH),
                .LEAK_SHIFT(LEAK_SHIFT),
                .THETA_DEC_SHIFT(THETA_DEC_SHIFT),
                .REFRACTORY_LEN(REFRACTORY_LEN),
                .REFRACTORY_WIDTH(REFRACTORY_WIDTH),
                .THETA_MIN(THETA_MIN),
                .THETA_MAX(THETA_MAX),
                .THETA_INIT(THETA_INIT),
                .ENABLE_ADAPTIVE(ENABLE_ADAPTIVE),
                .ENABLE_LEAKAGE(ENABLE_LEAKAGE),
                .ENABLE_REFRACTORY(ENABLE_REFRACTORY)
            ) u_channel (
                .clk(clk),
                .rst_n(rst_n_buf[ch]),
                .en(en_buf[ch]),
                .channel_en(channel_en[ch]),
                .cfg_enable_adaptive(cfg_enable_adaptive_buf[ch]),
                .cfg_enable_leakage(cfg_enable_leakage_buf[ch]),
                .cfg_enable_refractory(cfg_enable_refractory_buf[ch]),
                .decay_tick(decay_tick_buf[ch]),
                .cfg_load(cfg_load_buf[ch]),
                .cfg_theta_min(cfg_theta_min_buf[ch]),
                .cfg_theta_max(cfg_theta_max_buf[ch]),
                .cfg_theta_init(cfg_theta_init_buf[ch]),
                .cfg_refractory_len(cfg_refractory_len_buf[ch]),
                .x_in(x_flat[ch*DATA_WIDTH +: DATA_WIDTH]),
                .spike_up(spike_up[ch]),
                .spike_down(spike_down[ch]),
                .v_ref_dbg(),
                .theta_dbg()
            );
        end
    endgenerate

endmodule

`default_nettype wire
