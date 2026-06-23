# Proposal – TeamVKU

## SSCS Chipathon 2026 – Track A: Foundational Building Blocks

### Project: SFE Audio Frontend – Spiking Frequency Encoder Bank

> *Official template: [`template_2026_ChipathonProposals.pptx`](https://raw.githubusercontent.com/sscs-ose/sscs-chipathon-2026/main/resources/documents/template_2026_ChipathonProposals.pptx)*

---

## Executive Summary

We propose a **32-channel Spiking Frequency Encoder (SFE)** audio frontend ASIC implemented on the **GF180MCU** open-source process. The SFE converts time-domain audio signals into sparse spike-event streams using an adaptive integrate-and-fire neuron model per frequency channel, enabling ultra-low-power neuromorphic audio processing.

### Key Innovation
- **Parallel 32-channel filterbank** with 16-bit data width
- **Adaptive threshold** per channel for robust encoding across input amplitudes
- **AER (Address Event Representation)** output protocol — industry-standard for neuromorphic systems
- **Fanout buffer tree** architecture ensuring clean timing closure
- **12.9K gates** at 180nm, 0.018W total power

---

## Team

| Name | Role | Affiliation |
|------|------|-------------|
| **Hoang Vu** | Team Lead, RTL Design | VKU |
| *TBD* | *Member* | *TBD* |

---

## Block Diagram

```
Analog Audio In → [Future AFE] → Filterbank (32-ch) → SFE Core → AER Packetizer → Digital Pads (20×Bidir)
                                                                                        ↓
                                                                                 Analog Pads (60×) reserved
```

---

## Target Specifications

| Parameter | Target |
|-----------|--------|
| Process | GF180MCU (180nm) |
| Die Size | 2935 × 2935 µm |
| Core Area | 2051 × 2051 µm |
| Channels | 32 |
| Data Width | 16-bit |
| Max Frequency | TBD (post-layout STA) |
| Power | ~0.018 W (preliminary) |
| Output Protocol | AER (Address Event Representation) |
| Package | QFN-88 (compatible with Chipathon test board) |

---

## Current Status

- ✅ RTL design complete (SystemVerilog)
- ✅ LibreLane synthesis → GDS flow working
- ✅ Zero timing violations (setup/hold)
- ✅ Zero lint errors
- ⚠️ Slew violations at SS corner need fixing
- 🔲 Analog frontend integration (future phase)
- 🔲 Post-layout simulation with parasitics

---

## Links

- **GitHub:** https://github.com/hoangvu10105/chipathon-2026-teamvku
- **Proposal Slides:** *[TBD — add Google Slides/PowerPoint link]*
- **Abbreviated Proposal (2-min):** *[TBD — add Google Drive link]*
- **Issue:** *[TBD — create at sscs-ose/sscs-chipathon-2026]*
