# Veyro production watch — commercial target

**Status: commercial target, hardware superseded (2026-10-21).** The hardware
proposal is now [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md). It selects the
architecture, sources every part and prices 1,000 and 10,000 units. This page
keeps the **7,500 EGP** commercial target and the acceptance gates, and records
what the old ESP32-S3 sketch assumed. Nothing here describes a built device: no
unit exists, no production part has been ordered, and no gate has been measured.

## 1. The mission

Stated 2026-10-21: a watch that competes on a shelf with the Apple Watch and its
peers at about **7,500 EGP**, with a touchscreen, a large custom operating
system with its own system apps, internet and Bluetooth, and features that serve
any age, language, interest and job.

The hardware decision is made in [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §1:
a **Linux application processor plus a companion MCU** (RV1106G3 + ESP32-C6).
The alternative — an RTOS on a microcontroller — is cheaper and smaller but
cannot host a multi-process OS. That trade-off is for the owner to approve under
ROADMAP 4.5b.

## 2. Unit economics at 7,500 EGP

VAT is **output tax**, not a cost. The seller collects 14% from the customer and
remits it, so it must be removed from revenue before any margin is calculated.
The earlier version of this page counted "taxes and payment fees" as a 1,200 EGP
cost, which double-counted VAT and understated the available margin.

| Item | EGP | USD | Basis |
|---|---:|---:|---|
| Retail price | 7,500 | 137.64 | Fixed target |
| VAT at 14% | 921 | 16.90 | Output tax, remitted |
| Revenue ex-VAT | 6,579 | 120.74 | Arithmetic |
| Payment gateway at 2.5% | 164 | 3.02 | Assumption |
| Warranty reserve at 3% | 197 | 3.62 | Assumption |
| Available for landed BOM and margin | 6,218 | 114.10 | Arithmetic |

The FX rate is 1 USD = 54.488856 EGP on 2026-10-21 (source S1 in
[HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §12).

The sourced BOM is **$91.27 at 1,000 units** and **$59.17 at 10,000** (a
negotiation target, not a quote). With 4% freight and 30% duty:

| | 1,000 units | 10,000 units |
|---|---:|---:|
| Landed BOM | 6,724 EGP | 4,359 EGP |
| Gross contribution | **−145 EGP** | **2,220 EGP (29.6%)** |
| After gateway and warranty | **−507 EGP** | **1,858 EGP (24.8%)** |
| Retail needed for 30% after fees | **11,884 EGP** | **7,704 EGP** |

The BOM, the duty sensitivity and the arithmetic are in
[HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §9. The 30% duty is an indicative rate
for HS 9102, not a ruling; the classification is **UNKNOWN**.

## 3. What the ESP32-S3 sketch assumed (historical)

This is what `firmware/esp32s3` is written against. It is kept so the firmware
is not mistaken for the production design. It is not a specification.

| Subsystem | Code assumption | Source |
|---|---|---|
| Compute | ESP32-S3-MINI-1U-N16R8, 16 MB flash, 8 MB PSRAM | `veyro_main.c:1-18` |
| Display | 360×360 round AMOLED over SPI, backlight GPIO 7 | `veyro_main.c:14`, `display.h:7-8` |
| Touch | FT6336G on I²C bus A, address `0x38` | `veyro_main.c:13, 93` |
| Vitals | VC31B wrist PPG, address `0x33` | `veyro_main.c:7, 87` |
| Motion | QMI6858C per the code comment; the BOM says QMI8658CULT — **UNKNOWN which** | `veyro_main.c:8` |
| Environment | BMP581 `0x47`, STTS22H `0x3C` | `veyro_main.c:9-10` |
| Haptics | DRV2605L `0x5A` | `veyro_main.c:11` |
| Power | BQ25895 `0x6B`, NTC on GPIO 14 | `veyro_main.c:12, 75` |
| Radio | BLE only in code; no Wi-Fi application code | `veyro_main.c` |
| OS | ESP-IDF + FreeRTOS + LVGL **8.3.11** | `firmware/esp32s3/platformio.ini` |

The S3 declares three I²C buses but has two controllers (`I2C_NUM_2` cannot
work). The production design does not patch this: the RV1106 has five I²C
masters and the IMU moves to the companion MCU, so the third bus disappears
([HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §6.2). Do not flash the S3 image until
ROADMAP 4.4 is resumed on a decided target.

## 4. Industrial design (targets, not built)

The production targets are in [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §7:
46 mm case, ≤12.5 mm thick, aluminium or steel bezel, 2.5D glass, optical
polycarbonate rear window, 20 mm quick-release strap, 4-pad magnetic pogo.
The stack-up is an arithmetic budget, not a measurement.

**IP67 is the ingress target. 3 ATM is not claimed and swimming is not
supported.**

## 5. Software targets

The production stack is **Buildroot Linux + LVGL 9**, not FreeRTOS and not
LVGL 8. The system apps, the Arabic/English requirement and the update model are
in [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §8. The wire protocol and the app
remain as described in [SYSTEM.md](SYSTEM.md); a protocol v2 is still not
implemented on either side.

## 6. Acceptance gates

Every unit at this price would have to pass these before packaging. None has
been measured. The sleep gate is now scoped to the mode where the application
processor is power-gated off; Linux cannot suspend at 80 µA.

| # | Gate | Scope | State |
|---:|---|---|---|
| 1 | **≤80 µA** total | AP power-gated off, C6 deep sleep, IMU low-power, gauge sleeping | MUST MEASURE |
| 2 | **≤3 mA** suspend | Linux suspended, RAM retained, C6 connected | MUST MEASURE; target is 2 mA |
| 3 | **9-point touch**, zero ghosts | Production panel and touch controller | MUST MEASURE |
| 4 | **Optical SNR** on green and IR | PPG fixture, skin phantom | MUST MEASURE |
| 5 | **≤38 °C** case surface | Fast charge, 25 °C ambient | MUST MEASURE |
| 6 | **IP67** | IEC 60529, 1 m, 30 min | MUST MEASURE |

The prototype cannot be measured against any of them: it has no production
panel, no sealed case, no optical fixture and no AP-off mode.

## 7. What is still open

The live list is [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) §1.4 and §11. In
summary: the 1,000-piece SoC price, the production cell, the panel MOQ, the
duty classification, NTRA fees, the enclosure supplier and the factory fixture
are all **UNKNOWN**. None of them may appear in marketing as a specification.

The 7,500 EGP price is fixed by the mission, but the arithmetic in §2 says it
does not produce a viable margin at 1,000 units. The owner has three honest
choices: approve a higher price, approve Option A (RTOS, no Linux) at a lower
BOM, or commit to 10,000 units. This page does not choose for them.
