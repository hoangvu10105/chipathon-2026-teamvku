# SFE Audio Frontend - Tapeout Submission Package

TeamVKU - Track A - SSCS Chipathon 2026

## Required Files

- [ ] `final/gds/chip_top.gds` - Final GDSII layout
- [ ] `final/def/chip_top.def` - Final DEF
- [ ] `final/nl/chip_top.nl.v` or final gate-level netlist
- [ ] `final/sdc/chip_top.sdc` - Final SDC constraints
- [ ] `final/sdf/chip_top.sdf` - Final SDF timing
- [ ] `final/spef/chip_top.spef` - Final SPEF parasitics
- [ ] `final/metrics.csv` - Signoff metrics
- [x] `src/` - RTL source files
- [x] `librelane/config.yaml` - LibreLane configuration
- [x] `README.md` - Project documentation

## Verification Reports

- [x] Magic DRC report clean in `logs/rebuild_w27.log`
- [x] Netgen LVS report clean in `logs/rebuild_w27.log`
- [x] Antenna report passed in `logs/rebuild_w27.log`
- [x] Setup/Hold timing clean in `logs/rebuild_w27.log`
- [ ] Final `metrics.csv` refreshed in repository
- [ ] Gate-level regression after `make copy-final`

## Documentation

- [x] Project proposal
- [x] Schematic review notes
- [x] Week 25 report
- [x] Week 26 report draft
- [x] Chip ID / logo macros included
- [ ] Week 27 schematic review slides updated with final metrics

## Build Summary

| Metric | Current repository status |
|---|---|
| Latest log | `logs/rebuild_w27.log` |
| Flow completion | 83/83 stages complete |
| Magic DRC | Clean in latest log |
| Netgen LVS | Clean in latest log |
| Antenna | Passed in latest log |
| Setup/Hold timing | No violations in latest log |
| Committed metrics file | `docs/build_metrics.csv` still shows older electrical DRV counts |
| Max slew/cap/fanout | Needs final `metrics.csv` refresh and closure confirmation |
| Total power | 0.01791 W in committed metrics |
| Instance count | 129,873 in committed metrics |

Do not claim final electrical closure until the newest `final/metrics.csv` is
copied from the remote build and replaces the stale committed metrics.

## Team Info

- Team: TeamVKU
- Track: A - Foundational Building Blocks
- Lead: Hoang Vu
- GitHub: https://github.com/hoangvu10105/chipathon-2026-teamvku
- Issue: https://github.com/sscs-ose/sscs-chipathon-2026/issues/167