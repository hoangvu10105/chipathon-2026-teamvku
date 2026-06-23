# TODO – TeamVKU SSCS Chipathon 2026

> Cập nhật: 2026-06-23 | Build đang chạy trên server `192.168.1.224`

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
- [x] **SFE functional test** — PASSED (9997 events, 32 channels)
- [x] **Build LibreLane** — Đang chạy (~2h15m), log tại `build.log`

### SFE Core Test Results
```
iverilog compile: OK
Events: 9,997 spikes / 10,004 cycles
PASS: SFE core functional
```

---

## 🔄 ĐANG CHẠY

- [ ] **LibreLane build** trên server (PID 6351) — đang clone PDK → synthesis → PnR → DRC/LVS/STA
  - Log: `~/eda/designs/sfe_chipathon_padring_latest/build.log`
  - Kiểm tra: `tail -f ~/eda/designs/sfe_chipathon_padring_latest/build.log`

---

## 🔴 CẦN LÀM TIẾP (Turn sau)

### 1. Kiểm tra build kết quả
- [ ] Build xong chưa? `tail -50 build.log`
- [ ] Đọc `librelane/runs/*/final/metrics.csv`
- [ ] So sánh slew violations (SS corner) — mục tiêu giảm từ 2451
- [ ] Kiểm tra chip_id + logo có trong GDS không

### 2. Chạy cocotb full test với PDK
```bash
docker run --rm \
  -v ~/eda/designs/sfe_chipathon_padring_latest:/foss/designs/sfe_chipathon_padring \
  -v ~/gf180mcu:/foss/pdks/gf180mcuD \
  -e PDK_ROOT=/foss/pdks -e PDK=gf180mcuD -e SLOT=workshop \
  hpretl/iic-osic-tools:chipathon26 --skip \
  bash -c "cd /foss/designs/sfe_chipathon_padring && make sim"
```

### 3. Schematic Review (July 3) — Chuẩn bị
- [ ] Kiểm tra `docs/design/TeamVKU_Schematic_Review_W27.pptx` — cần cập nhật sau build mới
- [ ] Thêm screenshot GDS layout vào slides
- [ ] Cập nhật metrics table với kết quả build mới
- [ ] Submit weekly report Week 26: https://forms.gle/6839F1Jppxx42yw5A

### 4. Post-build verification
- [ ] Copy final artifacts: `make copy-final` (GDS, DEF, netlist, SDC, SDF, SPEF)
- [ ] Render chip layout image: `make render-image`
- [ ] Gate-level simulation: `GL=1 make sim-gl`

### 5. Submission checklist
- [ ] `final/gds/chip_top.gds` — Final GDSII
- [ ] `final/nl/chip_top.v` — Gate-level netlist
- [ ] `final/sdc/chip_top.sdc` — SDC constraints
- [ ] `final/sdf/chip_top.sdf` — SDF timing
- [ ] `final/spef/chip_top.spef` — SPEF parasitics
- [ ] `final/metrics.csv` — Signoff metrics
- [ ] Magic DRC report (clean)
- [ ] Netgen LVS report (clean)

### 6. GitHub
- [ ] **ĐỂ REPO PRIVATE** — Settings → Danger Zone → Make Private
- [ ] Tạo GitHub Issue chính thức trên `sscs-ose/sscs-chipathon-2026` (nếu chưa có)

---

## 📊 Build Metrics Tham Khảo (Build trước - grtrepair45)

| Corner | Slew | Fanout | Cap | Timing | Power |
|--------|------|--------|-----|--------|-------|
| TT 25°C | 107 | 77 | 27 | 0 ✅ | 0.018W |
| **SS 125°C** | **2451** ⚠️ | 77 | 27 | 0 ✅ | - |
| FF -40°C | 35 | 77 | 26 | 0 ✅ | - |
| DRC | 0 ✅ | - | - | - | - |
| LVS | 0 ✅ | - | - | - | - |
| Lint | 0 ✅ | - | - | - | - |

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
