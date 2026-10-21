# Veyro production watch — commercial target

**Status: under redesign (ROADMAP 4.5).** This is the input to that work, not a
settled design and not a description of anything built. No unit exists, no part
below has been ordered for production, and no acceptance gate has been measured.
Where this page and `firmware/` disagree, the firmware describes what the code
currently assumes; neither is a final decision.

## 1. The mission

Stated 2026-10-21: a watch that competes on a shelf with the Apple Watch and its
peers at about **7,500 EGP**, with a touchscreen, a large custom operating system
with its own system apps, internet and Bluetooth, and features that serve any
age, language, interest and job.

That mission is broader than the ESP32-S3 sketch in `firmware/esp32s3`. The
redesign therefore has to decide explicitly:

1. Whether the OS needs a Linux-class application processor with a companion MCU
   for radios, sensors and power, or whether an RTOS on a microcontroller can
   meet it.
2. Wi-Fi and BLE, or cellular.
3. Display technology, size and touch controller.
4. Battery, thermal and water-resistance budget.
5. The BOM at the target price.

Every part chosen must carry its source and its price. Every capability must
name the part that provides it. Anything that cannot be sourced is marked
UNKNOWN.

## 2. Unit economics at 7,500 EGP

The price is fixed as the planning target. The allocations are internal targets,
not quotes.

| Cost element | EGP | % of retail | Basis |
|---|---:|---:|---|
| Electronics BOM (PCBA) | 1,850 | 24.7% | Module, display, PMIC, sensors, passives, 4-layer PCB |
| Enclosure and glass | 450 | 6.0% | CNC aluminium chassis, 2.5D glass, gasket |
| Strap and charger | 300 | 4.0% | Quick-release band, 2-pin magnetic pogo cable |
| Assembly, calibration, yield | 400 | 5.3% | Optical calibration, leak test, 5% scrap reserve |
| Packaging and documentation | 200 | 2.7% | Box, insert, compliance guide |
| Taxes and payment fees | 1,200 | 16.0% | 14% VAT plus ~2% gateway |
| Warranty and support reserve | 300 | 4.0% | One-year limited hardware warranty |
| Net gross profit | 2,800 | 37.3% | R&D and operating reserve |
| **Retail** | **7,500** | **100.0%** | |

The previous version of this table listed 3,000 EGP (40.0%) profit and a 7,500
total, but its rows summed to 7,700 (102.7%). Profit is the balancing line here;
the other allocations are unchanged. Correcting it reduces the profit target,
which is the honest direction: the price is fixed, so an arithmetic error cannot
be paid for by raising it.

The previous production BOM recorded $28–46 per unit at 1,000 pieces, before
enclosure, assembly, tax and warranty. At the September 2026 planning rate of
about 50 EGP/USD that is roughly 1,400–2,300 EGP. The 1,850 EGP PCBA allocation
is about $37, so the BOM fits only if it lands below that. That is arithmetic on
carried-over numbers, not a current quote. See [HARDWARE.md](HARDWARE.md) §8.

## 3. What the current code assumes

This column is what `firmware/esp32s3` is written against. It is a sketch, not a
decision; Phase 4.5 may replace all of it.

| Subsystem | Code assumption | Source |
|---|---|---|
| Compute | ESP32-S3-MINI-1U-N16R8, 16 MB flash, 8 MB PSRAM | `veyro_main.c:1-18` |
| Display | 360×360 round AMOLED over SPI, backlight GPIO 7 | `veyro_main.c:14`, `display.h:7-8` |
| Touch | FT6336G on I²C bus A, address `0x38` | `veyro_main.c:13, 93` |
| Vitals | VC31B wrist PPG, address `0x33` | `veyro_main.c:7, 87` |
| Motion | QMI6858C per the code comment; the BOM says QMI8658CULT — **UNKNOWN which** | `veyro_main.c:8` |
| Environment | BMP581 `0x47`, STTS22H `0x3C` | `veyro_main.c:9-10` |
| Haptics | DRV2605L `0x5A` | `veyro_main.c:11` |
| Power | BQ25895 PMIC `0x6B`, NTC on GPIO 14 | `veyro_main.c:12, 75` |
| Radio | BLE only in code; no Wi-Fi application code | `veyro_main.c` includes Wi-Fi headers but no service |
| OS | ESP-IDF + FreeRTOS + LVGL **8.3.11** | `firmware/esp32s3/platformio.ini` |

Four parts of the previous specification are wrong against this code and are
corrected here: the module is **N16R8**, not N8R8; the graphics library is
**LVGL 8.3.11**, not 9.x; the PPG the code expects is **VC31B**, not
MAX30101/GH3011; and the prototype charger is an **MCP73831-class board with
load sharing**, not a bare TP4056.

## 4. Industrial design (target, not built)

These are targets for the redesign. No case, seal or strap exists.

1. **Chassis:** sandblasted 6000-series aluminium bezel and rim.
2. **Crystal:** chemically strengthened 2.5D curved glass, oleophobic coating.
3. **Rear pod:** optical-grade polycarbonate window, flush to the skin.
4. **Sealing:** silicone compression gasket, **designed for** IP67 / 3 ATM.
5. **Strap:** 20 mm quick-release spring bars.

IP67 is a design goal. The acceptance test in §6 is how it would be proven; it
has not been run.

## 5. Software targets

1. **UI:** LVGL 8.3.11 on FreeRTOS, double-buffered DMA over SPI, partial
   refresh. The five watch-face IDs and six theme IDs in `display.h` are the
   intended set; their switching functions are stubs today.
2. **Storage:** 60-day circular history of one-minute epochs. The prototype
   already does this on LittleFS; the S3 target uses SPIFFS.
3. **Protocol:** the wire format is v1 today. A future v2 would need an MTU
   negotiation and an OTA client; neither exists on either side. The app's
   `version = 2` constant is unused and must not be read as an implemented v2.
4. **OTA:** the partition table provides `ota_0` and `ota_1` at 4 MB each, and
   nothing writes to them. Cryptographic verification and rollback are targets,
   not features.

## 6. Production acceptance gates (targets)

Every unit at this price would have to pass these before packaging. None has
been measured; the numbers are the specification the redesign must meet.

1. **Sleep current:** under 80 µA with the display off and motion wake armed.
2. **Touch:** 9-point capacitive verification with zero ghost touches.
3. **Optical SNR:** green/IR signal-to-noise verified on an optical fixture.
4. **Thermal:** case surface at or below 38 °C during fast charging.
5. **Seal:** vacuum decay test confirming IP67 gasket integrity.

The prototype cannot be measured against any of them: it has no sleep mode, no
touch panel, no sealed case and no production optical path.

Provisioning steps from the old production manual — flash-station commands,
writing a serial number to NVS, and setting the PMIC ship mode — are **not**
carried into this document. They target a board that Phase 4.5 may replace, and
several depend on register values that were never verified on hardware. They
belong with the new design, after the part is chosen.

## 7. What is explicitly open

| Question | State |
|---|---|
| Application processor class | UNKNOWN — the central 4.5 decision |
| Cellular vs Wi-Fi/BLE | UNKNOWN |
| Final display panel and driver | UNKNOWN; code assumes 360×360 AMOLED |
| Battery capacity and runtime | UNKNOWN; “3–5 days” was a target with no test |
| Water resistance | UNKNOWN; IP67 is a design goal |
| Final BOM and unit cost | UNKNOWN; carried-over ranges are stale |
| Manufacturing partner and test fixtures | UNKNOWN |
| Regulatory certification path | UNKNOWN |

Anything in this table must not appear in marketing or a product page as a
specification until it has a source and a measurement.
