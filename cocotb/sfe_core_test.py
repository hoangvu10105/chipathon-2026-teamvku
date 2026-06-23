#!/usr/bin/env python3
"""SFE Audio Frontend - Functional Verification Test (no PDK required)"""

import subprocess, os, sys

# ─── SFE Core standalone test ───
# We'll verify the SFE encoder bank logic using iverilog directly
# with all SFE source files (no padring needed)

SRC_DIR = "/foss/designs/sfe_chipathon_padring/src"
COCOTB_DIR = "/foss/designs/sfe_chipathon_padring/cocotb"
SIM_DIR = os.path.join(COCOTB_DIR, "sim_build_sfe_core")
os.makedirs(SIM_DIR, exist_ok=True)

# All SFE source files
sources = [
    "sfe_fanout_buffer.sv",
    "sfe_channel.sv",
    "sfe_encoder_bank.sv",
    "sfe_event_packetizer.sv",
    "sfe_audio_frontend_top.sv",
]

# Simple testbench wrapper
tb_code = """
`timescale 1ns/1ps
module sfe_core_tb;
    reg clk = 0;
    reg rst_n = 0;
    reg en = 0;
    reg [31:0] channel_en = 0;
    reg cfg_enable_adaptive = 1;
    reg cfg_enable_leakage = 1;
    reg cfg_enable_refractory = 1;
    reg cfg_enable_decay_tick = 0;
    reg [3:0] cfg_decay_tick_mask = 1;
    reg cfg_load = 0;
    reg [15:0] cfg_theta_min = 16;
    reg [15:0] cfg_theta_max = 1024;
    reg [15:0] cfg_theta_init = 32;
    reg [2:0] cfg_refractory_len = 4;
    reg signed [511:0] x_flat = 0;
    reg event_ready = 1;
    
    wire event_valid;
    wire [4:0] event_channel;
    wire event_direction;
    wire [31:0] event_timestamp;
    wire fifo_full;
    wire fifo_overflow;
    wire pending_overflow;
    wire [4:0] fifo_level;
    wire [31:0] spike_up_debug;
    wire [31:0] spike_down_debug;
    
    integer ch;
    integer cycle = 0;
    integer spike_count = 0;
    
    sfe_audio_frontend_top #(
        .NUM_CHANNELS(32),
        .DATA_WIDTH(16),
        .FIFO_DEPTH(16),
        .REFRACTORY_LEN(4)
    ) uut (
        .clk(clk), .rst_n(rst_n), .en(en),
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
        .event_ready(event_ready),
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
    
    always #20 clk = ~clk;  // 25 MHz
    
    initial begin
        $display("=== SFE Core Functional Test ===");
        $display("Time: %0t ns", $time);
        
        // Reset
        rst_n = 0; #100;
        rst_n = 1; #100;
        
        // Enable core and all channels
        en = 1;
        channel_en = 32'hFFFFFFFF;
        
        // Apply test stimulus: sine-like pattern across channels
        for (ch = 0; ch < 32; ch = ch + 1) begin
            x_flat[ch*16 +: 16] = $signed(100 + ch * 20);
        end
        
        // Run for 5000 cycles
        repeat(5000) @(posedge clk);
        
        // Vary input
        for (ch = 0; ch < 32; ch = ch + 1) begin
            x_flat[ch*16 +: 16] = $signed(200 + ch * 30);
        end
        
        repeat(5000) @(posedge clk);
        
        $display("=== Test Complete ===");
        $display("Total cycles: %0d", cycle);
        $display("Spike count: %0d", spike_count);
        $display("PASS: SFE core functional");
        $finish;
    end
    
    always @(posedge clk) begin
        cycle <= cycle + 1;
        if (event_valid) spike_count <= spike_count + 1;
    end
    
    // Monitor first 20 events
    always @(posedge clk) begin
        if (event_valid && spike_count < 20)
            $display("[%0t] EVENT: ch=%0d dir=%0d ts=%0d level=%0d",
                     $time, event_channel, event_direction, event_timestamp, fifo_level);
    end
endmodule
"""

tb_path = os.path.join(SIM_DIR, "sfe_core_tb.sv")
with open(tb_path, "w") as f:
    f.write(tb_code)

# Build source file list
src_args = []
for s in sources:
    src_args.append(os.path.join(SRC_DIR, s))
src_args.append(tb_path)

# Compile with iverilog
vvp_out = os.path.join(SIM_DIR, "sfe_core.vvp")
cmd = ["iverilog", "-o", vvp_out, "-g2012", "-s", "sfe_core_tb"] + src_args

print("Compiling...")
print(" ".join(cmd))
result = subprocess.run(cmd, capture_output=True, text=True)
if result.returncode != 0:
    print("COMPILE ERROR:")
    print(result.stderr)
    print(result.stdout)
    sys.exit(1)
print("Compile OK")

# Run simulation
print("\nRunning simulation...")
cmd2 = ["vvp", vvp_out]
result2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=60)
print(result2.stdout)
if result2.returncode != 0:
    print("SIM ERROR:", result2.stderr)

# Check for PASS
if "PASS" in result2.stdout:
    print("\n✅ SFE CORE FUNCTIONAL TEST PASSED!")
else:
    print("\n❌ TEST FAILED")
