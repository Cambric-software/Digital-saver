# Veyro hardware design proposal

**Status: proposal for approval (ROADMAP 4.5a).** This document selects a production architecture and prices it from public sources. It is not a built design. No board, case, battery or panel has been ordered, no prototype exists, and no value in this document is a measurement. Every number is either a published figure, arithmetic on published figures, or explicitly marked as an assumption or an allowance.

Read this before buying anything for the production watch. The bench prototype in [HARDWARE.md](HARDWARE.md) is a different device and still the only hardware that exists.

## 0. How to read this document

| Label | Meaning |
|---|---|
| **LISTED** | A public distributor or vendor page showed this price or figure on 2026-10-21. The source ID is in the row. |
| **QUOTE** | A supplier stated the price in an enquiry. It is not a public page and is not a production quote. |
| **ALLOWANCE** | A planning number with no supplier behind it. It is included so the total is not understated, and it must be replaced before a purchase order. |
| **ASSUMPTION** | A design or volume target. It is not a fact and may be wrong. |
| **MUST MEASURE** | The value can only be settled on an EVT board. |
| **UNKNOWN** | No source was found. It is not guessed. |
| **VERIFIED** | The cited page was fetched and read on 2026-10-21. |

Prices are USD. The exchange rate is **1 USD = 54.488856 EGP**, from [S1], updated 2026-10-21 00:02 UTC. At that rate **7,500 EGP = $137.64**. Egyptian VAT is 14%, so the ex-VAT planning revenue is **6,579 EGP = $120.74** [S32]. VAT is output tax collected for the state; it is not a cost line.

LCSC prices are web tier prices for the stated quantity, not production quotes. They exclude assembly, test, reels, tariffs and freight. The 10,000-unit column is a negotiation target, not a public tier: every price in it is a **TARGET** or an **ALLOWANCE**, and §9.2 marks which.

## 1. Decision record

### 1.1 The decision

Build the watch as a **Linux application processor plus a companion MCU**:

- **Application processor:** Rockchip **RV1106G3** — one Cortex-A7 at 1.2 GHz, a RISC-V MCU, a 1 TOPS NPU, a 2D graphics engine, **no GPU**, and **2 Gb (256 MB) DDR3L stacked in the package** [S2].
- **Companion and radio:** Espressif **ESP32-C6-MINI-1-N4** — Wi-Fi 6 (802.11ax), Bluetooth 5.3 LE and 802.15.4, 4 MB flash, in a pre-certified module [S4][S5].
- **Link between them:** **ESP-Hosted** over SDIO for Wi-Fi and UART for Bluetooth HCI and sensor reports [S26].
- **Display:** 1.43-inch round AMOLED, 466×466, **QSPI**, on-cell touch, **CO5300** driver [S7][S8].
- **Power:** **BQ25619** charger with NVDC power path, **AXP313A** PMIC, **BQ27427** fuel gauge [S9][S10][S12].
- **OS:** Buildroot Linux with **LVGL 9** on DRM/fbdev, drawing through the RV1106 2D engine. Not Android, not Flutter.

The full reasoning, and what it costs, is in §1.2–§1.4 and §9.

### 1.2 The three options

| Criterion | A. MCU + RTOS | B. Linux AP + companion | C. Wearable Android SoC |
|---|---|---|---|
| Example part | ESP32-S3-WROOM-1-N16R8, STM32U575VGT6, nRF5340 | RV1106G3 + ESP32-C6 | Snapdragon W5+ Gen 1 class |
| Part price evidence | S3: $3.5514 @1300 [S22]; U575: $5.0884 @90 [S24]; nRF5340: $5.262 @100 [S23] | $22.6582 @30 [S3] + $3.0419 @100 [S5] | **UNKNOWN** — no public SoC price found |
| MMU / Linux | **No** | **Yes** | **Yes** |
| Multi-process app model | No; FreeRTOS tasks | Yes; Linux processes | Yes; Android/Wear OS |
| Display interface | SPI/QSPI, no video | QSPI direct; MIPI DSI needs a bridge | MIPI DSI |
| Battery class | Best; 3–5 days plausible | 2–3 days with AP suspend; ~1.2–1.6 days with always-on display | 1–2 days |
| Licensing | None | None beyond BSP licences | Wear OS / Google agreement, terms **UNKNOWN** |
| Verdict | Fails the mission's OS gate | **Selected** | Fails on price evidence and licensing |

Option A is the cheapest and the only one that could plausibly reach 7,500 EGP with a healthy margin today. It fails the stated mission: an ESP32-S3 or Cortex-M33 has no MMU and cannot host Linux or a multi-process application model, so "a large custom operating system with its own system apps" would be a single RTOS firmware with screens, not an OS. That is a product decision for the owner, not an engineering trick. If the owner relaxes the OS requirement, Option A is the honest fallback and the rest of this document does not apply.

Option C is the only option that gives a real third-party app ecosystem. It is rejected because no public price exists for a W5/W4100-class SoC, and because Wear OS requires a Google agreement plus a 2 GB RAM / 32 GB storage class device. Mobvoi's own page for the W5+ Gen 1 watch confirms 2 GB RAM, 32 GB storage and Wear OS 3, and publishes no price in the fetched HTML [S31]. A programme that cannot state its SoC cost cannot be planned against 7,500 EGP.

Option B is selected because it is the cheapest architecture that passes the OS gate and whose cost can actually be computed. It buys that with two costs: a higher BOM and a shorter battery life than Option A.

### 1.3 What the decision costs

| Item | 1,000 units | 10,000 units (target) |
|---|---:|---:|
| Electronics and mechanical BOM | $91.27 | $59.17 |
| BOM in EGP | 4,973 | 3,224 |
| Landed with 4% freight and 30% duty | $123.40 / 6,724 EGP | $80.00 / 4,359 EGP |
| Gross contribution at 7,500 EGP retail | **−145 EGP** | **2,220 EGP (29.6%)** |
| After 2.5% gateway and 3% warranty | **−507 EGP** | **1,858 EGP (24.8%)** |

The arithmetic and its inputs are in §9. In one sentence: **at 1,000 units this design loses money at 7,500 EGP; at 10,000 units with a 30% duty assumption it contributes about 1,858 EGP per watch before R&D, marketing and salaries.**

### 1.4 What is still not decided

| Question | State |
|---|---|
| Final cell supplier and capacity | UNKNOWN; 500 mAh retail cell used as a placeholder |
| Production panel supplier and MOQ | QUOTE needed; one public panel page exists [S7] |
| 1,000-piece SoC price | UNKNOWN; $22.6582 is the 30-piece web tier |
| Duty classification (HS 9102 vs 8517.62) | UNKNOWN; 30% used as a sensitivity, not a fact |
| NTRA type-approval fee and duration | UNKNOWN |
| Enclosure supplier, tooling and finish | UNKNOWN |
| Factory test fixture and calibration station | UNKNOWN |
| Whether the owner accepts 1.0–2.9 days of battery (see §4.5) | **Owner decision** |

## 2. Compute

### 2.1 RV1106G3 as the application processor

The RV1106 family datasheet lists one Cortex-A7 at 1.2 GHz, a RISC-V co-processor, a 1 TOPS NPU, a 2D engine, **MIPI CSI input only**, a parallel RGB LCD output, SDIO 3.0, five I²C masters and two SPI controllers [S2]. The G3 variant stacks **2 Gb DDR3L** (256 MB) in the package [S2]. The package is QFN128.

That is enough for Linux, LVGL, a 466×466 framebuffer and 18 first-party apps. It is not enough for Android: 256 MB is below the practical Android wearable floor, and the part has **no GPU**, so SurfaceFlinger and Flutter's Linux embedder (which targets OpenGL) are not options.

The absence of MIPI DSI is the single most important interface fact. A DSI panel would require an external DSI bridge or a different SoC. QSPI is the direct path, and it is why the panel in §3 was selected.

The part has no public 1,000-piece tier on LCSC. The only listed prices on 2026-10-21 were **$25.3877 at 1 piece and $22.6582 at 30 pieces** [S3]. The 1,000-piece price is **UNKNOWN** and is the largest single unknown in the BOM. A $7.27 figure appears in the 10,000-unit column in §9 as a negotiation target, not a quote.

### 2.2 ESP32-C6 as companion and radio

The ESP32-C6-MINI-1-N4 provides Wi-Fi 6, Bluetooth 5.3 LE and 802.15.4, with 4 MB flash and a pre-certified module [S4][S5]. It costs **$3.0419 at 100 pieces** and **$2.8359 at 1,300 pieces** [S5].

Its job is not to run the UI. It owns:

1. Wi-Fi and BLE, exposed to Linux by **ESP-Hosted** over SDIO/UART [S26].
2. The always-on IMU on its own I²C bus, so wrist motion can wake the watch while the application processor is power-gated.
3. The haptic trigger and the charger interrupt, so a notification can be delivered without booting Linux.

The C6 datasheet gives **7 µA deep sleep**, 35 µA and 180 µA light sleep, and 17–38 mA modem sleep [S4]. The 7 µA figure is what makes the low-power mode in §4.6 possible.

### 2.3 Memory and storage

The RV1106G3 includes 256 MB of DDR3L but no boot flash. Linux needs a root filesystem, so the board needs **SPI NAND or eMMC**. No specific memory part has been sourced, so the BOM carries a **$5.00 ALLOWANCE** at 1,000 units and $3.50 at 10,000. That line is not a quote and must be replaced by a real part before layout.

The 256 MB of RAM is shared by the kernel, LVGL, the framebuffer and the app processes. A 466×466 RGB565 framebuffer is 434 KB; double buffering is 868 KB. That is comfortable. The constraint is storage and boot time, not RAM.

The boot chain is BootROM → SPI NAND/eMMC → U-Boot → Linux → `init`. The C6 boots independently and can hold the AP in reset. The Rockchip BSP version and its licence terms are **UNKNOWN** until the BSP is downloaded and read.

## 3. Display and touch

### 3.1 The panel

| Property | Value | Source |
|---|---|---|
| Diagonal | 1.43 inch | [S7] |
| Resolution | 466×466 | [S7] |
| Type | AMOLED, round, on-cell touch, cover glass | [S7] |
| Interface | MIPI / QSPI | [S7] |
| Driver IC | CO5300 (page prints "C05300") | [S7][S8] |
| Panel luminance | 700 cd/m² in the vendor table | [S7] |
| Price | **$7.80–$13.20**, depending on option | [S7] |

The Waveshare development board that uses this panel class is listed at **350 cd/m²** and 60,000:1 contrast, with the same CO5300 driver, QSPI interface and an **FT6146** touch controller [S6]. The difference matters: 700 cd/m² is the panel table, 350 cd/m² is the module-level figure. Plan the power budget at 350 cd/m² and treat 700 as a maximum that will cost current.

The BOM uses **$13.20**, the top of the public range, because the exact option (touch, cover glass, FPC) is not selected. The $7.80 low end is a sale price for a different option and is not used.

### 3.2 Why QSPI and not MIPI DSI

The RV1106 has **no DSI output**; it exposes MIPI CSI for cameras and a parallel RGB LCD interface [S2]. A DSI panel would need a DSI-to-RGB or DSI-to-QSPI bridge: extra part, extra power, extra failure mode. The CO5300 datasheet explicitly supports Quad-SPI and names watches and smart bands as target applications [S8]. QSPI is therefore the direct, cheapest interface.

### 3.3 Frame-rate arithmetic

One frame at 466×466, RGB565, is:

```
466 × 466 × 2 bytes = 434,312 bytes per frame
```

A four-lane QSPI link moves four bits per clock. At 100% efficiency:

| QSPI clock | Raw bandwidth | Frame ceiling |
|---:|---:|---:|
| 20 MHz | 10 MB/s | 23 fps |
| 40 MHz | 20 MB/s | 46 fps |
| 50 MHz | 25 MB/s | 58 fps |

Real efficiency is lower because of command, address and dummy cycles, panel porch and tearing control. The CO5300's maximum QSPI clock is in a table that could not be extracted from the PDF, so it is **MUST VERIFY** on the EVT board. Plan **30 fps for transitions and partial refresh**, and **no video playback**. This is a UI watch, not a video device. Claiming 60 fps would be dishonest.

### 3.4 Touch

The panel is on-cell touch; the Waveshare module uses the **FT6146** at I²C address `0x38` [S6]. The exact controller on the bare Tailor Pixels panel is **UNKNOWN** until the panel datasheet is supplied. The design reserves an I²C bus, an interrupt and a reset line for it, and the address is confirmed by the panel FPC, not assumed.

The old prototype's FT6336G is not carried forward. The new panel's touch controller is whatever the panel ships with.

## 4. Power

### 4.1 Rail plan

| Rail | Source | Load |
|---|---|---|
| `VSYS` 3.0–4.4 V | BQ25619 NVDC output or cell | PMIC, charger, gauge |
| `VDD_AP` 0.9 V | AXP313A DCDC1 | RV1106 core |
| `VDD_ARM` 1.1 V | AXP313A DCDC2 | Cortex-A7 |
| `VDD_LOGIC` 1.8 V | AXP313A DCDC3 / LDO | DDR3L, IO |
| `VDD_3V3` 3.3 V | AXP313A ALDO1 | sensors, display, C6 |
| `VDD_1V8` 1.8 V | AXP313A RTCLDO | RTC, always-on domain |
| `VLCD` | AXP313A DLDO1 | AMOLED panel |

The AXP313A provides **3 DCDC and 3 LDO outputs in a 3×3 mm QFN-20**, with dynamic voltage scaling and over/under-voltage protection [S9]. It has **no charger**, which is why the BQ25619 is a separate part. Using a PMIC with an integrated charger (a BQ25895-class part) was considered, but the BQ25619's NVDC path and 20 mA termination are a better fit for a 500 mAh cell [S10].

### 4.2 Charger

The **BQ25619** is a 1.5 A buck charger with NVDC power path, JEITA profile and **20 mA termination**, plus a 1 A boost for accessories [S10]. It costs **$0.5906 at 1,000 pieces** [S11].

NVDC matters because the watch must run from a deeply discharged cell without browning out the AP. The charge current is set by a resistor, not by firmware. For a 500 mAh cell, **250 mA (0.5C)** is the planning current: 500/250 = **2.0 hours** from empty to full, plus the CV tail. At 500 mA it is 1.0 hour, but the cell temperature and the 38 °C surface gate become the limit. The actual cell datasheet is **UNKNOWN**; 0.5C is an **ASSUMPTION** until the cell is chosen.

### 4.3 Fuel gauge

The **BQ27427** uses a 50 µA normal mode and **9 µA sleep** [S12], costs **$0.9807 at 1,000 pieces** [S13], and reports state-of-charge over I²C at `0x55`. It replaces the prototype's voltage-divider estimate, which drifts with load and temperature.

### 4.4 Cell

The BOM uses the **Adafruit 1578**, a 3.7 V 500 mAh protected LiPo, at **$7.95** [S25]. It is a retail sample part, not a production cell. A production cell must be a custom 500 mAh pouch with a protection circuit, a 2-pin connector or solder tabs, **UN38.3** test evidence and **IEC 62133-2** certification. No such cell has been quoted; the $4.00 figure in the 10,000-unit column is an **ASSUMPTION**.

Usable capacity is taken as **425 mAh (85% of nameplate)** for runtime arithmetic, to account for termination, cut-off and ageing. That is an **ASSUMPTION**, not a measurement.

### 4.5 Power budget

The budget assumes 20 interactions of one minute per day, BLE connected all day, one 10-minute Wi-Fi sync, PPG at 30 seconds every 30 minutes, and the IMU at 100 Hz on the C6. The **8 mA always-on display** line is an **ASSUMPTION** for a 10% white-pixel face, not a datasheet value; it dominates the runtime spread and MUST MEASURE. Every other current is an **ASSUMPTION / MUST MEASURE** except where a datasheet figure is named.

| Load | Current | Duty | mAh/day | Basis |
|---|---:|---:|---:|---|
| AP active | 90 mA | 20 min/day | 30.0 | ASSUMPTION |
| AP suspend | 3 mA | 23.67 h/day | 71.0 | ASSUMPTION |
| Display on | 45 mA | 20 min/day | 15.0 | ASSUMPTION |
| Always-on display | 8 mA | 0 h/day | 0.0 | ASSUMPTION |
| BLE connected | 0.8 mA | 24 h/day | 19.2 | ASSUMPTION |
| Wi-Fi sync | 80 mA | 10 min/day | 13.3 | ASSUMPTION |
| IMU | 685 µA | 24 h/day | 16.4 | BMI270 datasheet [S15] |
| PPG | 12 mA | 30 s per 30 min | 4.8 | ASSUMPTION |
| Haptic | 60 mA | 20 s/day | 0.3 | ASSUMPTION |
| PMIC + gauge | 80 µA | 24 h/day | 1.9 | BQ27427 50 µA [S12] |
| **Total** | | | **171.9** | |

Runtime = 425 mAh ÷ 171.9 mAh/day = **2.47 days**.

| AP suspend | AOD off | AOD 12 h/day | AOD 24 h/day |
|---:|---:|---:|---:|
| 2 mA | 2.87 days | 1.74 days | 1.25 days |
| 3 mA | 2.47 days | 1.59 days | 1.17 days |
| 5 mA | 1.94 days | 1.35 days | 1.03 days |

The table swaps only the AP suspend current over the same 23.67 h/day; the AOD columns add 8 mA for the stated hours. The spread is the honest answer: **1.0 to 2.9 days**, depending on two numbers nobody has measured — Linux suspend current and always-on display current.

### 4.6 The 80 µA gate, restated

The old spec demanded "under 80 µA with the display off and motion wake armed". A Linux application processor cannot suspend at 80 µA; its DDR refresh and regulator quiescent current are measured in milliamps. The gate as written would fail on day one and teach the team nothing.

Replace it with two modes and two gates:

| Mode | What is powered | Gate | Basis |
|---|---|---|---|
| **Low-power watch** | AP power-gated off; C6 deep sleep; IMU low-power; gauge sleeping | **≤80 µA** total | C6 7 µA [S4] + gauge 9 µA [S12] + IMU and leakage. **MUST MEASURE.** |
| **Smart watch** | Linux suspended, RAM retained, C6 connected | **≤3 mA** suspend | ASSUMPTION; the number to beat |

In low-power mode the watch shows time on a small always-on segment or wakes the AP for the face; it cannot run the LVGL shell. In smart mode it is a computer that sleeps. Both are legitimate products; they must be described separately on the box and in the manual. The 38 °C surface gate applies during charging; the AP stays suspended unless the user is active.

## 5. Radios, internet and certification

### 5.1 Wi-Fi and BLE

The C6 provides **Wi-Fi 6** and **BLE 5.3** [S4]. Linux sees a network interface through **ESP-Hosted** over SDIO [S26]; Bluetooth HCI goes over UART. This is a supported Espressif design, not a custom radio stack.

Internet access is **Wi-Fi only**, through a home access point or a phone hotspot. The phone app can also relay notifications over BLE. There is no cellular modem, so the watch is not independently connected away from Wi-Fi.

### 5.2 What is deliberately absent

A cellular watch needs a modem module, a SIM or eSIM, band-specific antennas, GCF/PTCRB conformance, NTRA approval for the modem and a data plan per unit. The certification budget is **UNKNOWN**; cellular is a second product, not a feature flag. NFC payment needs a secure element, EMVCo/network scheme certification and a bank issuer agreement. A **ST25R3916B** front end costs **$3.0593 at 1,000 pieces** [S29], but the part is not the hard cost. Both are deferred and neither is in the BOM; NFC can return on the spare I²C bus.

### 5.3 Certification

| Market | Requirement | State |
|---|---|---|
| Egypt | NTRA type approval for Wi-Fi/BLE [S30] | Not started; fee and duration UNKNOWN |
| Egypt | Customs classification, HS 9102 (watches) vs 8517.62 (communication equipment) [S33] | UNKNOWN; 30% duty used only as a sensitivity |
| EU | CE: RED 2014/53/EU, EMC, RoHS, REACH | Not started if exporting |
| US | FCC Part 15, if exporting | Not started |
| Global | UN38.3 for the cell and a lithium battery MSDS | Required before air freight |
| Global | IEC 62133-2 for the cell | Required by most buyers |
| Ingress | IEC 60529 IP67 | Design target, not tested |

The ESP32-C6 module is pre-certified, which reduces the radio work but does not remove end-product approval. The RV1106 is not a radio, so it does not add an RF filing by itself.

## 6. Sensors and bus plan

### 6.1 Sensors

| Function | Part | Interface | Address | Price | Source |
|---|---|---|---:|---:|---|
| Heart rate / SpO₂ (wellness) | MAX30101 | I²C | `0x57` | $6.0888 @100 | [S14] |
| Motion / steps | BMI270 | I²C or SPI | `0x68` | $1.4011 @1k | [S16] |
| Pressure / altitude | BMP581 | I²C | `0x47` | $1.5331 @1k | [S17][S18] |
| Skin temperature | STTS22H | I²C | `0x3C` | $1.3166 @1k | [S19] |
| Haptics | DRV2605L + LRA | I²C | `0x5A` | $0.7630 + $0.5289 | [S21][S20] |
| Audio out | MAX98357A | I²S | — | $0.3050 @1k | [S27] |
| Microphone | SPH0645LM4H-B | I²S | — | $1.9625 @100 | [S28] |
| NFC (deferred) | ST25R3916B | SPI or I²C | — | $3.0593 @1k | [S29] |

The MAX30101 and STTS22H datasheet PDFs were not retrievable on 2026-10-21 (timeouts), so their addresses are taken from the prototype and marked **MUST CONFIRM** against the vendor datasheet and the strap resistors before layout. The BMP581 datasheet gives `0x46` for SDO low and `0x47` for SDO high, so `0x47` in the table is a strap decision, not a fixed address [S17]. The LCSC pages confirm part number and price, not register detail [S14][S18][S19].

The MAX30101 is expensive at **$6.09**. A watch-grade PPG such as the VC31B class used by the prototype is likely cheaper, but no public price was found. The design keeps the MAX30101 because it is sourced and documented; a cheaper PPG is a cost-reduction task with its own optical validation. Audio uses the MAX98357A I²S amplifier and SPH0645 I²S microphone [S27][S28] for alarms and voice notes without a codec; there is no Bluetooth Classic, so HFP calling is not a v1 feature.

### 6.2 Bus plan — this is how the three-bus problem ends

The ESP32-S3 firmware declares three I²C buses but the chip has two controllers, so `I2C_NUM_2` cannot work. The new architecture does not patch that bug; it removes the constraint. The RV1106 has **five I²C master controllers** [S2].

| Bus | Controller | 400 kHz devices | Addresses |
|---|---|---|---|
| Power | AP I²C0 | AXP313A, BQ25619, BQ27427 | `0x34`, `0x6B`, `0x55` |
| Sensors | AP I²C1 | MAX30101, BMP581, STTS22H, DRV2605L | `0x57`, `0x47`, `0x3C`, `0x5A` |
| Touch | AP I²C2 | Touch controller | `0x38` |
| Motion | C6 I²C0 | BMI270 | `0x68` |
| Spare | AP I²C3 | NFC, future | — |

Rules that make this safe:

1. **One device, one master.** No device appears on two buses.
2. **No address collision on any bus.** The power bus has `0x34/0x6B/0x55`; the sensor bus has `0x57/0x47/0x3C/0x5A`; touch is alone at `0x38`.
3. **No mux.** Five controllers are enough; a mux would add a part, a channel select line and a failure mode for no benefit.
4. **The IMU belongs to the C6.** That is what allows motion wake while the AP is power-gated. The AP reads motion through the C6 link.
5. **Pull-ups are per bus**, sized for 400 kHz and the bus capacitance. The values are **MUST MEASURE** on EVT; the prototype's parallel breakout pull-ups are not a model.

This resolves ROADMAP 4.1's third-bus blocker by design. The firmware change is not made in this phase and must not be made against the S3 board.

### 6.3 Pin and interrupt budget

| Signal | Owner | Direction | Note |
|---|---|---|---|
| `AP_UART_TX/RX` | AP ↔ C6 | both | HCI and sensor reports |
| `SDIO_CLK/CMD/D0-D3` | AP ↔ C6 | both | ESP-Hosted Wi-Fi |
| `C6_WAKE_AP` | C6 → AP | input | motion or notification wake |
| `AP_WAKE_C6` | AP → C6 | output | host request |
| `CHG_INT` | BQ25619 → C6 | input | charger status |
| `GAUGE_INT` | BQ27427 → AP | input | low battery |
| `TOUCH_INT/RST` | Touch ↔ AP | both | — |
| `HAPTIC_TRIG` | C6 → DRV2605L | output | EN pin |
| `LCD_TE` | Panel → AP | input | tearing effect, optional |

Exact GPIO numbers are assigned at schematic capture, not in this document. The table is a budget, not a pin map.

## 7. Mechanical and environmental

### 7.1 Targets

Every number in this table is an **industrial-design target**, not a measured or sourced dimension.

| Parameter | Target | Why |
|---|---|---|
| Case diameter | 46 mm | Fits a 1.43-inch round panel with a bezel |
| Thickness | ≤12.5 mm | 500 mAh cell plus PCB plus panel |
| Bezel | 6000-series aluminium or 316L steel | Scratch resistance |
| Crystal | Chemically strengthened 2.5D glass | Drop and scratch |
| Rear | Optical polycarbonate window | PPG path |
| Strap | 20 mm quick-release | Standard tooling |

### 7.2 Stack-up budget

| Layer | Thickness | Basis |
|---|---:|---|
| Rear cover + optical window | 1.2 mm | ASSUMPTION |
| Cell | 5.0 mm | 500 mAh pouch class |
| PCB | 0.8 mm | 6-layer HDI |
| Display + touch + cover glass | 1.8 mm | Panel class |
| Gasket compression + clearance | 2.0 mm | ASSUMPTION |
| **Total** | **10.8 mm** | Leaves 1.7 mm under the 12.5 mm target |

This is arithmetic on assumptions. It shows the target is not obviously impossible; it does not show it is achievable.

### 7.3 Sealing and charging

A **4-pad magnetic pogo** is the baseline: two pads for 5 V and ground, two for factory UART. There is no exposed USB-C socket on the watch, so there is no USB port to seal. The pogo pads are gold-plated and recessed; the interface is **charging and factory test only**, not a user data port.

Sealing is a silicone compression gasket with a designed compression of about 20%. IP67 is the target. **3 ATM is not claimed**; swimming is not a supported feature until a 5 ATM design and test exist. The rear optical window is the hardest seal because it must be transparent and skin-flush.

### 7.4 Environmental gates

| Test | Standard | Pass criterion | State |
|---|---|---|---|
| Ingress | IEC 60529 IP67 | 30 min at 1 m, no water ingress | Not run |
| Drop | IEC 60068-2-31, 1.0 m onto steel | No glass crack, no loss of function | Not run |
| Thermal shock | −20 °C to +55 °C, 5 cycles | No seal or display failure | Not run |
| Operating temperature | 0 °C to +45 °C | Charge inhibited outside 0–45 °C | Not run |
| Surface temperature | Internal gate | ≤38 °C during fast charge | Not run |
| Salt fog | IEC 60068-2-11, 24 h | No corrosion on case or pogo | Not run |
| Vibration | IEC 60068-2-6 | No solder or connector failure | Not run |

The charge-temperature window is enforced by the BQ25619 JEITA profile [S10], not by the AP. That is deliberate: the charger must be safe even if Linux hangs.

## 8. Operating system and software

### 8.1 The stack

| Layer | Choice | Why |
|---|---|---|
| Bootloader | U-Boot from the Rockchip BSP | Vendor-supported boot path |
| Kernel | Rockchip BSP Linux, version UNKNOWN until fetched | RV1106 drivers |
| Root filesystem | Buildroot, read-only squashfs + writable overlay | Small, reproducible |
| Graphics | LVGL 9 on DRM/fbdev, 2D engine blit | No GPU; LVGL is CPU-friendly |
| Compositor | None; LVGL owns the display | One full-screen app at a time |
| Connectivity | ESP-Hosted + BlueZ or a minimal HCI daemon | C6 radio |
| Updates | A/B partitions, signed image, rollback | Must survive a failed OTA |

The "large OS" is a **custom Linux shell with 18 first-party system apps**, not an app platform. There is no third-party store, no Android runtime and no Flutter. That is the honest description and it should be used in marketing. Updates use an A/B rootfs with a signed image and rollback; secure boot is **UNKNOWN** until the BSP is read; factory provisioning writes a serial number and per-unit key over the pogo UART, and that station does not exist yet.

### 8.2 Why not Android and why not Flutter

- **Android** needs more RAM and storage than 256 MB / 4–8 GB provides comfortably, and it expects a GPU. It also brings Google licensing and a large attack surface.
- **Flutter** on Linux renders through OpenGL. The RV1106 has no GPU, so Flutter would fall back to software rendering or fail. LVGL is the correct toolkit.
- **LVGL 8.3.11** is what the ESP32 prototype uses. The new design moves to LVGL 9 for its DRM/fbdev backend and better font handling. The app and protocol work is not thrown away; the UI layer is ported.

### 8.3 System apps (18, first-party)

| # | App | Core function | Offline? |
|---:|---|---|---|
| 1 | Watchface | Time, date, complications, AOD | Yes |
| 2 | Notifications | Phone notifications over BLE | No |
| 3 | Activity | Steps, distance, calories | Yes |
| 4 | Heart rate | Spot and continuous wellness HR | Yes |
| 5 | Blood oxygen | Spot SpO₂, wellness only | Yes |
| 6 | Sleep | Sleep/wake estimate, stages | Yes |
| 7 | Workouts | Walk, run, cycle, timer, history | Yes |
| 8 | Weather | Forecast via phone or Wi-Fi | No |
| 9 | Alarms | Multiple alarms, snooze, wrist haptics | Yes |
| 10 | Timer | Countdown, multiple timers | Yes |
| 11 | Stopwatch | Lap timer | Yes |
| 12 | Calendar | Month view, agenda | Yes |
| 13 | Calculator | Basic and tip | Yes |
| 14 | World clock | Multiple cities and UTC offsets | Yes |
| 15 | Music control | Play/pause/next on the phone | No |
| 16 | Find phone | Ring the paired phone | No |
| 17 | Voice notes | Record and play on the watch | Yes |
| 18 | Settings | Display, language, sensors, privacy | Yes |

Deliberately absent: payments, cellular calling, an app store, maps, camera and medical diagnosis — each is a certification programme or a different product. A magnetic compass is also absent: the BOM has no magnetometer, and adding one is a sourcing and calibration task, not a software feature.

### 8.4 Arabic, English and right-to-left

The shell ships with **Arabic and English** at launch, with a language switch in Settings. LVGL 9 has bidi and Arabic/Persian shaping options; the exact build flags must be enabled and tested, not assumed. The font set needs Arabic glyphs (an OFL font such as Noto Naskh Arabic) and must be subsetted to the app's strings to fit the image. RTL affects the app grid, the back gesture, the notification layout and the numeric alignment. All four are acceptance tests, not a translation pass at the end.

A third language is a Phase 5 task. The 18 apps are designed so their strings are external, not hard-coded.

## 9. Unit economics

### 9.1 Retail decomposition

| Item | EGP | USD | Basis |
|---|---:|---:|---|
| Retail price | 7,500 | 137.64 | Fixed target |
| VAT at 14% (output tax) | 921 | 16.90 | [S32] |
| Revenue ex-VAT | 6,579 | 120.74 | Arithmetic |
| Payment gateway at 2.5% of ex-VAT | 164 | 3.02 | ASSUMPTION |
| Warranty reserve at 3% of ex-VAT | 197 | 3.62 | ASSUMPTION |
| Available for landed BOM and margin | 6,218 | 114.10 | Arithmetic |

The old spec put "taxes and payment fees" at 1,200 EGP as a cost. That is wrong for a VAT-registered seller: the 14% is collected from the customer and remitted, so it never belongs to the company. Only the gateway fee and the warranty reserve are costs. This correction moves about 1,000 EGP back into the model and is the reason the margin discussion below is possible at all.

### 9.2 BOM at 1,000 and 10,000 units

| # | Line | 1k USD | 10k USD | Basis | Source |
|---:|---|---:|---:|---|---|
| 1 | RV1106G3 | 22.6582 | 7.27 | LISTED @30 / 10k TARGET | [S3] |
| 2 | SPI NAND or eMMC | 5.00 | 3.50 | ALLOWANCE | — |
| 3 | ESP32-C6-MINI-1-N4 | 3.0419 | 2.80 | LISTED @100 / TARGET | [S5] |
| 4 | AXP313A | 0.4528 | 0.42 | LISTED @1k | [S9] |
| 5 | BQ25619 | 0.5906 | 0.55 | LISTED @1k | [S11] |
| 6 | BQ27427 | 0.9807 | 0.90 | LISTED @1k | [S13] |
| 7 | MAX30101 | 6.0888 | 4.50 | LISTED @100 / TARGET | [S14] |
| 8 | BMI270 | 1.4011 | 1.30 | LISTED @1k | [S16] |
| 9 | BMP581 | 1.5331 | 1.45 | LISTED @1k | [S18] |
| 10 | STTS22H | 1.3166 | 1.20 | LISTED @1k | [S19] |
| 11 | DRV2605L | 0.7630 | 0.70 | LISTED @1k | [S21] |
| 12 | LRA, MD-LRA371-H20 | 0.5289 | 0.50 | LISTED @1k | [S34] |
| 13 | MAX98357A | 0.3050 | 0.28 | LISTED @1k | [S27] |
| 14 | SPH0645 | 1.9625 | 1.80 | LISTED @100 | [S28] |
| 15 | 1.43″ 466×466 AMOLED + touch | 13.20 | 10.00 | LISTED range / TARGET | [S7] |
| 16 | 500 mAh cell | 7.95 | 4.00 | LISTED retail / TARGET | [S25] |
| 17 | 6-layer HDI PCB | 3.50 | 2.50 | ALLOWANCE | — |
| 18 | Passives, connectors, ESD | 3.00 | 2.50 | ALLOWANCE | — |
| 19 | Case, glass, gasket, strap | 9.00 | 7.00 | ALLOWANCE | — |
| 20 | Packaging, pogo cable, docs | 3.00 | 2.50 | ALLOWANCE | — |
| 21 | Assembly, test, calibration | 5.00 | 3.50 | ALLOWANCE | — |
| | **Total** | **91.27** | **59.17** | | |
| | *of which sourced* | *62.77* | *37.67* | | |
| | *of which allowance* | *28.50* | *21.50* | | |

The 1,000-unit column mixes a 30-piece SoC price with 100-piece sensor prices. It is therefore **conservative and not a quote**. The 10,000-unit column is a negotiation target; only the 1,000-unit prices are public listings.

### 9.3 Landed cost

Assumptions: freight 4% of goods, duty 30% of CIF, no broker fee, no bank fee. The 30% is the indicative rate for HS 9102 on a public customs reference [S33]; the classification of a smartwatch is **UNKNOWN** and must be confirmed by a broker.

| | 1,000 units | 10,000 units |
|---|---:|---:|
| Goods | $91.27 | $59.17 |
| Freight 4% | $3.65 | $2.37 |
| CIF | $94.92 | $61.54 |
| Duty 30% | $28.48 | $18.46 |
| **Landed** | **$123.40 / 6,724 EGP** | **$80.00 / 4,359 EGP** |
| Revenue ex-VAT | 6,579 EGP | 6,579 EGP |
| **Gross contribution** | **−145 EGP** | **2,220 EGP (29.6%)** |
| After gateway and warranty (5.5%) | −507 EGP | 1,858 EGP (24.8%) |

### 9.4 Duty and volume sensitivity

| Duty | 1k landed EGP | 1k contribution | 10k landed EGP | 10k contribution |
|---:|---:|---:|---:|---:|
| 0% | 5,172 | 1,045 (13.9%) | 3,353 | 2,864 (38.2%) |
| 5% | 5,431 | 786 (10.5%) | 3,521 | 2,696 (36.0%) |
| 10% | 5,689 | 528 (7.0%) | 3,688 | 2,529 (33.7%) |
| 20% | 6,207 | 11 (0.1%) | 4,024 | 2,193 (29.2%) |
| 30% | 6,724 | −507 (−6.8%) | 4,359 | 1,858 (24.8%) |

Contribution is after the 5.5% gateway and warranty reserve, as a percentage of the 7,500 retail price.

### 9.5 What the numbers say

1. **At 1,000 units the design is loss-making at 7,500 EGP** for any duty at or above about 20%. Even at 0% duty it contributes 1,045 EGP, which does not fund R&D, tooling or support.
2. **At 10,000 units and 30% duty it contributes 1,858 EGP per unit (24.8%)** before R&D, marketing and overhead. That is thin for a hardware startup but not impossible.
3. **To earn a 30% contribution after fees at 10,000 units, the retail price must be about 7,704 EGP.** At 1,000 units it must be about **11,884 EGP**. Those are arithmetic, not recommendations.
4. **The SoC is the problem.** At $22.66 it is 25% of the 1,000-unit BOM. A 1,000-piece quote below $12 is the single highest-value negotiation.
5. **The MAX30101 is the second problem** at $6.09. A watch-grade PPG at half that price would move the landed 1,000-unit contribution by about 224 EGP.
6. **The 7,500 EGP mission survives only if volume, duty and the SoC price all break favorably.** The honest alternative is Option A (ESP32-S3), which cannot host the requested OS but can hit the price.

## 10. Verification plan

Nothing below has been run. The plan exists so that "done" has a definition.

| Stage | # | Test | Method | Pass criterion |
|---|---|---|---|---|
| EVT | E1 | Rail sequencing | Scope on all rails, 10 power cycles | No rail before its prerequisite; no latch-up |
| EVT | E2 | Boot | Serial console, 100 cold boots | Linux reaches the shell 100/100 |
| EVT | E3 | I²C inventory | `i2cdetect` on every bus | Exactly the devices in §6.2, no extra |
| EVT | E4 | Display | Framebuffer pattern, 30 min | No dead pixels, no tearing at 30 fps |
| EVT | E5 | Touch | Grid tap test, 1,000 taps | 100% registration, zero ghosts |
| EVT | E6 | Suspend current | µA meter, AP suspended | ≤3 mA, target ≤2 mA |
| EVT | E7 | AP-off current | µA meter, AP gated, C6 deep sleep | ≤80 µA |
| EVT | E8 | Charge | 0→100%, thermal coupon | ≤38 °C surface, termination at 20 mA |
| EVT | E9 | Gauge | Discharge log vs coulomb count | ±3% SOC error |
| EVT | E10 | Radio | Wi-Fi throughput, BLE range | ≥10 Mbit/s, 10 m through a wall |
| DVT | D1 | Battery runtime | Scripted 24 h use profile | Matches §4.5 within ±15% |
| DVT | D2 | IP67 | IEC 60529, 1 m, 30 min | No ingress |
| DVT | D3 | Drop | 1.0 m, 6 faces, steel | No crack, no functional loss |
| DVT | D4 | Thermal shock | −20/+55 °C, 5 cycles | No seal or display failure |
| DVT | D5 | EMC pre-scan | Accredited lab | Margin ≥6 dB under RED/FCC limits |
| DVT | D6 | OTA | Power loss at 20/50/80% | Always boots a valid image |
| DVT | D7 | Soak | 72 h UI loop | No leak, no hang, no reboot |
| DVT | D8 | Audio | Speaker SPL, mic intelligibility | Alarm audible at 1 m, notes intelligible |
| DVT | D9 | Haptics | Accelerometer on the case | Perceptible at 50% duty |
| PVT | P1 | Line test | Fixture: rails, current, I²C, display, touch | <2% false fail |
| PVT | P2 | Calibration | PPG optical fixture, gauge | Within the DVT limits |
| PVT | P3 | RF | Conducted and radiated spot check | Within certification margin |
| PVT | P4 | Seal | 100% vacuum decay | No leak |
| PVT | P5 | Ageing | 24 h burn-in | <1% early failure |
| PVT | P6 | Yield | Full lot | Target **UNKNOWN** until the first lot |

EVT uses 5–10 boards, DVT 30–50, PVT 100–300. The gates that survive from the old spec are: **≤80 µA** (now scoped to the AP-off mode), **9-point touch**, **optical SNR**, **≤38 °C** and **IP67**. The "3–5 days" battery claim does not survive; the measured range is 1.0–2.9 days depending on mode.

## 11. Risks and how they are retired

| Risk | Impact | Retirement |
|---|---|---|
| RV1106 BSP is incomplete or unlicensed | Schedule stop | Download and build the BSP before schematic freeze |
| QSPI cannot reach 30 fps at 466×466 | UI feels slow | Measure on EVT; reduce colour depth or resolution |
| Linux suspend is >5 mA | Battery below 2 days | Measure E6; gate the AP harder, use C6 for more |
| 1,000-piece SoC price stays above $20 | Unit economics fail | Get three quotes before DVT |
| Panel MOQ or FPC is wrong | Tooling rework | Buy 20 samples and the panel datasheet first |
| Duty is 30% and HS 9102 applies | 1k loses money | Broker ruling before pricing decision |
| NTRA approval delays launch | Revenue delay | Start the file at EVT, not at PVT |
| Cell is not UN38.3 / IEC 62133 | Cannot ship | Qualify the cell before DVT |
| No GPU limits animation | Product feels cheap | Design a static, high-contrast UI; test with users |

## 12. Sources

All pages fetched on **2026-10-21**. Where an entry says "datasheet", the PDF was downloaded and read; where it says "price", the distributor listing was read for part number and price.

| ID | What it supports | URL |
|---|---|---|
| S1 | USD/EGP rate, 54.488856 | https://open.er-api.com/v6/latest/USD |
| S2 | RV1106 datasheet: A7 1.2 GHz, 2 Gb DDR3L, 5 I²C, CSI only, RGB LCD | https://www.rockchip.fr/RV1106%20datasheet%20V2.0.pdf |
| S3 | RV1106G3 price, C5328706 | https://www.lcsc.com/product-detail/C5328706.html |
| S4 | ESP32-C6 datasheet: Wi-Fi 6, BLE 5.3, 7 µA deep sleep | https://www.espressif.com/sites/default/files/documentation/esp32-c6_datasheet_en.pdf |
| S5 | ESP32-C6-MINI-1-N4 price, C5736265 | https://www.lcsc.com/product-detail/C5736265.html |
| S6 | Waveshare 1.43″ AMOLED module: 350 cd/m², CO5300, FT6146, QSPI | https://www.waveshare.com/esp32-c6-touch-amoled-1.43.htm |
| S7 | Tailor Pixels TOH143XRT-01CG2: 466×466, QSPI, $7.80–13.20 | https://tailorpixels.com/product/1-43-inch-amoled-display-on-cell-touch-466x466-mipi-qspi/ |
| S8 | CO5300 datasheet: Quad-SPI, watch application | http://admin.osptek.com/uploads/CO_5300_Datasheet_V0_00_20230328_07edb82936.pdf |
| S9 | AXP313A: 3 DCDC + 3 LDO, QFN-20, price | https://www.lcsc.com/product-detail/C5365290.html |
| S10 | BQ25619 datasheet: 1.5 A, NVDC, JEITA, 20 mA termination | https://www.ti.com/lit/ds/symlink/bq25619.pdf |
| S11 | BQ25619 price, C2864534 | https://www.lcsc.com/product-detail/C2864534.html |
| S12 | BQ27427 datasheet: 50 µA normal, 9 µA sleep | https://www.ti.com/lit/ds/symlink/bq27427.pdf |
| S13 | BQ27427 price, C6075475 | https://www.lcsc.com/product-detail/C6075475.html |
| S14 | MAX30101 price, C2859066 | https://www.lcsc.com/product-detail/C2859066.html |
| S15 | BMI270 datasheet: 685 µA | https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmi270-ds000.pdf |
| S16 | BMI270 price, C2836813 | https://www.lcsc.com/product-detail/C2836813.html |
| S17 | BMP581 datasheet | https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmp581-ds004.pdf |
| S18 | BMP581 price, C5362283 | https://www.lcsc.com/product-detail/C5362283.html |
| S19 | STTS22H price, C2969838 | https://www.lcsc.com/product-detail/C2969838.html |
| S20 | DRV2605L datasheet | https://www.ti.com/lit/ds/symlink/drv2605l.pdf |
| S21 | DRV2605L price, C527464 | https://www.lcsc.com/product-detail/C527464.html |
| S22 | ESP32-S3-WROOM-1-N16R8 price, C2913202 | https://www.lcsc.com/product-detail/C2913202.html |
| S23 | nRF5340 price, C3015611 | https://www.lcsc.com/product-detail/C3015611.html |
| S24 | STM32U575VGT6 price, C5270988 | https://www.lcsc.com/product-detail/C5270988.html |
| S25 | Adafruit 1578, 500 mAh 3.7 V LiPo, $7.95 | https://www.adafruit.com/product/1578 |
| S26 | ESP-Hosted, Wi-Fi/BLE over SDIO/UART | https://github.com/espressif/esp-hosted |
| S27 | MAX98357A price, C2682619 | https://www.lcsc.com/product-detail/C2682619.html |
| S28 | SPH0645 price, C45337831 | https://www.lcsc.com/product-detail/C45337831.html |
| S29 | ST25R3916B price, C5267436 | https://www.lcsc.com/product-detail/C5267436.html |
| S30 | NTRA type-approval service | https://www.tra.gov.eg/en/services/type-approval/ |
| S31 | TicWatch Pro 5: W5+ Gen 1, 2 GB/32 GB, Wear OS 3 | https://www.mobvoi.com/us/pages/ticwatchpro5 |
| S32 | Egyptian Tax Authority (VAT) | https://www.eta.gov.eg/en |
| S33 | Egypt import reference, HS 9102 | https://customs.educore.software/import/9102/ |
| S34 | LRA price, C50275770 | https://www.lcsc.com/product-detail/C50275770.html |

## 13. What this supersedes

| Document | Change |
|---|---|
| [11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md) | Its hardware sections are superseded by this document. The 7,500 EGP commercial target and the still-applicable acceptance gates remain. |
| [HARDWARE.md](HARDWARE.md) §7–§8 | Replaced by a link and a one-paragraph summary. §1–§6 and §9 remain the bench procedures. |
| [ROADMAP.md](ROADMAP.md) 4.5 | Split into 4.5a (this document, done), 4.5b (owner approval), 4.5c (EVT and measurements). 4.5 stays unchecked. |
| `firmware/esp32s3` | Unchanged. Its `I2C_NUM_2` bug is not fixed here; the new architecture removes the need for a third controller on the S3. |

**Do not order production parts from this document.** The only parts that may be ordered are EVT samples, and only after 4.5b. The prices are web prices, the allowances are guesses, and nothing has been measured.
