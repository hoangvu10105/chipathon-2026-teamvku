# SFE Chipathon Adapter Notes

This staged workshop-slot design replaces the default counter `chip_core.sv`
with the SFE audio frontend adapter.

Run inside the Chipathon IIC-OSIC tools container:

```sh
cd /foss/designs/sfe_chipathon_padring
SLOT=workshop make librelane
```

Archive `runs/*/final/metrics.csv`, final GDS, final Verilog, logs, Magic DRC,
Netgen LVS, and STA reports for review.
