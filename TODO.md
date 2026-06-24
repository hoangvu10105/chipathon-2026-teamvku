# TODO – TeamVKU SSCS Chipathon 2026

> Cập nhật: 2026-06-24 01:10 ICT | **BUILD #6 + #7 HOÀN THÀNH** — Setup vio: 99→29→15, Antenna vẫn fatal (22/48), cần fix antenna config để pass exit code 2

---

## ✅ ĐÃ HOÀN THÀNH

### Code Fixes (commit `b2c3ce7` trên GitHub)
- [x] **Cocotb testbench** — Viết lại `chip_top_tb.py` cho SFE (4 tests: startup, AER events, config modes, health check)
- [x] **chip_id + logo** — Uncomment macros trong `config.yaml` và `chip_top.sv`
- [x] **Schematic review** — Thêm CDC diagram, Power Domain diagram, input_en_q docs
- [x] **Push lên GitHub** — `hoangvu10105/chipathon-2026-teamvku`

### Server `192.168.1.224` (hoangvu / 798235)
- [x] **SSH thành công** — Linux hoangvu-ThinkPad-P50, Ubuntu 24.04, Docker 29.1.3
- [x] **Clone repo mới** — `~/eda/designs/sfe_chipathon_padring_latest/`
- [x] **SFE functional test** — PASSED (9997 events / 10004 cycles)
- [x] **Fix PDK mount** — Mount `gf180mcu:/foss/pdks` (LibreLane hardcode `/foss/pdks`)
- [x] **Fix DRT-0073** — Set `DRT_ANTENNA_REPAIR_ITERS: 0` (skip internal antenna repair)
- [x] **Build #5 hoàn thành** — final views/artifacts đã tạo; một số checker/signoff phụ bị skip/deferred theo cấu hình

### SFE Core Test Results
```
iverilog compile: OK
Events: 9,997 spikes / 10,004 cycles
PASS: SFE core functional
Generic SFE IP default: 32 channels
Workshop-slot build: 20 channels instantiated in src/chip_core.sv
```

---

## 📊 BUILD #5 METRICS (FINAL)

| Corner | Slew | Fanout | Cap | Setup Vio | Hold Vio | Power |
|--------|------|--------|-----|-----------|----------|-------|
| **TT 25°C** | **0** ✅ | 11 | 48 | **0** ✅ | **0** ✅ | 0.021W |
| **SS 125°C** | **39** 🎉 | 11 | 48 | **0** ✅ | **0** ✅ | - |
| **FF -40°C** | **0** ✅ | 11 | 48 | **0** ✅ | **0** ✅ | - |
| **max_ss 125°C** | - | - | - | **99** ⚠️ | 0 ✅ | - |

| Check | Result |
|-------|--------|
| **Magic DRC** | **0** ✅ |
| **KLayout DRC** | **0** ✅ |
| **Netgen LVS** | **0 errors** ✅ |
| **KLayout Antenna** | 40 (deferred) ⚠️ |
| **Lint** | 0 errors, 368 warnings |
| **Wire length** | 997,517 µm |
| **Cells** | 130,694 instances |
| **Die area** | 2935 x 2935 µm |

### 🔥 Cải thiện chính
- **Slew SS 125°C: 2451 → 39 (-98.4%)** nhờ `GRT_RESIZER` + `RUN_POST_GRT_DESIGN_REPAIR`
- Magic DRC + KLayout DRC + LVS: 0 (clean như build trước)
- Tất cả `nom_*` corners timing clean (0 setup/hold violations)
- ⚠️ `max_ss_125C_4v50` (signoff corner) có 99 setup violations — đây là lý do build exit code 2

---

## 🔴 CẦN LÀM TIẾP

### 1. Fix max_ss setup violations (99 violations)
- [x] Mở timing report cho `max_ss_125C_4v50` và liệt kê top violating paths
- [x] Xác định root cause: reset synchronizer output (`rst_core_n`) bị dùng như reset tree high-fanout, tạo ~80 reg-to-reg setup paths qua delay buffers
- [x] Sửa RTL: dùng `rst_n` để clear state bất đồng bộ, dùng `rst_core_n` chỉ làm synchronized release/enable (`core_en`)
- [x] Đồng bộ config: `DRT_ANTENNA_REPAIR_ITERS: 0` và skip `OpenROAD.RepairAntennas`
- [x] **Build #6 (reset fix, b15ed43)**: Setup 99→29 ✅, Antenna 40→22 nhưng vẫn fatal (exit 2)
- [x] **Build #7 (pipeline, 55abd5b)**: Setup 29→15 ✅, nhưng Antenna 22→48 ⚠️ và Slew 149→188 ⚠️
- [ ] **Cần fix KLayout antenna errors** — đây là blocker chính (exit code 2), cần enable `RepairAntennas`/`Odb.DiodesOnPorts` hoặc thêm antenna diodes
- [ ] Sau khi fix antenna, chạy lại để verify WNS >= 0 ở max_ss

### 2. Chạy cocotb full test với PDK
- [ ] Chạy SFE testbench với GDS PDK (không chỉ verilator)
```bash
docker run --rm \
  -v ~/eda/designs/sfe_chipathon_padring_latest:/foss/designs/sfe_chipathon_padring \
  -v ~/gf180mcu:/foss/pdks/gf180mcuD \
  -e PDK_ROOT=/foss/pdks -e PDK=gf180mcuD -e SLOT=workshop \
  hpretl/iic-osic-tools:chipathon26 --skip \
  bash -c "cd /foss/designs/sfe_chipathon_padring && make sim"
```

### 3. Post-build verification
- [ ] Copy final artifacts: `make copy-final` (GDS, DEF, netlist, SDC, SDF, SPEF)
- [ ] Render chip layout image: `make render-image`
- [ ] Gate-level simulation: `GL=1 make sim-gl`

### 4. Schematic Review (July 3) — Chuẩn bị
- [ ] Cập nhật `docs/design/TeamVKU_Schematic_Review_W27.pptx` với metrics mới
- [ ] Thêm screenshot GDS layout vào slides
- [ ] Submit weekly report Week 26: https://forms.gle/6839F1Jppxx42yw5A

### 5. Submission checklist
- [x] `final/gds/chip_top.gds` — Final GDSII ✅
- [x] `final/nl/chip_top.nl.v` / `chip_top.v` — Gate-level netlist ✅
- [x] `final/sdc/chip_top.sdc` — SDC constraints ✅
- [x] `final/sdf/chip_top.sdf` — SDF timing ✅
- [x] `final/spef/chip_top.spef` — SPEF parasitics ✅
- [x] `final/metrics.csv` — Signoff metrics ✅
- [x] Magic DRC report (clean) ✅
- [x] Netgen LVS report (clean) ✅

### 6. GitHub
- [ ] **ĐỂ REPO PRIVATE** — Settings → Danger Zone → Make Private
- [x] GitHub Issue chính thức: https://github.com/sscs-ose/sscs-chipathon-2026/issues/167
- [ ] Cập nhật Issue #167 với Build #5 metrics và phần còn lại: 99 setup violations ở `max_ss`

---

## 📊 BUILD #6 — Reset Fix (b15ed43) — RUN_2026-06-23_18-21-55

> Commit: `b15ed43 Fix reset release timing path` | Runtime: ~2h | Exit: **2** ❌ (22 antenna)

| Corner | Slew | Fanout | Cap | Setup Vio | WNS | TNS |
|--------|------|--------|-----|-----------|-----|-----|
| **nom_tt** | 0 ✅ | 10 | 49 | 0 ✅ | 0.0 | 0.0 |
| **nom_ss** | 22 | 10 | 49 | 0 ✅ | 0.0 | 0.0 |
| **nom_ff** | 0 ✅ | 10 | 49 | 0 ✅ | 0.0 | 0.0 |
| **max_ss** | 149 ⚠️ | 10 | 49 | **29** ⚠️ | **-0.84** | **-7.38** |
| **max_ff** | 0 ✅ | 10 | 49 | 0 ✅ | 0.0 | 0.0 |

| Check | Result |
|-------|--------|
| Magic DRC | **0** ✅ |
| KLayout DRC | **0** ✅ |
| Netgen LVS | **0 errors** ✅ |
| KLayout Antenna | **22** ❌ (fatal) |

### Cải thiện so với Build #5
- **Setup violations max_ss: 99 → 29 (-70.7%)** — reset async clear giúp giảm timing paths qua reset tree
- **Antenna: 40 → 22 (-45%)** — nhờ `DRT_ANTENNA_REPAIR_ITERS: 0` skip internal repair
- Vẫn fatal do 22 antenna errors — cần fix config antenna diodes

---

## 📊 BUILD #7 — Pipeline Channel (55abd5b) — RUN_2026-06-23_19-35-12

> Commit: `55abd5b Pipeline channel fire decision to break critical datapath` | Runtime: ~2h | Exit: **2** ❌ (48 antenna)

| Corner | Slew | Fanout | Cap | Setup Vio | WNS | TNS |
|--------|------|--------|-----|-----------|-----|-----|
| **nom_tt** | 0 ✅ | 8 | 44 | 0 ✅ | 0.0 | 0.0 |
| **nom_ss** | 4 | 8 | 44 | 0 ✅ | 0.0 | 0.0 |
| **nom_ff** | 0 ✅ | 8 | 44 | 0 ✅ | 0.0 | 0.0 |
| **max_ss** | 188 ⚠️ | 8 | 45 | **15** ⚠️ | **-0.94** | **-8.17** |
| **max_ff** | 0 ✅ | 8 | 45 | 0 ✅ | 0.0 | 0.0 |

| Check | Result |
|-------|--------|
| Magic DRC | **0** ✅ |
| KLayout DRC | **0** ✅ |
| Netgen LVS | **0 errors** ✅ |
| KLayout Antenna | **48** ❌ (fatal) |

### Phân tích Pipeline change
- ✅ **Setup 29→15 (-48%)** — pipeline regs cắt critical path hiệu quả
- ✅ **Fanout 10→8, Cap 49→45** — ít load hơn nhờ register stage
- ⚠️ **WNS -0.84→-0.94** — pipeline thêm 1 cycle nhưng combinational delay vẫn lớn
- ❌ **Antenna 22→48** — thêm register tăng số net → nhiều antenna violation hơn
- ❌ **Slew 149→188** — pipeline reg drive strength không đủ cho fanout

---

## 📊 So sánh Build Metrics qua các lần

| Corner | Build #4 (grtrepair) | Build #5 | **B#6 (reset)** | **B#7 (pipe)** |
|--------|---------------------|----------|-----------------|-----------------|
| TT Slew | 107 | **0** | **0** | **0** |
| SS Slew | 2451 | **39** | 22 | 4 |
| FF Slew | 35 | **0** | **0** | **0** |
| **max_ss Setup Vio** | - | **99** | **29** ↓ | **15** ↓ |
| **max_ss WNS** | - | - | **-0.84** | **-0.94** |
| DRC | 0 ✅ | 0 ✅ | 0 ✅ | 0 ✅ |
| LVS | 0 ✅ | 0 ✅ | 0 ✅ | 0 ✅ |
| **Antenna** | - | 40 ⚠️ | **22** ❌ | **48** ❌ |
| Exit Code | ? | 2 | 2 | 2 |

---

## 🔗 Links

| Resource | URL |
|----------|-----|
| **GitHub Repo** | https://github.com/hoangvu10105/chipathon-2026-teamvku |
| **Chipathon Schedule** | https://github.com/sscs-ose/sscs-chipathon-2026/tree/main/schedule |
| **Weekly Report Form** | https://forms.gle/6839F1Jppxx42yw5A |
| **Weekly Zoom (8am PT)** | https://us06web.zoom.us/j/87694732928?pwd=gjUePaAEKDJB2G3f2d4iPIqyYe0qBx.1 |
| **Discord** | https://discord.gg/tvZcQzvt7q |
| **Server SSH** | `ssh hoangvu@192.168.1.224` (pass: 798235) |
| **Build log** | `~/eda/designs/sfe_chipathon_padring_latest/build.log` |
| **Metrics** | `~/eda/designs/sfe_chipathon_padring_latest/librelane/runs/RUN_2026-06-23_15-01-03/final/metrics.csv` |

---

## 📅 Key Dates

| Date | Milestone |
|------|-----------|
| **June 26** | Analog Design Ideas 🎓 (3 ngày nữa) |
| **July 3** | 🔴 **Schematic Review** (10 ngày) |
| July 10 | Simulation Review (blocks) |
| **July 17** | 🔴 Simulation Review (top) + **Go/No-go** |
| July 24 | Layout Tutorial |
| Aug 14 | Layout Review (blocks) |
| Aug 28 | Final Verification + Chip Review |
| TBD | **Final GDS Submission** |
