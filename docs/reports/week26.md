# Weekly Report – Week 26 (June 19 – June 26, 2026)

**Team:** TeamVKU | **Track:** A – Foundational Building Blocks  
**Project:** SFE Audio Frontend – Spiking Frequency Encoder Bank

---

## Progress This Week

### Slew Violation Fix
- ✅ Root cause identified: `rst_core_n` → 891 loads → 182ns slew @ SS corner
- ✅ Added `sfe_fanout_buffer` for `rst_core_n` in `chip_core.sv` (fanout ≤10 per stage)
- ✅ Added `SYNTH_MAX_FANOUT: 10` + `MAX_TRANSITION_CONSTRAINT: 3.0` to `config.yaml`
- 🔄 Rebuild pending on Linux machine

### Repository Setup
- ✅ Fork created: `hoangvu10105/chipathon-2026-teamvku`
- ✅ Full RTL source committed (6 SystemVerilog files)
- ✅ Professional README with architecture diagram, specs, build results
- ✅ Project documentation: design specs, proposal, weekly reports
- ✅ Proposal presentation (7 slides, PPTX)

### Documentation
- ✅ Architecture block diagram
- ✅ Full block specifications (parameters, interfaces, protocols)
- ✅ Build metrics exported (CSV + JSON)
- ✅ Chipathon 2026 milestone timeline

---

## Challenges
- 🔴 GitHub Issue creation pending (requires manual creation on sscs-ose repo)
- 🔴 Team code not yet assigned (waiting for Issue approval)
- ⚠️ Schematic review preparation needed for July 3

---

## Next Steps (Week 27)
1. 🔴 **CREATE GITHUB ISSUE** on sscs-ose/sscs-chipathon-2026
2. Submit abbreviated proposal slides to Google Drive
3. Prepare schematic diagrams for Week 27 Schematic Review
4. Rebuild with slew fix and verify improvement
5. Add cocotb simulation results
6. Submit Week 26 report via Google Form

---

## Links
- **GitHub:** https://github.com/hoangvu10105/chipathon-2026-teamvku
- **Proposal:** docs/proposal/TeamVKU_Chipathon2026_Proposal.pptx
- **Report Form:** https://forms.gle/6839F1Jppxx42yw5A
