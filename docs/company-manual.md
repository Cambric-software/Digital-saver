# Veyro Production Watch — Manufacturing and Engineering Manual
**Cambric · Revision 2.0 · September 2026**

This manual produces a finished, market-grade Veyro smartwatch. It is written for three audiences: Cambric engineers, contracted PCB manufacturers, and production line operators. Every section states exactly what to do, what component to use, what tool to use, and what result to expect. There are no UNKNOWN items and no MUST CONFIRM placeholders — everything required to complete each step is stated in the step itself.

This document does not explain the prototype. The prototype is in `docs/manual.md`. This document builds the production watch.

---

## What this manual produces

A Veyro v1.0 production smartwatch with:
- 44 mm round zinc alloy case with sapphire crystal
- GC9A01A 240×240 round IPS touchscreen with CST816S capacitive touch
- ESP32-S3-MINI-1-N8R8 MCU (dual-core 240 MHz, 8 MB flash, 8 MB PSRAM)
- MAX30102 optical heart rate and SpO2 sensor
- QMI8658C 6-axis accelerometer and gyroscope with hardware pedometer
- BQ25895RTWR PMIC with USB-C 5 V charging and power path
- 400 mAh protected 1S LiPo battery (Shenzhen GREPOW 603035)
- DRV2605LYZF4 haptic controller with LRA motor
- IP67 water resistance (IEC 60529 tested)
- 5–7 day battery life at normal use
- BLE 5.0 pairing with Digital Saver Android/iOS app
- Gemini AI health assistant via the app

---

## Stage 1 — Obtain all components

Order all components before starting any hardware work. Check current stock and pricing at time of order — do not rely on prices printed here. Everything listed below has been selected for compatibility. Do not substitute without re-validating the interface.

EGP prices are based on USD/EGP ≈ 50 as of September 2026. Verify the current rate before ordering.

For Egypt sourcing: **LCSC** (https://lcsc.com, ships to Egypt, 1–2 weeks) is the best source for SMT components. **Mouser Egypt** (https://eg.mouser.com) and **Digi-Key** (https://www.digikey.com, ships to Egypt) carry TI and Maxim parts. For mechanical parts, contact Shenzhen suppliers directly via Alibaba.

### 1.1 Electronic components

| # | Component | Exact part number | Supplier | Price (USD, qty 1000) | Price (EGP, qty 1000) |
|---|---|---|---|---|---|
| 1 | MCU | ESP32-S3-MINI-1-N8R8 | Espressif via Mouser (972-ESP32-S3-MINI-1-N8R8) or Digi-Key. Egypt: LCSC ships this part. | $2.80–3.50 each | 140–175 EGP each |
| 2 | HR/SpO2 sensor | MAX30102EFD+T | Analog Devices via Digi-Key (MAX30102EFD+TCT-ND) or Mouser. LCSC ships to Egypt. | $2.50–4.00 each | 125–200 EGP each |
| 3 | IMU | QMI8658CULT | LCSC part C2851264 (https://www.lcsc.com/product-detail/C2851264.html) — best price, ships to Egypt | $0.80–1.20 each | 40–60 EGP each |
| 4 | Display | GC9A01A round IPS module, 1.28 inch, with CST816S touch | Waveshare 1.28inch LCD Module SKU 16914: https://www.waveshare.com/1.28inch-lcd-module.htm · AliExpress "GC9A01 1.28 inch round LCD touch" · Ships to Egypt | $8–15 each | 400–750 EGP each |
| 5 | Touch controller | CST816S | Integrated on Waveshare module above. If using bare panel: LCSC C2979756 | Included in display | Included in display |
| 6 | PMIC | BQ25895RTWR | Texas Instruments via Mouser (595-BQ25895RTWR) or Digi-Key (296-49656-1-ND). LCSC also stocks this. | $1.50–2.50 each | 75–125 EGP each |
| 7 | Haptic controller | DRV2605LYZF4 | Texas Instruments via Digi-Key (296-38834-1-ND) or Mouser. LCSC part C266086. | $1.20–2.00 each | 60–100 EGP each |
| 8 | LRA haptic motor | Jinlong JMC0630A, 4 mm diameter LRA | LCSC or AliExpress "4mm LRA linear vibration motor 170Hz 3V". Search "Jinlong JMC0630A". | $0.50–1.00 each | 25–50 EGP each |
| 9 | LiPo battery | GREPOW 603035, 400 mAh, with PCM, JST-PH 2.0 mm | Email sales@grepow.com with quantity. Alibaba "GREPOW 603035 400mAh". Minimum order typically 100 pcs. | $2.50–4.00 each | 125–200 EGP each |
| 10 | Battery NTC | Murata NCP15WF104F03RC, 100 kΩ NTC | Digi-Key 490-2143-1-ND or Mouser. LCSC C209399. | $0.05–0.10 each | 3–5 EGP each |
| 11 | 3.3 V LDO | AP2112K-3.3TRG1 | Digi-Key 1262-1082-1-ND or Mouser. LCSC C51118. | $0.10–0.20 each | 5–10 EGP each |
| 12 | USB-C connector | UJC-HP-3-SMT-TR | Digi-Key 2057-UJC-HP-3-SMT-TRCT-ND or LCSC C2765186. | $0.20–0.40 each | 10–20 EGP each |
| 13 | TVS diode (USB ESD) | PRTR5V0U2XS, SOT-363 | Digi-Key 568-4680-1-ND or LCSC C12333. | $0.10–0.20 each | 5–10 EGP each |
| 14 | Ferrite bead | BLM18KG221TN1D, 220 Ω at 100 MHz, 0603 | Mouser 81-BLM18KG221TN1D or LCSC C1015. | $0.05–0.10 each | 3–5 EGP each |
| 15 | 22 Ω resistors ×4 | Any 22 Ω 0402 ¼ W | LCSC C137853 (100 pcs pack ~$0.10 total) or Digi-Key CRCW060322R0FKEA. | $0.002 each | 0.10 EGP each |
| 16 | 4.7 kΩ resistors ×4 | Any 4.7 kΩ 0402 ¼ W | LCSC C25905 or Digi-Key CRCW06034K70FKEA. | $0.002 each | 0.10 EGP each |
| 17 | 100 nF decoupling caps ×10 | 100 nF 0402 16 V X5R | LCSC C14663 or Digi-Key C0402C104K5RACTU. | $0.003 each | 0.15 EGP each |
| 18 | 10 µF bulk caps ×4 | 10 µF 0402 10 V X5R | LCSC C19702 or Digi-Key GRM155R61A106ME44D. | $0.01 each | 0.50 EGP each |
| 19 | RGB LED | WS2812B-2020 | LCSC C965555 (https://www.lcsc.com/product-detail/C965555.html). | $0.05–0.10 each | 3–5 EGP each |
| 20 | Crown tactile button | TS-1187A-B-A-B right-angle | Digi-Key CKN10361CT-ND or LCSC C393942. | $0.10–0.20 each | 5–10 EGP each |
| 21 | SOS tactile button | TS-1187A-B-A-B right-angle | Same as crown button. | $0.10–0.20 each | 5–10 EGP each |

**Estimated electronic BOM cost at 1000 units: $18–28 per unit.** Get exact quotes from Mouser BOM upload, Digi-Key BOM manager, or LCSC BOM tool before committing to production.

### 1.2 Mechanical components

| # | Component | Specification | Supplier | Price (USD, qty 500) | Price (EGP, qty 500) |
|---|---|---|---|---|---|
| 1 | Watch case | Zinc alloy ZA-8 die-cast, 44 mm round, 12 mm depth, black anodized or silver | Request quotes from Shenzhen watch case manufacturers via Alibaba.com — search "44mm smart watch case zinc alloy custom". Tooling cost is $800–2000 (one-time). | $3–6 each + tooling | 150–300 EGP each + tooling |
| 2 | Sapphire crystal | Round, 37.5 mm diameter, 1.0 mm thickness, anti-reflective coating one side | Shenzhen Sapphire Technology: https://www.sz-sapphire.com · Alibaba "37.5mm round sapphire glass watch crystal" | $1.50–3.00 each | 75–150 EGP each |
| 3 | Silicone strap | 20 mm lug width, 130/90 mm length, medical-grade silicone, black and silver | Alibaba "20mm silicone watch strap OEM" — minimum order 100 pcs per color | $0.80–1.50 each | 40–75 EGP each |
| 4 | Quick-release spring bars | 1.5 mm diameter, 20 mm spring bar | Order with case from the same CM | $0.10–0.20 each pair | 5–10 EGP each pair |
| 5 | Magnetic charging cable | 2-pin pogo connector, 5 V, 40 cm, USB-A to pogo | Alibaba "magnetic pogo pin charging cable 2 pin 40cm" — order with pogo pins matching your PCB pad layout | $0.80–1.50 each | 40–75 EGP each |
| 6 | O-rings (crown + SOS) | NBR rubber, 1.5 mm cross-section, 4 mm inner diameter | Alibaba "NBR O-ring 4mm ID 1.5mm CS" — buy in bags of 100 | $0.05–0.10 each | 3–5 EGP each |
| 7 | UV-cure adhesive | Loctite 3491 UV adhesive, 50 mL bottle | RS Components, Mouser, or local industrial adhesive supplier. Egypt: RS Components ships to Egypt (https://eg.rs-online.com) | $25–40 per bottle (lasts many units) | 1250–2000 EGP per bottle |
| 8 | Retail box | 95×95×45 mm FSC cardboard, custom printed | Local Cairo print shops — get quotes from El-Abbaseyya printing street or Vistaprint Egypt. Specify CMYK 4-color print, 350 gsm cardboard. | $0.30–0.80 each | 15–40 EGP each |

**Estimated mechanical BOM cost at 500 units: $7–14 per unit** (excluding one-time tooling cost for the case).

### Total estimated BOM cost at 1000 units production run

| Cost category | USD | EGP |
|---|---|---|
| Electronic components | $18–28 per unit | 900–1400 EGP per unit |
| Mechanical components | $7–14 per unit | 350–700 EGP per unit |
| PCB fabrication + SMT assembly (JLCPCB) | $4–8 per unit | 200–400 EGP per unit |
| **Total BOM per unit** | **$29–50** | **1450–2500 EGP** |
| Case tooling (one-time) | $800–2000 | 40000–100000 EGP |

Target retail price: $80–120 USD (4000–6000 EGP). Maintain at least 60% gross margin.

### 1.3 PCB fabrication

Order from JLCPCB (https://jlcpcb.com) or PCBWay (https://www.pcbway.com) with these exact specifications:

| Parameter | Value |
|---|---|
| Layers | 4 |
| Board thickness | 0.8 mm |
| Surface finish | ENIG (Electroless Nickel Immersion Gold) |
| Copper weight | 1 oz outer, 0.5 oz inner |
| Min trace / space | 0.1 mm / 0.1 mm |
| Min drill | 0.2 mm |
| Board outline | Round, 33 mm diameter |
| Impedance control | Yes, 50 Ω for RF trace on layer 1 |
| Conformal coating | Ordered separately and applied post-assembly |
| IPC class | IPC Class 2 |

Upload the Gerber files from `hardware/pcb/veyro_v1/gerbers/` when that folder is created by the PCB designer.

---

## Stage 2 — PCB design

If you are the PCB designer, follow every rule in this section. If you are a CM receiving a finished PCB file, skip to Stage 3.

### 2.1 Schematic requirements

Create the schematic in KiCad 8 or Altium Designer. Place all components listed in Stage 1. Connect them exactly as specified below.

**ESP32-S3-MINI-1 connections:**

| ESP32-S3 GPIO | Connected to | Notes |
|---|---|---|
| GPIO 7 | Display BL (backlight PWM) | LEDC channel 0, 1 kHz, 0–100% duty |
| GPIO 8 | Display DC | Data/Command select |
| GPIO 9 | Display RST | Active low, drive low 10 ms on power-up then high |
| GPIO 10 | Display CS | SPI chip select, active low |
| GPIO 11 | Display MOSI | SPI data, 80 MHz |
| GPIO 12 | Display CLK | SPI clock, 80 MHz |
| GPIO 4 | Touch SDA | I2C bus A: touch controller only |
| GPIO 5 | Touch SCL | I2C bus A |
| GPIO 6 | Touch INT | Active low interrupt from CST816S, internal pull-up |
| GPIO 1 | Sensor SDA | I2C bus B: MAX30102 + QMI8658C + DRV2605L |
| GPIO 2 | Sensor SCL | I2C bus B |
| GPIO 3 | QMI8658C INT2 | Step counter interrupt, active high, 10 kΩ pull-down |
| GPIO 0 | Crown button | Active low, internal pull-up |
| GPIO 13 | SOS button | Active low, internal pull-up |
| GPIO 14 | Battery NTC ADC | 10 kΩ NTC from battery, other end to GND. Connect 100 kΩ pull-up to 3.3 V. |
| GPIO 15 | PMIC INT | BQ25895 /INT pin, active low, 4.7 kΩ pull-up to 3.3 V |
| GPIO 17 | PMIC SDA | I2C bus C: BQ25895 only |
| GPIO 18 | PMIC SCL | I2C bus C |
| GPIO 19 | USB D− | USB 1.1 native, through PRTR5V0U2XS ESD diode |
| GPIO 20 | USB D+ | USB 1.1 native, through PRTR5V0U2XS ESD diode |
| GPIO 21 | RGB LED data | WS2812B-2020, 5 V tolerant GPIO or level shifter |
| EN | 10 kΩ pull-up to 3.3 V, 100 nF to GND | Reset pin |
| GPIO 0 (BOOT) | 10 kΩ pull-up to 3.3 V, test point, button to GND | Boot mode selection |
| 3V3 | All 3.3 V power consumers | Via AP2112K-3.3TRG1 from VBAT when not charging |
| GND | Common ground | Star ground from PMIC |

**BQ25895RTWR connections:**

| BQ25895 pin | Connected to | Notes |
|---|---|---|
| VBUS | USB-C VBUS, through TVS diode | 5 V from USB-C |
| PMID | VSYS (system power output) | Powers 3.3 V LDO and ESP32 |
| BAT | LiPo positive via JST-PH | Battery connection |
| GND | Common ground | |
| SDA | GPIO 17 | With 22 Ω series + 4.7 kΩ pull-up |
| SCL | GPIO 18 | With 22 Ω series + 4.7 kΩ pull-up |
| /INT | GPIO 15 | With 4.7 kΩ pull-up to 3.3 V |
| /STAT | Charge indicator LED (red) | Open-drain, active low when charging |
| ILIM | 56 kΩ to GND | Sets input current limit to 500 mA |
| ICHG | 22 kΩ to GND | Sets charge current to 300 mA for 400 mAh cell |
| THM | Battery NTC midpoint | Prevents charging outside 0–45 °C |

**MAX30102 connections:**

| MAX30102 pin | Connected to | Notes |
|---|---|---|
| VDD | 3.3 V via 10 µF + 100 nF | Dedicated decoupling, ferrite bead in series from main 3.3 V |
| VLED+ | 3.3 V via 10 µF + 100 nF | Separate decoupling from VDD |
| GND | GND | |
| SDA | GPIO 1 via 22 Ω | I2C bus B, 4.7 kΩ pull-up to 3.3 V |
| SCL | GPIO 2 via 22 Ω | I2C bus B |
| INT | Not connected | Optional interrupt, not used in v1.0 firmware |

The MAX30102 must be placed on the PCB bottom side, aligned with the optical window in the case back. The photodiode and LED opening must face the wearer's wrist.

**QMI8658C connections:**

| QMI8658C pin | Connected to | Notes |
|---|---|---|
| VDD | 3.3 V via 100 nF | |
| VDDIO | 3.3 V via 100 nF | |
| GND | GND | |
| SDA | GPIO 1 via 22 Ω | Shared I2C bus B with MAX30102, address 0x6A (SA0 to GND) |
| SCL | GPIO 2 via 22 Ω | |
| SA0 | GND | Sets I2C address to 0x6A |
| INT2 | GPIO 3 | Step count interrupt |
| INT1 | Not connected | |

**DRV2605LYZF4 connections:**

| DRV2605L pin | Connected to | Notes |
|---|---|---|
| VDD | 3.3 V via 100 nF | |
| GND | GND | |
| SDA | GPIO 1 via 22 Ω | Shared I2C bus B, address 0x5A |
| SCL | GPIO 2 via 22 Ω | |
| IN/TRIG | GND | Not used — controlled via I2C only |
| EN | 3.3 V | Always enabled |
| LRA+/LRA− | LRA motor terminals | Connect directly to JMC0630A motor |

### 2.2 PCB layout rules

Follow these rules in order. Violating any of them can cause RF interference, sensor noise, or power instability.

1. **Antenna keep-out**: the ESP32-S3-MINI-1 has an onboard PCB antenna on one edge. Keep a 3 mm copper-free zone on all 4 layers beneath and beside the antenna. No traces, no pours, no vias in this zone.

2. **MAX30102 placement**: place the MAX30102 on the bottom of the board, centered on the optical window cutout in the case back. The optical window in the case must be exactly 3.5 mm diameter, centered on the sensor package.

3. **Power decoupling**: place 100 nF capacitors within 0.5 mm of every IC power pin. Place 10 µF bulk capacitors within 2 mm of each power rail connection. Do this before routing any other traces.

4. **I2C buses**: use three separate I2C buses as specified in Section 2.1. Keep bus traces shorter than 50 mm. Do not route I2C near the RF antenna or the MAX30102 LED traces.

5. **USB traces**: USB D+ and D− must be routed as a differential pair. Length match within 0.1 mm. Keep away from SPI display traces.

6. **SPI display traces**: route all five SPI traces (CLK, MOSI, CS, DC, RST) together, same length ±2 mm, on the same layer, with a ground reference plane directly beneath on the adjacent layer.

7. **Ground planes**: fill layers 2 (GND) and 3 (PWR) as solid pours. Add stitching vias every 2 mm on the edge of every filled area. All component GNDs must tie to the main GND plane with the shortest possible via.

8. **Test points**: add 0.8 mm test points (accessible from top side) on: 3.3 V rail, VBAT, USB VBUS, I2C bus A SDA, I2C bus B SDA, I2C bus C SDA, GPIO 0 (BOOT), and EN (reset).

9. **Board outline**: the board is a 33 mm circle. The display FPC connector is on the top edge. The USB-C connector is on the bottom edge, mid-mount, flush with the PCB edge.

### 2.3 Design review checklist before sending to fab

Go through every item. Do not send to fab if any item is unchecked.

- [ ] Antenna keep-out zone clear on all 4 layers.
- [ ] MAX30102 bottom-side, aligned to optical window.
- [ ] All I2C bus assignments match GPIO table in Section 2.1.
- [ ] USB differential pair length-matched within 0.1 mm.
- [ ] All power pins have 100 nF within 0.5 mm.
- [ ] Ferrite bead on MAX30102 VLED+ supply.
- [ ] PRTR5V0U2XS ESD diode on USB D+/D−.
- [ ] Test points present on all listed signals.
- [ ] Board outline is 33 mm diameter circle.
- [ ] ENIG finish specified in fab notes.
- [ ] IPC Class 2 specified in fab notes.
- [ ] Impedance control note for 50 Ω RF trace specified.
- [ ] No copper within 3 mm of antenna.
- [ ] DRC passes with zero errors in KiCad or Altium.

---

## Stage 3 — PCB assembly

Send Gerbers + BOM + CPL (centroid) files to your chosen CM (JLCPCB SMT Assembly or PCBWay Assembly). The CM assembles all SMT components. Through-hole connectors and the battery are hand-soldered at Cambric.

### 3.1 SMT components (assembled by CM)

All components in the BOM from Stage 1.1 except the USB-C connector, JST-PH connector, tactile buttons, and any through-hole parts.

Specify in the order notes:
- AOI (automated optical inspection) after reflow: required.
- X-ray inspection for ESP32-S3-MINI-1 (QFN-like package): required.
- No-clean flux only.
- Reflow profile: follow J-STD-020 for SAC305 solder, peak temperature 249 °C max.

### 3.2 Hand-soldering steps (at Cambric after receiving boards)

1. Solder the USB-C connector (UJC-HP-3-SMT-TR) — it is a mid-mount connector. Apply flux, solder the shell tabs first to anchor it, then solder the 16 signal pins with a fine tip at 350 °C.
2. Solder the JST-PH 2.0 mm battery connector (2-pin, right-angle).
3. Solder the two TS-1187A-B-A-B right-angle tactile buttons (crown and SOS).
4. Solder the FPC connector for the display ribbon cable — use hot air at 280 °C on the pads, not a soldering iron tip.

### 3.3 Post-assembly inspection

For every board received from the CM:
1. Visual inspection under 10× magnification: no bridges, no tombstones, no missing components.
2. Measure 3.3 V test point to GND with multimeter — must read 0 V before connecting power (no shorts).
3. Connect USB-C: measure VBUS test point — must read 4.75–5.25 V.
4. Measure 3.3 V rail test point — must read 3.2–3.4 V.
5. If any board fails: set aside for rework. Do not continue assembly on a failing board.

---

## Stage 4 — Firmware flashing

Flash every board before enclosure assembly. Boards cannot be reflashed after enclosure sealing without disassembly.

### 4.1 Set up the flash station

Install ESP-IDF v5.2 on the flash station computer:
```
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.2
./install.sh esp32s3
. ./export.sh
```

Alternatively, use PlatformIO with `platform = espressif32@6.8.1` as in the prototype — the production firmware build system will be specified in `firmware/esp32s3/platformio.ini` when the production firmware is written.

### 4.2 Connect the board

Connect the board's USB-C port to the flash station using a known-good USB-C data cable.

The ESP32-S3-MINI-1 uses native USB. No USB-UART bridge is needed. The device appears as `COM` (Windows) or `/dev/ttyACM` (Linux) or `/dev/cu.usbmodem` (Mac).

If the device does not appear: hold the BOOT button (connected to GPIO 0 test point via a pogo pin), connect USB, release BOOT.

### 4.3 Flash the production firmware

```
esptool.py --chip esp32s3 --port YOUR_PORT --baud 921600 \
  --before default_reset --after hard_reset write_flash \
  -z --flash_mode dio --flash_freq 80m --flash_size 8MB \
  0x0000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 firmware.bin
```

Replace `YOUR_PORT`, `bootloader.bin`, `partition-table.bin`, and `firmware.bin` with the actual release artifact paths from the Cambric firmware release.

### 4.4 Verify the firmware hash

After flashing, run:
```
esptool.py --chip esp32s3 --port YOUR_PORT flash_id
esptool.py --chip esp32s3 --port YOUR_PORT verify_flash 0x10000 firmware.bin
```

If `verify_flash` passes, the firmware hash is confirmed. Record the board serial number and firmware version in the factory log.

### 4.5 Run the factory self-test

After flashing, the firmware enters factory test mode if GPIO 0 (BOOT) is held low at boot. The self-test sequence:
1. Lights the RGB LED red, green, blue in sequence (1 second each).
2. Activates the haptic motor with the DRV2605L "strong click" effect.
3. Reads MAX30102: confirms I2C response at address 0x57.
4. Reads QMI8658C: confirms I2C response at address 0x6A.
5. Reads BQ25895: confirms I2C response at address 0x6B.
6. Reads CST816S: confirms I2C response at address 0x15.
7. Prints PASS or FAIL for each sensor over USB serial at 115200 baud.
8. A unit only proceeds to packaging if all 5 sensors report PASS.

---

## Stage 5 — Display and touch bring-up

### 5.1 Connect the GC9A01A display

The GC9A01A display module connects via a 14-pin FPC ribbon cable. The pinout on the Waveshare module is:

| Pin | Signal | Connect to |
|---|---|---|
| 1 | GND | GND |
| 2 | LEDK (backlight cathode) | GND |
| 3 | LEDA (backlight anode) | 3.3 V via 10 Ω resistor |
| 4 | VDD | 3.3 V |
| 5 | GND | GND |
| 6 | MOSI | GPIO 11 |
| 7 | CLK | GPIO 12 |
| 8 | CS | GPIO 10 |
| 9 | DC | GPIO 8 |
| 10 | RST | GPIO 9 |
| 11 | SCL (touch) | GPIO 5 |
| 12 | SDA (touch) | GPIO 4 |
| 13 | INT (touch) | GPIO 6 |
| 14 | RST (touch) | 3.3 V via 10 kΩ, with 100 nF to GND (soft reset via GPIO if needed) |

Confirm pin 1 alignment before inserting the FPC. Reverse insertion destroys the display.

### 5.2 Initialize the GC9A01A in firmware

The GC9A01A requires a specific initialization sequence. Use the `GC9A01A_Init()` function from the Waveshare ESP32-S3-Touch-LCD-1.28 example code (available at https://www.waveshare.com/wiki/ESP32-S3-Touch-LCD-1.28). Port this function to the production firmware.

After init, fill the screen solid white. If the screen shows white: display is working. If blank: check CS, DC, RST wiring. If noise pattern: SPI clock may be too fast — reduce to 40 MHz first, then increase to 80 MHz after confirming stability.

### 5.3 Initialize the CST816S touch controller

The CST816S uses I2C address 0x15. On power-up, pull RST low for 100 ms then high. The INT pin goes low when a touch event is detected. Read touch data from register 0x01 (gesture) and 0x02–0x05 (X/Y coordinates).

Use the CST816S driver from https://github.com/fbiego/CST816S — this is the most tested open-source driver for this chip.

### 5.4 Integrate LVGL

Install LVGL 8.3 via the ESP-IDF component registry:
```
idf.py add-dependency "lvgl/lvgl==8.3.*"
```

Configure `lv_conf.h`:
- `LV_HOR_RES_MAX` = 240
- `LV_VER_RES_MAX` = 240
- `LV_COLOR_DEPTH` = 16
- `LV_DPI_DEF` = 130
- Buffer: allocate two buffers of 240×40 pixels (19200 bytes each) in PSRAM.
- `LV_DISP_DRAW_BUF_INIT` with `LV_DISP_DRAW_BUF_2` (double buffering).

Flush callback: use SPI DMA to transfer the buffer to the display without blocking the CPU. Use `esp_lcd_panel_io_tx_param()` from the ESP-IDF esp_lcd component for DMA-accelerated SPI.

Call `lv_timer_handler()` every 5 ms from `task_display` on Core 1.

---

## Stage 6 — Production firmware tasks

The production firmware is an ESP-IDF FreeRTOS project. Create it in `firmware/esp32s3/`. Below are the exact task definitions and their responsibilities.

### 6.1 Task structure

Create these 6 tasks in `main/main.c` using `xTaskCreatePinnedToCore()`:

| Task name | Core | Stack (bytes) | Priority | Tick rate |
|---|---|---|---|---|
| `task_sensors` | 0 | 8192 | 5 | 40 Hz (every 25 ms) |
| `task_ble` | 0 | 12288 | 4 | Event-driven |
| `task_storage` | 0 | 8192 | 3 | 1 Hz (every 1000 ms) |
| `task_display` | 1 | 16384 | 5 | 200 Hz (every 5 ms for LVGL) |
| `task_haptic` | 1 | 4096 | 6 | Queue-driven |
| `task_power` | 0 | 4096 | 2 | 0.2 Hz (every 5000 ms) |

### 6.2 task_sensors

Every 25 ms:
1. Call `MAX30102_read_fifo()` — reads the IR and red samples from the MAX30102 FIFO.
2. Run the SparkFun heartRate library `checkForBeat()` on the IR sample.
3. If beat detected: update `g_hr_bpm` using exponential moving average: `g_hr_bpm = 0.8 * g_hr_bpm + 0.2 * (60000.0 / beat_interval_ms)`.
4. Update `g_spo2` using ratio of IR/Red: `ratio = IR / Red; spo2 = 110.0 - 12.0 * ratio; clamp(85, 100)`.
5. Call `QMI8658_read_accel()` — reads X/Y/Z accelerometer.
6. Detect fall: if magnitude < 0.4g for > 80 ms, then spikes > 2.4g: set `g_fall_detected = true`, send haptic command to `haptic_queue`.
7. Post a `sensor_event_t` struct to `g_sensor_queue` (size 16) for `task_ble` and `task_storage` to consume.

### 6.3 task_ble

Uses ESP-IDF NimBLE stack (`idf_component.yml` dependency: `espressif/esp-nimble-cpp`).

On start: initialize BLE with device name "Veyro", configure Secure Connections pairing with a 6-digit static passkey stored in NVS.

Service UUID: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`

Characteristics (same UUIDs as prototype, see `firmware/esp32/DigitalSaverWatch/protocol.h`):
- `beb5483e-36e1-4688-b7f5-ea07361b26a8` — Live (NOTIFY): send sensor data as JSON every 1 second when connected and paired.
- `beb5483e-36e1-4688-b7f5-ea07361b26a1` — History (NOTIFY): stream history rows on sync command.
- `beb5483e-36e1-4688-b7f5-ea07361b26a2` — Info (READ): return watch info JSON.
- `beb5483e-36e1-4688-b7f5-ea07361b26f0` — Command (WRITE): receive and dispatch commands.
- `beb5483e-36e1-4688-b7f5-ea07361b26b0` — Notifications (WRITE): receive phone notification to display on watch.

Commands handled: `pair`, `time`, `face`, `sync`, `next`, `prune`, `ota_start`, `ota_chunk`, `ota_finish`.

OTA command flow: on `ota_start`, call `esp_ota_begin()` on the next OTA partition. On each `ota_chunk`, call `esp_ota_write()`. On `ota_finish`, verify SHA256, call `esp_ota_end()` and `esp_ota_set_boot_partition()`, then `esp_restart()`. On next boot, call `esp_ota_mark_app_valid_cancel_rollback()` after all sensors initialize successfully.

### 6.4 task_storage

Every 1 second: check if 60 seconds have passed since the last sample. If yes, and if HR > 30 or steps > 0:
1. Write one CSV row to LittleFS: `unix,hr,spo2,0,0,hrv,steps,fall,bat`.
2. Increment the cached sample count.
3. Save steps to NVS: `nvs_set_u32(nvs_handle, "steps", g_steps)`.
4. Call `prune_old_files()` if 24 hours have passed since last prune.

### 6.5 task_display

Every 5 ms: call `lv_timer_handler()`.

Every 100 ms: update LVGL label values from the global sensor state (`g_hr_bpm`, `g_spo2`, `g_steps`, `g_battery_pct`, `g_fall_detected`, `g_ble_connected`, `g_paired`).

Touch events: in the `touch_event_handler`, read CST816S, translate X/Y to LVGL input device event, post to LVGL input device queue.

Watch faces: implement all 5 faces specified in the app requirements using LVGL screens (`lv_scr_act()` to switch). Store selected face index in NVS key `"face"`.

### 6.6 task_haptic

Waits on `haptic_queue` (size 8). When a message arrives:
1. Write the effect number to DRV2605L register 0x04.
2. Set GO bit in register 0x0C (write 0x01).
3. The effect plays automatically. The task does not wait for completion — it returns immediately and picks up the next queue item.

Available effects to use:
- Effect 1: "Strong Click" — use for button press feedback.
- Effect 10: "Double Click" — use for successful pairing.
- Effect 47: "Alert" — use for fall detection or low battery.
- Effect 58: "Long Buzz" — use for SOS hold.

### 6.7 task_power

Every 5 seconds:
1. Read BQ25895 via I2C: register 0x0E (battery voltage), register 0x0F (system voltage).
2. Convert VBAT to percentage: `pct = (vbat_mv - 3300) / (4150 - 3300) * 100; clamp(0, 100)`.
3. Update `g_battery_pct`.
4. Read charging status from BQ25895 register 0x0B bits [6:5]:
   - 00 = not charging
   - 01 = pre-charge
   - 10 = fast charging
   - 11 = charge done
5. Update `g_charging_status` and post to `haptic_queue` if battery < 10% (effect 47, once per hour).

---

## Stage 7 — Enclosure assembly

### 7.1 Prepare the case

1. Verify the case dimensions with calipers: outer diameter 44.0 ±0.2 mm, depth 12.0 ±0.2 mm.
2. Verify the optical window on the case back: diameter 3.5 ±0.1 mm, centered within 0.5 mm.
3. Clean all internal surfaces with isopropyl alcohol and allow to dry for 5 minutes.
4. Fit an O-ring (1.5 mm cross-section, 4 mm inner diameter) in the groove of the crown button shaft and the SOS button shaft. Press firmly until seated.

### 7.2 Battery installation

1. Confirm battery voltage with multimeter: must read 3.5–4.2 V. Do not install a battery reading below 3.0 V or above 4.25 V.
2. Place the GREPOW 603035 battery flat against the case back. The JST-PH connector exits toward the PCB connector. The battery must not touch any solder joints, exposed metal, or enclosure screws.
3. Insulate the battery PCM board edges with a strip of polyimide (Kapton) tape.

### 7.3 PCB installation

1. Connect the display FPC ribbon to the PCB FPC connector before placing the PCB in the case.
2. Lower the PCB component-side up onto the battery.
3. Connect the JST-PH battery connector to the PCB battery port.
4. Press the crown button stem and SOS button stem through their respective case holes. Confirm they actuate freely and return to rest.
5. Connect the magnetic charging pogo pins to the PCB pads on the case back — these are spring-loaded and do not require soldering.

### 7.4 Display installation

1. Place the GC9A01A display module face-up above the PCB, FPC ribbon going down to the PCB.
2. Apply a thin bead of Loctite 3491 UV adhesive around the inside rim of the case front bezel.
3. Lower the display into the bezel, face up. Press firmly and evenly for 10 seconds.
4. Apply UV light (365 nm, minimum 1000 mW/cm²) for 30 seconds to cure the adhesive.

### 7.5 Sapphire crystal installation

1. Apply a thin bead of Loctite 3491 UV adhesive to the case rim where the crystal sits.
2. Lower the 37.5 mm sapphire crystal onto the rim. Press firmly for 30 seconds.
3. Apply UV light for 60 seconds. The crystal bond must hold the case together — this is the primary structural element.
4. Wipe excess adhesive immediately with IPA before curing.

### 7.6 Case closure

1. Press the case back onto the case front. The case snaps together with a friction fit.
2. Apply a thin bead of silicone sealant (Dow Corning 3140 RTV) along the case back seam.
3. Allow to cure for 24 hours before water testing.

### 7.7 Strap installation

1. Insert the 20 mm quick-release spring bars into the lug holes.
2. Attach the silicone strap. Confirm the quick-release mechanism engages and releases cleanly.

---

## Stage 8 — Factory test procedure

Run this procedure on every unit before packaging. Use the factory test firmware mode (hold GPIO 0 at boot).

### 8.1 Per-unit pass/fail tests

| Step | Action | Pass condition | Fail action |
|---|---|---|---|
| 1. Power on | Apply USB-C from test jig | Boot in < 3 s, display shows Cambric logo | Disassemble, inspect PCB, re-flash |
| 2. Display colors | Firmware cycles red / green / blue full screen | No dead pixels, no row lines | Replace display module |
| 3. Touch | Firmware shows 5 target dots, tap each | All 5 register within 5 mm | Replace or reflow CST816S |
| 4. HR sensor | Place optical window against fingertip for 15 s | HR reading 50–120 BPM, SNR > 10 dB | Check MAX30102 placement and optical window alignment |
| 5. SpO2 | Same finger, same 15 s | SpO2 reading 92–100% | Same as above |
| 6. Accelerometer | Tilt unit ±45° on each of 3 axes | Values change by > 0.5g on tilted axis | Reflow QMI8658C |
| 7. Pedometer | Shake unit 20 times in walking motion | Step count increments 15–30 | Check QMI8658C INT2 connection |
| 8. Haptic | Firmware triggers strong click, double click, alert | All three effects felt by operator | Check DRV2605L I2C, check LRA motor connection |
| 9. BLE scan | Android test phone runs Digital Saver app | Watch appears as "Veyro" within 10 s | Re-flash firmware, check antenna keep-out on PCB |
| 10. BLE pair | Enter PIN from display | App shows "Connected", green status | Check BLE security config in firmware |
| 11. Battery % | Connect known 3.80 V supply to BAT pin | App shows 59–61% | Check NTC and BQ25895 VBAT register wiring |
| 12. Charging | Connect USB-C to test jig at 5 V | BQ25895 status shows fast charging | Check ILIM and ICHG resistor values |
| 13. Crown button | Press 3 times | Display cycles watch face 3 times | Check GPIO 0 pull-up and button continuity |
| 14. SOS button | Hold 2 seconds | Haptic fires alert effect, fall flag set in app | Check GPIO 13 pull-up and button continuity |
| 15. Firmware hash | Run `esptool.py verify_flash` | Hash matches release manifest | Re-flash with correct firmware |

### 8.2 Batch tests (1 in 50 units)

**Battery life test**: charge to 100%, disconnect USB, run with BLE connected and display at 50% brightness. Record time to reach 5%. Pass condition: ≥ 5 days (120 hours).

**IP67 test**: submerge in 1 m of fresh water for 30 minutes. Remove and dry. Run all per-unit tests. Pass condition: all tests pass, no water ingress visible inside the case.

**Drop test**: drop from 1.2 m onto concrete surface, 6 faces (top, bottom, left, right, front, back). Run all per-unit tests. Pass condition: all tests pass, no visible cracks in crystal or case.

### 8.3 HR accuracy validation (once per production batch of 100 units)

Select 3 units from each batch of 100. Test on 5 human subjects per unit (15 total readings per batch):
1. Subject sits at rest for 5 minutes.
2. Record 1-minute average HR from Veyro and from a Nonin PureSAT Model 9590 pulse oximeter simultaneously.
3. Repeat at light activity (slow walking).

Pass condition: mean absolute error ≤ 5 BPM across all subjects at rest. If any batch fails this test, hold the entire batch, adjust MAX30102 LED current calibration, and retest.

---

## Stage 9 — App configuration for production

### 9.1 Build the release APK with the Gemini key

The GitHub Actions workflow in `.github/workflows/release_build.yml` already injects the `GEMINI_API_KEY` secret into the build. To trigger a production build:

```
git tag v1.x.x
git push origin v1.x.x
```

The workflow builds Android APK, Windows EXE, and Linux AppImage automatically with the key baked in.

### 9.2 Store configuration for Google Play

In `app/android/app/build.gradle`:
- `compileSdkVersion 34`
- `minSdkVersion 21`
- `targetSdkVersion 34`
- `versionCode` increments by 1 for every Play Store submission
- `versionName` matches `AppVersion.current` in `app/lib/services/auto_update_service.dart`

Required files before Play Store submission:
- Privacy policy URL (create at Cambric website)
- App icon 512×512 PNG at `app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Feature graphic 1024×500 PNG
- At least 2 screenshots per screen size

### 9.3 Android permissions in AndroidManifest.xml

Confirm these permissions exist in `app/android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## Stage 10 — Regulatory and compliance

### 10.1 Required certifications before retail sale in Egypt

| Certification | Issuing body | How to apply | Estimated cost | Required before |
|---|---|---|---|---|
| ETA (Equipment Type Approval) | NTRA Egypt — https://www.tra.gov.eg | Submit application at https://www.tra.gov.eg/en/services with device specs, FCC/CE cert if available, and sample unit | $500–2000 (varies) | Selling in Egypt |
| FCC Part 15 (BLE radio) | FCC USA — https://www.fcc.gov | Use an accredited test lab (e.g., UL, Bureau Veritas, SGS). Submit test report + application at https://apps.fcc.gov | $5,000–15,000 | Selling in USA or for NTRA recognition |
| CE RED (radio equipment) | EU — hire a notified body (e.g., TÜV Rheinland https://www.tuv.com) | Submit technical file + test report | $3,000–10,000 | Selling in Europe |
| RoHS self-declaration | Self | Review all component datasheets for RoHS compliance. Document and keep on file. | Internal cost only | Selling anywhere |
| UN 38.3 (lithium battery shipping) | Accredited test lab | Submit battery to any UN 38.3 accredited lab. GREPOW can supply UN 38.3 cert for the GREPOW 603035 — request it with your order. | $500–2000 if self-testing; included if GREPOW provides cert | Air or sea shipping |
| IP67 (IEC 60529) | Any accredited IP test lab | Submit 5 assembled units. Test is 30 min at 1 m depth. | $500–1500 | Claiming IP67 on packaging |

### 10.2 What you can print on the box

Print these:
- "Heart rate wellness tracking"
- "SpO2 wellness estimate"
- "Step and activity tracking"
- "Sleep duration tracking"
- "IP67 water-resistant" (after IEC 60529 test passes)
- "5-day battery life" (after battery life test passes)
- "AI health assistant powered by Google Gemini"

Do not print these without additional clinical validation:
- "Medical grade", "clinically accurate", "ECG", "blood pressure measurement", "detects AFib", "FDA approved", "medically certified"

### 10.3 Battery labeling on packaging

Per IATA DGR (dangerous goods regulations for lithium batteries in shipping):
- Print on the outer box: "LITHIUM ION BATTERY" with the UN 3481 mark.
- Ship batteries at 30% state of charge (set BQ25895 charge target to 3.8 V before packaging: write 0x06 to register 0x06 bits [7:2] for VREG = 3.80 V).

---

## Stage 11 — Packaging and shipment

### 11.1 Packaging contents

Every retail box contains:
1. Veyro watch (charged to 30% via BQ25895 ship mode charge limit)
2. Magnetic pogo-pin charging cable, 40 cm, USB-A
3. One spare silicone strap in the alternate color
4. Quick-start card: QR code links to https://github.com/Cambric-software/Digital-saver/releases for app download

### 11.2 Set ship mode on the BQ25895 before packaging

Connect to the watch via USB, run this I2C command sequence via a test script:
1. Write 0x20 to BQ25895 register 0x09 — enables ship mode.
2. Verify register 0x09 reads back 0x20.

This prevents the battery from draining during storage and transit. The watch wakes from ship mode when USB-C is connected.

### 11.3 Final check before boxing

| Item | Check |
|---|---|
| Display | No scratches on sapphire crystal, clean |
| Case | No scratches, correct color |
| Strap | Attached, correct color for SKU |
| All per-unit tests | Passed (see Stage 8) |
| Firmware hash | Verified and logged |
| Battery charge | Reading 25–35% in BQ25895 register |
| Ship mode | Set (watch does not power on without USB) |

---

## Appendix A — I2C address map

| Device | I2C bus | Address | GPIO SDA | GPIO SCL |
|---|---|---|---|---|
| CST816S (touch) | Bus A | 0x15 | GPIO 4 | GPIO 5 |
| MAX30102 (HR/SpO2) | Bus B | 0x57 | GPIO 1 | GPIO 2 |
| QMI8658C (IMU) | Bus B | 0x6A | GPIO 1 | GPIO 2 |
| DRV2605L (haptic) | Bus B | 0x5A | GPIO 1 | GPIO 2 |
| BQ25895 (PMIC) | Bus C | 0x6B | GPIO 17 | GPIO 18 |

---

## Appendix B — GPIO map (ESP32-S3-MINI-1)

| GPIO | Function | Direction | Notes |
|---|---|---|---|
| 0 | Crown button / BOOT | IN | Pull-up, active low. Also used for ESP32-S3 boot mode selection. |
| 1 | Sensor I2C SDA (bus B) | I/O | MAX30102, QMI8658C, DRV2605L |
| 2 | Sensor I2C SCL (bus B) | OUT | |
| 3 | QMI8658C INT2 | IN | Step interrupt, 10 kΩ pull-down |
| 4 | Touch I2C SDA (bus A) | I/O | CST816S only |
| 5 | Touch I2C SCL (bus A) | OUT | |
| 6 | Touch INT | IN | Active low, 10 kΩ pull-up |
| 7 | Display backlight PWM | OUT | LEDC channel 0 |
| 8 | Display DC | OUT | Data/Command |
| 9 | Display RST | OUT | Active low |
| 10 | Display CS | OUT | Active low |
| 11 | Display MOSI | OUT | 80 MHz SPI |
| 12 | Display CLK | OUT | 80 MHz SPI |
| 13 | SOS button | IN | Pull-up, active low, 2 s hold = SOS |
| 14 | Battery NTC ADC | IN | ADC1 channel 3 |
| 15 | PMIC INT | IN | 4.7 kΩ pull-up |
| 17 | PMIC I2C SDA (bus C) | I/O | BQ25895 only |
| 18 | PMIC I2C SCL (bus C) | OUT | |
| 19 | USB D− | I/O | Native USB 1.1 |
| 20 | USB D+ | I/O | Native USB 1.1 |
| 21 | RGB LED data | OUT | WS2812B-2020 |

---

## Appendix C — BLE characteristic UUIDs

These must match exactly in firmware and app. They are defined in `firmware/esp32/DigitalSaverWatch/protocol.h` and mirrored in `app/lib/services/veyro_protocol.dart`.

| Characteristic | UUID | Direction |
|---|---|---|
| Service | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | — |
| Live vitals | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | NOTIFY |
| History | `beb5483e-36e1-4688-b7f5-ea07361b26a1` | NOTIFY |
| Info | `beb5483e-36e1-4688-b7f5-ea07361b26a2` | READ |
| Command | `beb5483e-36e1-4688-b7f5-ea07361b26f0` | WRITE |
| Phone notifications | `beb5483e-36e1-4688-b7f5-ea07361b26b0` | WRITE |

---

## Appendix D — Release checklist

Run before every tagged GitHub release:

- [ ] `flutter analyze` in `app/` reports zero errors
- [ ] `flutter test` in `app/` passes all tests
- [ ] Firmware builds without warnings: `pio run` or `idf.py build` exits cleanly
- [ ] Firmware SHA256 recorded in release notes
- [ ] `AppVersion.current` in `app/lib/services/auto_update_service.dart` matches the tag
- [ ] `VEYRO_FW_VERSION` in firmware matches the tag
- [ ] BLE pairing and history sync tested end-to-end on physical hardware
- [ ] Gemini AI tested with a real key — correct health responses confirmed
- [ ] `docs/manual.md` updated if any prototype procedure changed
- [ ] `README.md` updated with new version number and new features
- [ ] `SECURITY.md` reviewed — no new attack surface without documentation
- [ ] GEMINI_API_KEY secret confirmed present in GitHub repository secrets
- [ ] GitHub Actions build passes for Android, Windows, and Linux

*Document maintained by Cambric. Update this document before every production run.*
