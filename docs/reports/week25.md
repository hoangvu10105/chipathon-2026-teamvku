# Weekly Report – Week 25 (June 12 – June 19, 2026)

**Team:** TeamVKU | **Track:** A – Foundational Building Blocks  
**Project:** SFE Audio Frontend – Spiking Frequency Encoder Bank

---

## Progress This Week

### RTL Design
- ✅ Completed `sfe_encoder_bank.sv` — 32-channel encoder bank with fanout buffer tree
- ✅ Completed `sfe_channel.sv` — Single-channel adaptive integrate-and-fire neuron
- ✅ Completed `sfe_event_packetizer.sv` — AER protocol event packer with FIFO
- ✅ Completed `sfe_fanout_buffer.sv` — Generic fanout buffer tree (max 10 per stage)
- ✅ Completed `sfe_audio_frontend_top.sv` — Top-level SFE wrapper
- ✅ Updated `chip_core.sv` — Workshop padring adapter for SFE frontend

### Build & Integration
- ✅ Full LibreLane 3.0 flow successful (RTL → GDS)
- ✅ GF180MCU PDK 1.8.0 integration working
- ✅ Workshop slot (2935×2935 µm) configured
- ✅ Build signoff: 0 lint errors, 0 timing violations

### Build Results
| Metric | Value |
|--------|-------|
| Instances | 129,874 |
| Area | 7,814,220 µm² |
| Total Power | 0.018 W |
| Setup violations | 0 |
| Hold violations | 0 |

---

## Challenges
- ⚠️ 2470 max_slew violations at SS corner (125°C, 4.5V) — root cause identified: `rst_core_n` fans out to 891 loads through minimal buffering
- ⚠️ 65 max_fanout violations and 22 max_cap violations remaining

---

## Next Steps
1. Fix slew violations: add reset buffer tree in RTL + tighter synthesis constraints
2. Create GitHub repo and proposal slides
3. Register team with official Chipathon issue
4. Prepare for Week 27 Schematic Review (July 3)

---

## Links
- **GitHub:** https://github.com/hoangvu10105/chipathon-2026-teamvku
