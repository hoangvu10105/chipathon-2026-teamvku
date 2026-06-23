# TeamVKU – SSCS Chipathon 2026

> **[Track A] SFE Audio Frontend – Spiking Frequency Encoder Bank**

**Team Lead:** Hoang Vu | **Team Code:** *(pending assignment)*

**GitHub:** https://github.com/hoangvu10105/chipathon-2026-teamvku

---

## 🎯 Project Overview

This repository contains the **TeamVKU** submission for the **IEEE SSCS Chipathon 2026**, competing in **Track A: Foundational Building Blocks**.

Our project is an **SFE (Spiking Frequency Encoder) Audio Frontend** — a neuromorphic mixed-signal IP block that converts audio input into sparse spike-event streams using 32 parallel frequency-encoding channels. The design targets the **GF180MCU** open-source process and uses the **LibreLane 3.0** automated RTL-to-GDS flow.

### 🔬 What is SFE?

The Spiking Frequency Encoder is a bio-inspired neural encoding scheme. Each of the 32 channels acts as an adaptive spiking neuron with:
- **Leaky integrate-and-fire dynamics** with configurable threshold
- **Frequency-selective encoding** across 32 spectral bands
- **Adaptive threshold** (theta) that self-tunes between min/max bounds
- **Refractory period** to prevent burst firing
- **AER (Address Event Representation)** output protocol

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  sfe_audio_frontend_top                  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              sfe_encoder_bank                      │   │
│  │  ┌──────────┐  ┌──────────┐       ┌──────────┐   │   │
│  │  │ Channel 0 │  │ Channel 1 │  ...  │Channel 31│   │   │
│  │  │ (16-bit)  │  │ (16-bit)  │       │ (16-bit)  │   │   │
│  │  └──────────┘  └──────────┘       └──────────┘   │   │
│  │       ▲              ▲                  ▲         │   │
│  │       └──────────────┴──────────────────┘         │   │
│  │          sfe_fanout_buffer (max fanout ≤ 10)       │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                               │
│                          ▼                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │           sfe_event_packetizer (AER)               │   │
│  │  Spike→Event: channel, direction, timestamp        │   │
│  │  FIFO depth: 16, overflow protection               │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                               │
│          ┌───────────────┴───────────────┐               │
│          ▼                               ▼               │
│   20× bidir pads                  60× analog pads        │
│   (config in, status out)         (audio inputs)         │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Specifications

| Parameter | Value |
|-----------|-------|
| **Channels** | 32 |
| **Data width per channel** | 16 bit |
| **Threshold (theta) range** | 16 – 1024 (16-bit) |
| **Default theta** | 32 |
| **Leak shift** | 4 |
| **Theta decay shift** | 6 |
| **Refractory length** | 4 cycles |
| **Timestamp width** | 32 bit |
| **FIFO depth** | 16 entries |
| **Max fanout per buffer** | 10 |
| **Output protocol** | AER (Address Event Representation) |
| **Technology** | GF180MCU (180nm) |
| **Process** | GlobalFoundries 0.18µm |

---

## 🏗️ Build Results

| Metric | Value |
|--------|-------|
| **Lint errors** | **0** ✅ |
| **Timing violations** | **0** ✅ |
| **Setup/Hold violations** | **0** ✅ |
| **Instance count** | ~129,874 |
| **Area** | ~7.81 M units² |
| **Total power** | ~0.018 W |
| **GDS** | Generated ✅ |

---

## 📁 Repository Structure

```
.
├── README.md                         # This file
├── AUTHORS.md                        # Team & copyright
├── CREDITS.md / NOTICE / LICENSE     # Apache-2.0
├── docs/
│   ├── design/                       # Design specs & docs
│   ├── proposal/                     # Proposal slides
│   ├── reports/                      # Weekly reports
│   └── SFE_ADAPTER_NOTES.md          # Integration notes
├── src/
│   ├── sfe_audio_frontend_top.sv     # Top-level SFE wrapper
│   ├── sfe_encoder_bank.sv           # 32-channel encoder bank ★
│   ├── sfe_channel.sv                # Single SFE channel (neuron)
│   ├── sfe_event_packetizer.sv       # AER event packer + FIFO
│   ├── sfe_fanout_buffer.sv          # Fanout buffer tree
│   ├── chip_core.sv                  # Workshop padring adapter
│   ├── chip_top.sv                   # Chip top (padring)
│   ├── slot_defines.svh              # SLOT_WORKSHOP config
│   ├── sfe_pad_cfg.tcl               # Pad configuration
│   ├── gf180_io_site.lef             # I/O LEF
│   └── gf180_io_stubs.v              # I/O stub models
├── librelane/                        # LibreLane 3.0 flow config
├── Makefile                          # Build automation
└── flake.nix / shell.nix             # Nix environment
```

---

## 🚀 Quickstart

### Prerequisites
- [Nix](https://nixos.org/download.html) with flakes enabled
- Or Docker: [`hpretl/iic-osic-tools`](https://github.com/iic-jku/IIC-OSIC-TOOLS)

### Build (native, Nix shell)
```bash
git clone https://github.com/hoangvu10105/chipathon-2026-teamvku.git
cd chipathon-2026-teamvku
nix-shell                          # LibreLane 3.0.0
make clone-pdk                     # GF180MCU PDK 1.8.0
SLOT=workshop make librelane
```

**Build time:** ~2h 15m for full signoff (DRC + LVS + antenna + STA, 3 corners).

### Build (Docker)
```bash
scripts/run_docker_iic.sh
# Inside container:
make clone-pdk
SLOT=workshop make librelane
```

---

## 🎓 Chipathon 2026 – Key Dates

| Week | Date | Milestone |
|------|------|-----------|
| Week 26 | **June 26 (TODAY)** | Analog Design Ideas 🎓 |
| Week 27 | July 3 | **Schematic Review** 👥 |
| Week 28 | July 10 | Simulation Review (blocks) |
| Week 29 | July 17 | Simulation Review (top) + **Go/No-go** 🔴 |
| Week 33 | Aug 14 | Layout Review (blocks) |
| Week 34 | Aug 21 | Layout Review (top) |
| Week 35 | Aug 28 | Final Verification + Chip Review |
| TBD | — | **Final GDS Submission** |

---

## 👥 TeamVKU

| Name | Role | GitHub |
|------|------|--------|
| Hoang Vu | Team Lead / RTL Design | [@hoangvu10105](https://github.com/hoangvu10105) |

---

## 📞 Support

- **Track A Leaders:** James Stine, Saroj, Gaurav, Akhilesh Patil, Sumanth Kamineni
- **Discord:** [SSCS Chipathon](https://discord.gg/tvZcQzvt7q) → `#2026-track-a-foundational-building`
- **Issues:** [sscs-ose/sscs-chipathon-2026](https://github.com/sscs-ose/sscs-chipathon-2026/issues)

---

## 📄 License

Apache-2.0. See [`LICENSE`](LICENSE), [`NOTICE`](NOTICE), and [`AUTHORS.md`](AUTHORS.md).

## 🙏 Credits

Derived from:
- [wafer-space/gf180mcu-project-template](https://github.com/wafer-space/gf180mcu-project-template) — Leo Moser & contributors
- [JuanMoya/padring_gf180](https://github.com/JuanMoya/padring_gf180) — Workshop pad layout
- [Mauricio-xx/chipathon-2026-gf180mcu-padring](https://github.com/Mauricio-xx/chipathon-2026-gf180mcu-padring) — Chipathon fork
