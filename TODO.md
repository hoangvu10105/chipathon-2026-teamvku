# TODO - TeamVKU SSCS Chipathon 2026

> Updated: 2026-06-23 | Repository: `hoangvu10105/chipathon-2026-teamvku`

---

## Completed

### Code fixes

- [x] Reworked `cocotb/chip_top_tb.py` for SFE-oriented tests:
  startup, AER events, config modes, and output health check.
- [x] Enabled `chip_id` and wafer.space logo macros in `librelane/config.yaml`
  and `src/chip_top.sv`.
- [x] Added schematic-review documentation for CDC, power domains, and
  `input_en_q`.
- [x] Added reset/control fanout buffering through `sfe_fanout_buffer`.
- [x] Added post-global-route repair knobs in `librelane/config.yaml`.
- [x] Added `make copy-final` target so final LibreLane views can be copied
  into `final/` before `make render-image` or `GL=1 make sim-gl`.

### Remote build status from `logs/rebuild_w27.log`

- [x] LibreLane flow completed all 83 stages.
- [x] Magic DRC: passed.
- [x] Netgen LVS: passed, circuits match uniquely.
- [x] Antenna report: passed.
- [x] Setup timing: no violations found.
- [x] Hold timing: no violations found.
- [x] Final views saved by LibreLane.

### SFE functional status

```text
RTL functional test: PASSED
Observed event activity: 9997 events / 10004 cycles
Workshop-slot channels: 20 instantiated in `src/chip_core.sv`
Generic SFE IP default: 32 channels in `src/sfe_audio_frontend_top.sv`
```

---

## Still Open / Must Fix

### 1. Electrical warning closure

The latest committed `docs/build_metrics.csv` is still the older metrics file
and reports:

| Metric | Current committed metric |
|---|---:|
| max slew violations | 3180 |
| max fanout violations | 77 |
| max cap violations | 38 |

Action items:

- [ ] Pull the newest `final/metrics.csv` from the remote LibreLane run.
- [ ] Replace/update `docs/build_metrics.csv` and `docs/build_metrics.json`.
- [ ] Confirm whether the final run truly closes max slew/cap/fanout or only
  passes timing/DRC/LVS/antenna.
- [ ] If violations remain, run another closure pass with tighter repair
  settings or a smaller/faster SFE wrapper configuration.

### 2. Post-build verification

Run after final views are available locally:

```bash
make copy-final
make render-image
GL=1 make sim-gl
```

Expected deliverables:

- [ ] `final/gds/chip_top.gds`
- [ ] `final/nl/chip_top.nl.v` or final gate-level netlist
- [ ] `final/sdc/chip_top.sdc`
- [ ] `final/sdf/chip_top.sdf`
- [ ] `final/spef/chip_top.spef`
- [ ] `final/metrics.csv`
- [ ] `img/chip_top.png`

### 3. Schematic Review - July 3

- [ ] Update `docs/design/TeamVKU_Schematic_Review_W27.pptx`.
- [ ] Add final GDS/layout screenshot.
- [ ] Add final metrics table after refreshing `final/metrics.csv`.
- [ ] Explain remaining electrical warnings honestly if not fully closed.
- [ ] Submit Week 26 report: https://forms.gle/6839F1Jppxx42yw5A

### 4. GitHub / submission

- [ ] Keep the repository private if required by the organizers.
- [ ] Keep Issue #167 updated on `sscs-ose/sscs-chipathon-2026`.
- [ ] Attach final metrics, layout image, and status summary once copied from
  the remote build.

---

## Current Honest Verdict

```text
Track A positioning: READY
RTL/cocotb testbench: READY
LibreLane build completion: READY
DRC/LVS/Antenna/timing: CLEAN in latest log
Max slew/cap/fanout closure: NEEDS FINAL METRICS CONFIRMATION
Gate-level regression: NOT YET
Final submission package: NOT YET
```

---

## Useful Links

| Resource | URL |
|---|---|
| GitHub Repo | https://github.com/hoangvu10105/chipathon-2026-teamvku |
| Chipathon Schedule | https://github.com/sscs-ose/sscs-chipathon-2026/tree/main/schedule |
| Weekly Report Form | https://forms.gle/6839F1Jppxx42yw5A |
| Discord | https://discord.gg/tvZcQzvt7q |
| Issue #167 | https://github.com/sscs-ose/sscs-chipathon-2026/issues/167 |