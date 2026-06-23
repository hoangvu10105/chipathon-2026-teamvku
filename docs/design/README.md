# Design Documentation – SFE Audio Frontend

## Track A: Foundational Building Blocks – Spiking Frequency Encoder Bank

> **Target Process:** GF180MCU (GlobalFoundries 180nm)
> **Slot:** Workshop (2935×2935 µm die, 2051×2051 µm core)
> **Tool Flow:** LibreLane 3.0 (RTL → GDS)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  sfe_audio_frontend_top              │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │           sfe_encoder_bank (×32)              │   │
│  │  ┌─────────┐ ┌─────────┐     ┌─────────┐     │   │
│  │  │ Channel │ │ Channel │ ... │ Channel │     │   │
│  │  │    0    │ │    1    │     │   31    │     │   │
│  │  └────┬────┘ └────┬────┘     └────┬────┘     │   │
│  │       │ spike_up/down              │          │   │
│  │       └────────────┬───────────────┘          │   │
│  │                    │                          │   │
│  │     sfe_fanout_buffer (control fanout ≤10)    │   │
│  └────────────────────┬─────────────────────────┘   │
│                       │                             │
│  ┌────────────────────┴─────────────────────────┐   │
│  │         sfe_event_packetizer                  │   │
│  │   AER Protocol · FIFO (depth 16) · Priority   │   │
│  └────────────────────┬─────────────────────────┘   │
│                       │                             │
│  event_valid · event_channel · event_direction      │
│  event_timestamp · fifo_level · overflow flags      │
└───────────────────────┬─────────────────────────────┘
                        │
              chip_core (pad adapter)
                        │
         ┌──────────────┴──────────────┐
         │      Workshop Padring        │
         │  60×Analog · 20×Bidir · PWR │
         └─────────────────────────────┘
```

---

## Block Specifications

### 1. `sfe_encoder_bank` — Parameterized Spiking Encoder

| Parameter | Value | Description |
|-----------|-------|-------------|
| NUM_CHANNELS | 32 default, 20 in workshop `chip_core` | Frequency channels / sampled feature lanes |
| DATA_WIDTH | 16 | Input sample width per channel |
| THETA_WIDTH | 16 | Adaptive threshold width |
| LEAK_SHIFT | 4 | Leakage decay rate (>>4 = /16) |
| THETA_DEC_SHIFT | 6 | Threshold adaptation rate |
| REFRACTORY_LEN | 4 | Refractory period (cycles) |
| THETA_MIN | 16 | Minimum threshold |
| THETA_MAX | 1024 | Maximum threshold |
| THETA_INIT | 32 | Initial threshold |
| MAX_FANOUT | 10 | Per-buffer fanout limit |

**Features:**
- ✅ Adaptive threshold (theta): auto-adjusts per channel
- ✅ Leakage: membrane potential decay
- ✅ Refractory period: prevents burst firing
- ✅ Fanout buffer tree for high-fanout control signals
- ✅ Configurable per-channel enable
- ✅ Spike output: up/down per channel (rate-coded frequency)

### 2. `sfe_channel` — Single Channel Core

Each channel implements:
- Membrane potential accumulation
- Spike generation on threshold crossing
- Adaptive threshold update (up/down)
- Refractory counter
- Leakage integration

### 3. `sfe_event_packetizer` — AER Event Encoder

| Parameter | Value | Description |
|-----------|-------|-------------|
| NUM_CHANNELS | Parameterized | Input spike channels |
| CH_WIDTH | Derived | Channel address width |
| TIMESTAMP_WIDTH | 32 | Event timestamp width |
| FIFO_DEPTH | 16 | Output event FIFO depth |

**Output Protocol:** Address Event Representation (AER)
- `event_valid` — Event ready strobe
- `event_channel[4:0]` — Source channel address
- `event_direction` — Spike direction (0=down, 1=up)
- `event_timestamp[31:0]` — 32-bit timestamp
- `fifo_full`, `fifo_overflow`, `pending_overflow` — Status flags
- `fifo_level` — FIFO fill level

### 4. `chip_core` — Padring Adapter

Maps the SFE frontend to the workshop padring:
- **Bidir[3:0]**: Configuration inputs (run_en, fixed_threshold, decay_tick_2, disable_refractory)
- **Bidir[19:4]**: Status outputs (AER events + FIFO status)
- **input_in[0]**: External input enable
- **60× Analog pads**: Reserved for future analog frontend

---

## Build Results (2026-06-23)

| Metric | Value |
|--------|-------|
| **Tool** | LibreLane 3.0 + GF180MCU PDK 1.8.0 |
| **Lint Errors** | 0 |
| **Inferred Latches** | 0 |
| **Instance Count** | 129,874 |
| **Design Area** | 7,814,220 µm² |
| **Total Power** | 0.018 W |
| **Setup Violations** | 0 |
| **Hold Violations** | 0 |
| **Max Slew/Cap/Fanout** | Needs final `metrics.csv` refresh |

> Note: latest log reports clean DRC/LVS/antenna and no setup/hold violations; refresh final metrics before claiming electrical DRV closure.

---

## File Map

| File | Description |
|------|-------------|
| `src/sfe_audio_frontend_top.sv` | Top-level wrapper: encoder bank + packetizer |
| `src/sfe_encoder_bank.sv` | Parameterized encoder bank with fanout buffers |
| `src/sfe_channel.sv` | Single spiking frequency encoder channel |
| `src/sfe_event_packetizer.sv` | AER event packer with FIFO |
| `src/sfe_fanout_buffer.sv` | Fanout buffer tree (max 10 loads per buffer) |
| `src/chip_core.sv` | Workshop pad adapter for SFE |
| `src/chip_top.sv` | Top-level chip wrapper |
| `src/slot_defines.svh` | SLOT_WORKSHOP pad definitions |
| `src/sfe_pad_cfg.tcl` | Pad configuration for SFE |
| `src/gf180_io_stubs.v` | I/O stub models for simulation |
| `src/gf180_io_site.lef` | I/O site LEF for placement |