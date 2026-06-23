# Weekly Report - Week 26 (June 19 - June 26, 2026)

**Team:** TeamVKU
**Track:** A - Foundational Building Blocks
**Project:** SFE Audio Frontend - Spiking Frequency Encoder Bank

---

## Progress This Week

### RTL and Integration

- Root cause identified: high fanout on `rst_core_n` into the SFE core.
- Added `sfe_fanout_buffer` for reset/control fanout reduction.
- Added `SYNTH_MAX_FANOUT: 10`, `MAX_TRANSITION_CONSTRAINT: 3.0`, and
  post-global-route repair settings to `librelane/config.yaml`.
- Enabled required `chip_id` macro and wafer.space logo macro.
- Reworked cocotb testbench for SFE-oriented startup, AER, config, and health
  checks.

### Physical Build

- LibreLane rebuild completed according to `logs/rebuild_w27.log`.
- Flow reached stage 83/83.
- Magic DRC passed.
- Netgen LVS passed.
- Antenna report passed.
- Setup and hold timing checkers reported no violations.

### Documentation

- Added Schematic Review notes for CDC, reset synchronizer, power domain, and
  `input_en_q`.
- Updated TODO and submission checklist to separate completed signoff checks
  from remaining electrical-warning closure.
- Added `make copy-final` to simplify post-build artifact collection.

---

## Challenges

- The committed `docs/build_metrics.csv/json` still contain older electrical
  warning counts and must be refreshed from the newest remote `final/metrics.csv`.
- Max slew/cap/fanout closure should not be claimed until the new metrics file
  confirms it.
- Gate-level simulation still needs to be run after final views are copied.
- Week 27 schematic-review slides need the final layout screenshot and metrics.

---

## Next Steps

1. Copy final views with `make copy-final`.
2. Render chip layout with `make render-image`.
3. Run gate-level regression with `GL=1 make sim-gl`.
4. Refresh `docs/build_metrics.csv` and `docs/build_metrics.json`.
5. Update `docs/design/TeamVKU_Schematic_Review_W27.pptx`.
6. Submit Week 26 report through the Google Form.

---

## Links

- GitHub: https://github.com/hoangvu10105/chipathon-2026-teamvku
- Issue #167: https://github.com/sscs-ose/sscs-chipathon-2026/issues/167
- Report Form: https://forms.gle/6839F1Jppxx42yw5A