# Schematic Review – Week 27 (July 3, 2026)

**Team:** TeamVKU | **Track:** A – Foundational Building Blocks  
**Project:** SFE Audio Frontend – Spiking Frequency Encoder Bank

---

## 1. Top-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       chip_top                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    chip_core                             │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │            sfe_audio_frontend_top                  │  │  │
│  │  │  ┌────────────────────────────────────────────┐  │  │  │
│  │  │  │          sfe_encoder_bank (×32)              │  │  │  │
│  │  │  │  ┌──────┐ ┌──────┐       ┌──────┐          │  │  │  │
│  │  │  │  │ Ch 0 │ │ Ch 1 │  ...  │ Ch31 │          │  │  │  │
│  │  │  │  └──┬───┘ └──┬───┘       └──┬───┘          │  │  │  │
│  │  │  │     │ spike_up/down          │               │  │  │  │
│  │  │  │     └──────────┬─────────────┘               │  │  │  │
│  │  │  │                │                             │  │  │  │
│  │  │  │   sfe_fanout_buffer (×7 control + multi-bit) │  │  │  │
│  │  │  └────────────────┬────────────────────────────┘  │  │  │
│  │  │                   │                                │  │  │
│  │  │  ┌────────────────┴────────────────────────────┐  │  │  │
│  │  │  │        sfe_event_packetizer                   │  │  │  │
│  │  │  │  Priority Encoder → FIFO(16) → AER Output     │  │  │  │
│  │  │  └────────────────┬────────────────────────────┘  │  │  │
│  │  └───────────────────┼───────────────────────────────┘  │  │
│  │                      │ event_valid/channel/dir/ts        │  │
│  │  ┌───────────────────┴───────────────────────────────┐  │  │
│  │  │  sfe_fanout_buffer (rst_core_n → rst_core_buf_n)   │  │  │
│  │  └───────────────────────────────────────────────────┘  │  │
│  └──────────────────────────┬──────────────────────────────┘  │
│                             │                                  │
│  ┌──────────────────────────┴──────────────────────────────┐  │
│  │              Workshop Padring                             │  │
│  │  60×Analog │ 20×Bidir │ 4×DVDD │ 4×DVSS │ clk │ rst_n    │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. SFE Channel (Integrate-and-Fire Neuron)

### Schematic Description
Each of the 32 channels implements an adaptive integrate-and-fire neuron:

```
x[n] (16-bit) ──→ [Membrane Accumulator] ──→ [Comparator] ──→ spike
                       ↑                          │
                       │         ┌─────────────────┘
                       │         ▼
                   [Leakage]  [Threshold Adapt]
                       │         │
                   theta[n] ←──┘
```

### Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| DATA_WIDTH | 16 | Input sample width |
| THETA_WIDTH | 16 | Adaptive threshold width |
| LEAK_SHIFT | 4 | Leakage rate (>>4 = /16 per tick) |
| THETA_DEC_SHIFT | 6 | Threshold adaptation rate |
| REFRACTORY_LEN | 4 | Refractory period (clock cycles) |
| THETA_MIN | 16 | Minimum threshold |
| THETA_MAX | 1024 | Maximum threshold |
| THETA_INIT | 32 | Initial threshold value |

### Spike Generation Logic
1. Accumulate input `x[n]` into membrane potential
2. Apply leakage: `membrane = membrane - (membrane >> LEAK_SHIFT)`
3. Compare `membrane >= theta` → if true, generate spike
4. On spike:
   - Increase theta (adaptive): `theta = theta + (theta >> THETA_DEC_SHIFT)`
   - Reset membrane
   - Enter refractory period (REFRACTORY_LEN cycles)
5. When idle (no spike), theta slowly decays toward THETA_MIN

---

## 3. AER Event Packetizer

### Protocol: Address Event Representation (AER)

```
spike_up[31:0]   ──→ [Priority Encoder] ──→ [FIFO (depth 16)] ──→ event_valid
spike_down[31:0] ──→                          │                 → event_channel[4:0]
                                               │                 → event_direction
                                         [timestamp]             → event_timestamp[31:0]
                                         counter 32-bit          → fifo_full/overflow
```

### Output Interface

| Signal | Width | Description |
|--------|-------|-------------|
| event_valid | 1 | Strobe: event data valid this cycle |
| event_channel | 5 | Source channel (0–31) |
| event_direction | 1 | 0=spike_down, 1=spike_up |
| event_timestamp | 32 | Monotonic event timestamp |
| fifo_full | 1 | FIFO at capacity |
| fifo_overflow | 1 | Event dropped due to full FIFO |
| fifo_level | 5 | Current FIFO fill level |

---

## 4. Fanout Buffer Tree

### Problem
High-fanout control signals (rst_n, en, cfg signals) drive 32 channels simultaneously, causing max_fanout violations.

### Solution: `sfe_fanout_buffer`
```
in ──→ [buf_1] ──→ out[0:9]   (fanout ≤ 10)
            └──→ [buf_2] ──→ out[10:19]
            └──→ [buf_3] ──→ out[20:29]
            └──→ [buf_4] ──→ out[30:31]
```
Each buffer stage drives at most MAX_FANOUT=10 loads. Multi-bit signals use per-bit buffer trees.

---

## 5. Padring Interface

### Workshop Slot (GF180MCU)

| Pad Type | Count | Usage |
|----------|-------|-------|
| analog (asig_5p0) | 60 | Reserved for future analog frontend |
| bidir (bi_24t) | 20 | **4× config in + 16× status out** |
| DVDD | 4 | Core + I/O power |
| DVSS | 4 | Ground |
| clk_pad (in_s) | 1 | 25 MHz system clock |
| rst_n_pad (in_c) | 1 | Active-low reset |
| corner | 4 | Auto-inserted by LibreLane |

### Bidir Pad Assignment

| Pad | Direction | Signal |
|-----|-----------|--------|
| bidir[0] | IN | run_en |
| bidir[1] | IN | fixed_threshold |
| bidir[2] | IN | decay_tick_2 |
| bidir[3] | IN | disable_refractory |
| bidir[4] | OUT | event_valid |
| bidir[5] | OUT | event_direction |
| bidir[10:6] | OUT | event_channel[4:0] |
| bidir[17:11] | OUT | event_timestamp[6:0] |
| bidir[18] | OUT | overflow_flag |
| bidir[19] | OUT | heartbeat |

---

## 6. Known Issues

| Issue | Severity | Status |
|-------|----------|--------|
| max_slew @ SS corner (2470 violations) | Medium | Fix applied, rebuild pending |
| max_fanout violations (65) | Low | SYNTH_MAX_FANOUT=10 added |
| max_cap violations (22) | Low | Being addressed with MAX_TRANSITION_CONSTRAINT |
| No analog frontend | Future | Reserve 60 analog pads for Phase 2 |

---

## 7. Review Checklist

- [ ] Architecture diagram reviewed
- [ ] Channel neuron schematic verified
- [ ] AER protocol timing confirmed
- [ ] Padring pinout validated
- [ ] Clock domain crossing checked (rst_n async → sync)
- [ ] Power domain planning (VDD/VSS distribution)
- [ ] Test plan: cocotb testbench for digital core
- [ ] DRC/LVS status: clean on digital blocks
