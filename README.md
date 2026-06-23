# TeamVKU – SSCS Chipathon 2026

> **[Track A] Foundational Building Blocks on GF180MCU**

**Team Lead:** Hoang Vu | **Team Code:** *(pending assignment)*

**GitHub:** https://github.com/hoangvu10105/chipathon-2026-teamvku

---

## 🎯 Project Overview

This repository is the **TeamVKU** submission for the **IEEE SSCS Chipathon 2026**, competing in **Track A: Foundational Building Blocks**.

Track A focuses on basic analog and digital building blocks implemented using the open-source GF180MCU process design kit (PDK) and the LibreLane 3.0 automated RTL-to-GDS flow.

### Target Design(s)

> *[Update this section with your specific block designs — e.g., OpAmp, Bandgap Reference, LDO, ADC, DAC, PLL, Standard Cell Library, etc.]*

- **Block 1:** TBD
- **Block 2:** TBD
- **Integration:** Workshop padring (60 analog pads, 20 bidir pads)

---

## 📁 Repository Structure

```
.
├── README.md                    # This file — project overview
├── AUTHORS.md                   # Team & copyright holders
├── CREDITS.md                   # Detailed credits & attributions
├── NOTICE                       # Apache-2.0 formal notice
├── LICENSE                      # Apache-2.0
├── docs/
│   ├── proposal/                # Proposal slides & documentation
│   ├── design/                  # Design specs, schematics, test plans
│   ├── workshop-slot-spec.md    # Full pad-by-pad mapping
│   ├── reproducing-native.md    # Nix-shell walkthrough
│   └── reproducing-docker.md    # Docker (iic-osic-tools) walkthrough
├── src/
│   ├── chip_top.sv              # Top-level wrapper (upstream)
│   ├── chip_core.sv             # Core design — replace with TeamVKU blocks
│   └── slot_defines.svh         # SLOT_WORKSHOP definitions
├── librelane/
│   ├── config.yaml              # LibreLane configuration
│   ├── pdn_cfg.tcl              # Power Delivery Network config
│   ├── chip_top.sdc             # Timing constraints
│   └── slots/
│       └── slot_workshop.yaml   # Workshop slot (2935×2935 µm)
├── cocotb/                      # Cocotb testbenches
├── examples/                    # Reference notebooks & examples
├── scripts/                     # Helper scripts (Docker, verification)
├── Makefile                     # Build automation
└── flake.nix / shell.nix        # Nix development environment
```

---

## 🏗️ GF180MCU Workshop Slot – Quick Reference

- **Die:** 2935 × 2935 µm
- **Core area:** 2051 × 2051 µm
- **60 × analog pads** (`gf180mcu_fd_io__asig_5p0`)
- **20 × bidir pads** (`gf180mcu_fd_io__bi_24t`)
- **4 × DVDD + 4 × DVSS** power pads
- **clk_pad, rst_n_pad**
- **4 × corner pads** (auto-inserted by LibreLane)

Full pad mapping: [`docs/workshop-slot-spec.md`](docs/workshop-slot-spec.md)

---

## 🚀 Quickstart

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Or Docker with [`hpretl/iic-osic-tools`](https://github.com/iic-jku/IIC-OSIC-TOOLS)

### Build (native, Nix shell)

```bash
git clone https://github.com/hoangvu10105/chipathon-2026-teamvku.git
cd chipathon-2026-teamvku
nix-shell                          # provides LibreLane 3.0.0
make clone-pdk                     # clones wafer-space/gf180mcu @ 1.8.0
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

### Output Artifacts

- `final/gds/chip_top.gds` — Final GDS (~85 MB)
- `final/metrics.csv` — Signoff metrics
- `final/*.log` — Per-stage logs

---

## 🔧 How to Integrate Your Design

1. Replace `src/chip_core.sv` with your RTL, keeping the port interface:
   - `NUM_INPUT=1`, `NUM_BIDIR=20`, `NUM_ANALOG=60`
   - `clk`, `rst_n`
2. Update `docs/design/` with your schematics and test plans.
3. Re-run: `SLOT=workshop make librelane`

The padring remains fixed — only the core changes.

---

## 📝 Design Flow

```
Specification
    ↓
Schematic Capture (xschem)
    ↓
SPICE Simulation (ngspice)
    ↓
RTL Design (SystemVerilog)
    ↓
Synthesis (Yosys + OpenROAD / LibreLane)
    ↓
Layout & DRC/LVS (Magic / KLayout)
    ↓
GDS Submission
```

---

## ✅ Verification

Reference build validated **2026-04-23** with LibreLane 3.0 + wafer-space PDK 1.8.0 (DRC/LVS/antenna/STA signoff).

```bash
scripts/verify_workshop_slot.sh /path/to/reference/template
```

---

## 📅 Chipathon 2026 – Key Dates (Track A)

| Week | Date | Milestone |
|------|------|-----------|
| Week 26 | June 26 | Analog Design Ideas (Tutorial) |
| Week 27 | July 3 | **Schematic Review** 👥 |
| Week 28 | July 10 | Simulation Review (blocks) |
| Week 29 | July 17 | Simulation Review (top level) + **Go/No-go** |
| Week 33 | Aug 14 | Layout Review (blocks) |
| Week 34 | Aug 21 | Layout Review (top level) |
| Week 35 | Aug 28 | Verification + Final Chip Review |
| TBD | — | **Final GDS Submission** |

---

## 👥 Team

| Name | Role | GitHub |
|------|------|--------|
| Hoang Vu | Team Lead | [@hoangvu10105](https://github.com/hoangvu10105) |
| *Your Name* | *Member* | *...add team members...* |

---

## 📞 Support

- **Track A Leaders:** James Stine, Saroj, Gaurav, Akhilesh Patil, Sumanth Kamineni
- **Discord:** [SSCS Chipathon Server](https://discord.gg/tvZcQzvt7q) → `#2026-track-a-foundational-building`
- **Issues:** [sscs-ose/sscs-chipathon-2026/issues](https://github.com/sscs-ose/sscs-chipathon-2026/issues)

---

## 📄 License

Apache-2.0, inherited from upstream. See [`LICENSE`](LICENSE), [`NOTICE`](NOTICE), and [`AUTHORS.md`](AUTHORS.md).

---

## 🙏 Credits

This repository is derived from:
- [wafer-space/gf180mcu-project-template](https://github.com/wafer-space/gf180mcu-project-template) — by Leo Moser & contributors
- [JuanMoya/padring_gf180](https://github.com/JuanMoya/padring_gf180) — Workshop pad layout
- [Mauricio-xx/chipathon-2026-gf180mcu-padring](https://github.com/Mauricio-xx/chipathon-2026-gf180mcu-padring) — Chipathon 2026 workshop fork

See [`CREDITS.md`](CREDITS.md) for full attributions.
