`timescale 1ns/1ps

module sfe_audio_frontend_top #(
    parameter int NUM_CHANNELS = 32,
    parameter int DATA_WIDTH = 16,
    parameter int THETA_WIDTH = 16,
    parameter int TIMESTAMP_WIDTH = 32,
    parameter int FIFO_DEPTH = 16,
    parameter int REFRACTORY_LEN = 4,
    parameter int REFRACTORY_WIDTH = (REFRACTORY_LEN <= 1) ? 1 : $clog2(REFRACTORY_LEN + 1),
    parameter int CH_WIDTH = (NUM_CHANNELS <= 1) ? 1 : $clog2(NUM_CHANNELS)
) (
    input  logic                              clk,
    input  logic                              rst_n,
    input  logic                              en,
    input  logic [NUM_CHANNELS-1:0]           channel_en,
    input  logic                              cfg_enable_adaptive,
    input  logic                              cfg_enable_leakage,
    input  logic                              cfg_enable_refractory,
    input  logic                              cfg_enable_decay_tick,
    input  logic [3:0]                        cfg_decay_tick_mask,
    input  logic                              cfg_load,
    input  logic [THETA_WIDTH-1:0]            cfg_theta_min,
    input  logic [THETA_WIDTH-1:0]            cfg_theta_max,
    input  logic [THETA_WIDTH-1:0]            cfg_theta_init,
    input  logic [REFRACTORY_WIDTH-1:0]       cfg_refractory_len,
    input  logic signed [NUM_CHANNELS*DATA_WIDTH-1:0] x_flat,
    input  logic                              event_ready,
    output logic                              event_valid,
    output logic [CH_WIDTH-1:0]               event_channel,
    output logic                              event_direction,
    output logic [TIMESTAMP_WIDTH-1:0]        event_timestamp,
    output logic                              fifo_full,
    output logic                              fifo_overflow,
    output logic                              pending_overflow,
    output logic [$clog2(FIFO_DEPTH + 1)-1:0] fifo_level,
    output logic [NUM_CHANNELS-1:0]           spike_up_debug,
    output logic [NUM_CHANNELS-1:0]           spike_down_debug
);

    logic [NUM_CHANNELS-1:0] pending_mask;

    sfe_encoder_bank #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .DATA_WIDTH(DATA_WIDTH),
        .THETA_WIDTH(THETA_WIDTH),
        .REFRACTORY_LEN(REFRACTORY_LEN)
    ) u_encoder_bank (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .channel_en(channel_en),
        .cfg_enable_adaptive(cfg_enable_adaptive),
        .cfg_enable_leakage(cfg_enable_leakage),
        .cfg_enable_refractory(cfg_enable_refractory),
        .cfg_enable_decay_tick(cfg_enable_decay_tick),
        .cfg_decay_tick_mask(cfg_decay_tick_mask),
        .cfg_load(cfg_load),
        .cfg_theta_min(cfg_theta_min),
        .cfg_theta_max(cfg_theta_max),
        .cfg_theta_init(cfg_theta_init),
        .cfg_refractory_len(cfg_refractory_len),
        .x_flat(x_flat),
        .spike_up(spike_up_debug),
        .spike_down(spike_down_debug)
    );

    sfe_event_packetizer #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .CH_WIDTH(CH_WIDTH),
        .TIMESTAMP_WIDTH(TIMESTAMP_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_event_packetizer (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .event_ready(event_ready),
        .spike_up(spike_up_debug),
        .spike_down(spike_down_debug),
        .event_valid(event_valid),
        .event_channel(event_channel),
        .event_direction(event_direction),
        .event_timestamp(event_timestamp),
        .pending_mask(pending_mask),
        .fifo_full(fifo_full),
        .fifo_overflow(fifo_overflow),
        .pending_overflow(pending_overflow),
        .fifo_level(fifo_level)
    );

endmodule
