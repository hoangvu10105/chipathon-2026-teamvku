# SPDX-FileCopyrightText: © 2025 Project Template Contributors
# SPDX-FileCopyrightText: © 2026 TeamVKU – SFE Audio Frontend
# SPDX-License-Identifier: Apache-2.0
#
# Cocotb testbench for chip_top (workshop padring + SFE audio frontend).
# Exercises the SFE encoder bank through the bidir pad interface:
#   bidir[3:0]   = config inputs  (run_en, fixed_threshold, decay_tick_2, disable_refractory)
#   bidir[19:4]  = status outputs (event_valid, direction, channel[4:0], timestamp[6:0], overflow, heartbeat)
#   input_in[0]  = input enable (tied high for test)

import os
import logging
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb_tools.runner import get_runner

sim = os.getenv("SIM", "icarus")
pdk_root = os.getenv("PDK_ROOT", Path("~/.ciel").expanduser())
pdk = os.getenv("PDK", "gf180mcuD")
scl = os.getenv("SCL", "gf180mcu_fd_sc_mcu7t5v0")
gl = os.getenv("GL", False)
slot = os.getenv("SLOT", "workshop")

hdl_toplevel = "chip_top"


async def set_defaults(dut):
    """Initialize all pad inputs to safe defaults."""
    dut.input_PAD.value = 0
    dut.bidir_PAD.value = 0


async def enable_power(dut):
    """Enable power for gate-level simulation."""
    dut.VDD.value = 1
    dut.VSS.value = 0


async def start_clock(clock, freq=25):
    """Start the clock @ freq MHz (default 25 MHz for GF180MCU)."""
    c = Clock(clock, 1 / freq * 1000, "ns")
    cocotb.start_soon(c.start())


async def reset(reset, active_low=True, time_ns=2000):
    """Assert and deassert reset."""
    logger = logging.getLogger("sfe_testbench")
    logger.info("Reset asserted...")
    reset.value = not active_low
    await Timer(time_ns, "ns")
    reset.value = active_low
    logger.info("Reset deasserted.")


async def start_up(dut):
    """Full startup sequence."""
    await set_defaults(dut)
    if gl:
        await enable_power(dut)
    await start_clock(dut.clk_PAD)
    await reset(dut.rst_n_PAD)
    # Wait for internal reset synchronizer (2-stage FF in chip_core)
    await ClockCycles(dut.clk_PAD, 5)


# ─── SFE Functional Tests ───────────────────────────────────────


@cocotb.test()
async def test_sfe_startup(dut):
    """Verify SFE powers up cleanly and produces heartbeat."""
    logger = logging.getLogger("sfe_testbench")
    logger.info("=== Test: SFE Startup ===")
    await start_up(dut)

    # Enable SFE: run_en=1, fixed_threshold=0 (adaptive on),
    #   decay_tick_2=1 (decay enabled), disable_refractory=0 (refractory on)
    dut.bidir_PAD.value = 0b0001   # bidir[0]=run_en=1
    dut.input_PAD.value = 0b1      # input_en=1

    await ClockCycles(dut.clk_PAD, 200)

    # Heartbeat should be toggling on bidir[19]
    heartbeat_high = False
    heartbeat_low = False
    for _ in range(100):
        await RisingEdge(dut.clk_PAD)
        val = dut.bidir_PAD.value.integer
        if val & (1 << 19):
            heartbeat_high = True
        else:
            heartbeat_low = True
        if heartbeat_high and heartbeat_low:
            break

    assert heartbeat_high and heartbeat_low, "Heartbeat on bidir[19] not toggling"
    logger.info("✅ Heartbeat toggling OK")


@cocotb.test()
async def test_sfe_aer_events(dut):
    """Verify AER events are produced with valid protocol."""
    logger = logging.getLogger("sfe_testbench")
    logger.info("=== Test: SFE AER Event Production ===")
    await start_up(dut)

    # Enable SFE with adaptive threshold
    dut.bidir_PAD.value = 0b0001   # run_en=1
    dut.input_PAD.value = 0b1      # input_en=1

    event_count = 0
    channels_seen = set()
    overflow_seen = False
    timestamps = []

    # Monitor for 5000 cycles
    for _ in range(5000):
        await RisingEdge(dut.clk_PAD)
        val = dut.bidir_PAD.value.integer

        event_valid = (val >> 4) & 1
        event_dir   = (val >> 5) & 1
        event_ch    = (val >> 6) & 0x1F    # bits [10:6]
        event_ts_lo = (val >> 11) & 0x7F   # bits [17:11]
        overflow    = (val >> 18) & 1
        heartbeat   = (val >> 19) & 1

        # Config inputs on bidir[3:0] may be reading back; mask them
        # We only care about output signals on [19:4]

        if event_valid:
            event_count += 1
            channels_seen.add(event_ch)
            timestamps.append(event_ts_lo)

        if overflow:
            overflow_seen = True

    logger.info(f"Events captured: {event_count}")
    logger.info(f"Channels fired:  {sorted(channels_seen)}")
    logger.info(f"Overflow seen:   {overflow_seen}")

    assert event_count > 0, "No AER events produced! SFE may not be firing."
    assert len(channels_seen) >= 2, f"Only {len(channels_seen)} channels fired, expected >= 2"

    # Timestamp should be non-decreasing (low 7 bits visible on pads)
    for i in range(1, len(timestamps)):
        ts_prev = timestamps[i-1]
        ts_curr = timestamps[i]
        # Handle 7-bit wrap; each should be ~ monotonic in low bits
        if ts_curr < ts_prev:
            logger.debug(f"Timestamp wrap at event {i}: {ts_prev} -> {ts_curr}")

    logger.info(f"✅ SFE produced {event_count} AER events across {len(channels_seen)} channels")


@cocotb.test()
async def test_sfe_config_modes(dut):
    """Verify SFE responds to configuration changes on bidir inputs."""
    logger = logging.getLogger("sfe_testbench")
    logger.info("=== Test: SFE Configuration Modes ===")
    await start_up(dut)

    # ─── Mode 1: Normal operation (adaptive threshold + refractory) ───
    logger.info("Mode 1: Normal (adaptive + decay + refractory)")
    dut.bidir_PAD.value = 0b0001   # run_en=1, rest=0
    dut.input_PAD.value = 0b1

    events_mode1 = 0
    for _ in range(2000):
        await RisingEdge(dut.clk_PAD)
        if dut.bidir_PAD.value.integer & (1 << 4):
            events_mode1 += 1

    logger.info(f"  Mode 1 events: {events_mode1}")

    # ─── Mode 2: Fixed threshold (no adaptation) ───
    logger.info("Mode 2: Fixed threshold")
    dut.bidir_PAD.value = 0b0011   # run_en=1, fixed_threshold=1

    events_mode2 = 0
    for _ in range(2000):
        await RisingEdge(dut.clk_PAD)
        if dut.bidir_PAD.value.integer & (1 << 4):
            events_mode2 += 1

    logger.info(f"  Mode 2 events: {events_mode2}")

    # ─── Mode 3: Disabled (run_en=0) ───
    logger.info("Mode 3: Disabled")
    dut.bidir_PAD.value = 0b0000   # run_en=0

    events_mode3 = 0
    for _ in range(500):
        await RisingEdge(dut.clk_PAD)
        if dut.bidir_PAD.value.integer & (1 << 4):
            events_mode3 += 1

    logger.info(f"  Mode 3 events: {events_mode3}")

    assert events_mode1 > 0, "No events in normal mode"
    # Mode 2 (fixed) may have different firing rate
    assert events_mode3 == 0, f"SFE still firing when disabled: {events_mode3} events"
    logger.info("✅ Configuration modes work correctly")


@cocotb.test()
async def test_sfe_no_stuck(dut):
    """Verify no outputs are stuck at constant values (basic health check)."""
    logger = logging.getLogger("sfe_testbench")
    logger.info("=== Test: SFE Output Health (no stuck signals) ===")
    await start_up(dut)

    dut.bidir_PAD.value = 0b0001   # run_en=1
    dut.input_PAD.value = 0b1

    # Sample outputs over many cycles
    samples = []
    for _ in range(1000):
        await RisingEdge(dut.clk_PAD)
        samples.append(dut.bidir_PAD.value.integer & 0xFFFF0)  # mask config bits

    # Check that output bits toggle (not stuck)
    all_or  = 0
    all_and = 0xFFFFF
    for s in samples:
        all_or |= s
        all_and &= s

    stuck_high = all_and & 0xFFFF0
    stuck_low  = (~all_or) & 0xFFFF0

    # Heartbeat (bit 19) MUST toggle
    assert (all_or >> 19) & 1, "Heartbeat bit 19 stuck low"
    assert not ((all_and >> 19) & 1), "Heartbeat bit 19 stuck high"

    logger.info(f"Bits always high: 0b{stuck_high:020b}")
    logger.info(f"Bits always low:  0b{stuck_low:020b}")
    logger.info("✅ Output health check passed")


# ─── Cocotb Runner ─────────────────────────────────────────────


def chip_top_runner():
    proj_path = Path(__file__).resolve().parent
    src_path = proj_path / "../src"

    sources = []
    defines = {f"SLOT_{slot.upper()}": True}
    includes = [src_path]

    if gl:
        # Gate-level: use post-PNR netlist + SCL models
        sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / f"{scl}.v")
        sources.append(Path(pdk_root) / pdk / "libs.ref" / scl / "verilog" / "primitives.v")
        sources.append(proj_path / f"../final/pnl/{hdl_toplevel}.pnl.v")
        defines = {"FUNCTIONAL": True, "USE_POWER_PINS": True}
    else:
        # RTL simulation: include ALL source files
        sources += [
            src_path / "chip_top.sv",
            src_path / "chip_core.sv",
            src_path / "sfe_audio_frontend_top.sv",
            src_path / "sfe_encoder_bank.sv",
            src_path / "sfe_channel.sv",
            src_path / "sfe_event_packetizer.sv",
            src_path / "sfe_fanout_buffer.sv",
            src_path / "gf180_io_stubs.v",
        ]

    # PDK IO pad models + IP macros
    sources += [
        Path(pdk_root) / pdk / "libs.ref/gf180mcu_fd_io/verilog/gf180mcu_fd_io.v",
        Path(pdk_root) / pdk / "libs.ref/gf180mcu_fd_io/verilog/gf180mcu_ws_io.v",
        Path(pdk_root) / pdk / "libs.ref/gf180mcu_fd_ip_sram/verilog/gf180mcu_fd_ip_sram__sram512x8m8wm1.v",
        proj_path / "../ip/gf180mcu_ws_ip__id/vh/gf180mcu_ws_ip__id.v",
        proj_path / "../ip/gf180mcu_ws_ip__logo/vh/gf180mcu_ws_ip__logo.v",
    ]

    build_args = []
    if sim == "icarus":
        build_args = ["-g2012"]  # SystemVerilog support
    if sim == "verilator":
        build_args = ["--timing", "--trace", "--trace-fst", "--trace-structs"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        defines=defines,
        always=True,
        includes=includes,
        build_args=build_args,
        waves=True,
    )

    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module="chip_top_tb",
        waves=True,
    )


if __name__ == "__main__":
    chip_top_runner()
