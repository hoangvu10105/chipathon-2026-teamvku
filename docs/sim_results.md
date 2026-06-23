# Simulation Results

## SFE Core Functional Test

**Date:** 2026-06-23
**Tool:** Icarus Verilog and cocotb flow inside the Chipathon GF180 container
**Status:** PASSED for RTL-level SFE functionality

## Test Setup

- Workshop-slot SFE wrapper with 20 instantiated channels in `src/chip_core.sv`.
- Generic SFE IP remains parameterized and defaults to 32 channels in
  `src/sfe_audio_frontend_top.sv`.
- 16-bit data path.
- 25 MHz clock target.
- Deterministic input stimulus to exercise event generation.

## Results

```text
Compile: OK
Events observed: 9997 events / 10004 cycles
Workshop-slot channels instantiated: 20
Overflow: not observed in the reported functional smoke test
Status: PASS
```

## Observations

1. Event activity is present and sustained.
2. Multiple channels fire, confirming that the SFE bank is not stuck on one
   output channel.
3. The test is sufficient as a functional smoke test before gate-level
   regression.

## Known Limitations

- Full gate-level simulation requires final post-PNR netlist/SDF/SPEF views.
- The committed metrics file still needs to be refreshed from the newest
  LibreLane run.
- Analog frontend simulation is not included in this Track A digital building
  block submission.

## Next Steps

- [ ] Run full cocotb RTL test in the GF180 container.
- [ ] Run gate-level sim with SDF back-annotation after `make copy-final`.
- [ ] Refresh final metrics and add the result to Week 27 schematic review.
- [ ] Add power-aware simulation if the contest review requires it.