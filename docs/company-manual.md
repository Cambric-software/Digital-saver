# Veyro Production Watch — Company Manufacturing Manual
**Cambric · Confidential · Revision 1.0 · September 2026**

---

## About This Document

This manual is written for Cambric engineers, contracted PCB houses, and CM (contract manufacturers) producing the Veyro smart watch for retail sale.
It is not the hobbyist prototype guide (that is `docs/manual.md`).
Every section is actionable. Every specification is a hard requirement unless marked DECISION PENDING.

This document covers:
1. Product vision and market targets
2. System architecture for the production hardware
3. Custom PCB design requirements
4. Touchscreen display and UI stack
5. Power system, battery, and charge management
6. Sensor suite and validation requirements
7. Firmware architecture for production
8. Flutter app production requirements
9. Enclosure, strap, and industrial design
10. Testing and quality gates
11. Manufacturing and production line
12. Regulatory, safety, and compliance
13. Software release and OTA update pipeline
14. Glossary

---

## 1. Product Vision

### 1.1 What We Are Building

The Veyro production watch is a **market-grade wearable health monitor** that looks and feels like a consumer smartwatch. It must:

- Have a **round or square touchscreen** with a modern watch-face UI.
- Measure **heart rate, SpO2, step count, sleep, and activity** accurately enough to be useful as a wellness device.
- Run on a **rechargeable LiPo** with at least **5 days** typical battery life.
- Connect to the Digital Saver Android/iOS app over **BLE 5.0**.
- Survive **IP67 water resistance** (1 m for 30 minutes).
- Cost **under $35 USD bill of materials** at volumes of 1,000 units.
- Look and feel worth at least $80 USD retail.

### 1.2 Target Customer

Young health-conscious users aged 16–35 in Egypt and MENA region who want a real health companion, not a toy. They care about:
- Real-looking screen and UI (not a blinking OLED).
- Battery that lasts the week.
- An AI that actually helps them understand their body.
- A price that does not require a credit card.

### 1.3 What This Watch Is NOT

- Not a Class II medical device. No ECG, no FDA-cleared readings.
- Not an Apple Watch clone. We are building our own identity.
- Not a fitness band. Full round face, watch strap, watch UI.

---

## 2. System Architecture

### 2.1 Block Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      VEYRO PRODUCTION MCU                     │
│  ESP32-S3 (240 MHz dual-core, 8 MB flash, 8 MB PSRAM)        │
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ Touchscreen │  │   Sensor     │  │   Power / Charge   │   │
│  │  GC9A01     │  │  MAX30102    │  │   BQ25895 PMIC     │   │
│  │  240×240    │  │  QMI8658C    │  │   + 300 mAh LiPo  │   │
│  │  Round IPS  │  │  (Accel+Gyro)│  │   + 5V USB-C       │   │
│  └─────────────┘  └──────────────┘  └────────────────────┘   │
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │  BLE 5.0    │  │  LittleFS    │  │  Haptic + LED      │   │
│  │  + WiFi     │  │  16 MB NOR   │  │  DRV2605 + RGB     │   │
│  │  (optional) │  │  Flash       │  │                    │   │
│  └─────────────┘  └──────────────┘  └────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 MCU Selection: ESP32-S3

The prototype used ESP32-WROOM-32. Production upgrades to **ESP32-S3-MINI-1** for the following reasons:

| Property | Prototype (ESP32) | Production (ESP32-S3) |
|---|---|---|
| CPU | 240 MHz single-core | 240 MHz dual-core Xtensa LX7 |
| RAM | 520 KB SRAM | 512 KB SRAM + 8 MB PSRAM |
| Flash | 4 MB | 8 MB (supports larger firmware + OTA) |
| BLE | 4.2 | 5.0 (better range, faster pairing) |
| USB | UART bridge (CP2102) | USB 1.1 Full Speed native (no bridge) |
| Display SPI speed | 40 MHz | 80 MHz (smooth 60 fps UI) |
| AI inference | None | Vector instructions (basic ML) |
| Price (1k units) | ~$4 module | ~$3.50 chip (bare die, custom board) |

**Do not use a DevKit in production.** The production board is a custom PCB.

---

## 3. Custom PCB Requirements

### 3.1 Board Specification

| Parameter | Requirement |
|---|---|
| Layers | 4 layers (signal / GND / PWR / signal) |
| Dimensions | Round: 36 mm diameter. Square: 40 × 34 mm |
| Thickness | 0.8 mm (to fit in thin enclosure) |
| Material | FR4, IPC Class 2 |
| Finish | ENIG (gold contacts, corrosion-resistant) |
| Trace width (power) | ≥ 0.3 mm |
| Trace width (signal) | 0.1 mm minimum |
| Impedance control | 50 Ω for antenna trace |
| Test points | Required on all I2C, power rails, USB D+/D− |
| Conformal coating | Required on production boards for IP67 support |

### 3.2 Connector and Interface Map

| Signal | Pin / Connector | Notes |
|---|---|---|
| USB-C (power + data) | USB-C 16-pin | 5 V charging + firmware flashing |
| SPI (display) | GC9A01: CLK, MOSI, CS, DC, RST | 80 MHz max |
| Touch I2C | CST816S: SDA, SCL, INT, RST | 400 kHz |
| Sensor I2C bus | MAX30102 + QMI8658C | Same bus, different addresses |
| Haptic I2C | DRV2605L | Address 0x5A |
| PMIC I2C | BQ25895 | Address 0x6B |
| Battery NTC | ADC input | 10 kΩ NTC to GND |
| Charge indicator LED | GPIO (open-drain) | Active-low from BQ25895 |
| RGB LED | 3 × PWM GPIOs | WS2812 or individual RGB |
| SOS button | 1 GPIO pull-up | Tactile, on side of case |
| Crown/mode button | 1 GPIO pull-up | Tactile or rotary encoder |

### 3.3 Antenna Design

- Use the ESP32-S3 onboard PCB antenna area.
- **Keep a 3 mm copper-free keep-out** around the antenna area on all layers.
- Do not route power planes or ground fills under the antenna trace.
- Run a 50 Ω microstrip to the antenna feed point; calculate width for your stackup.
- Validate with a VNA before mass production: target VSWR < 2.0.

### 3.4 Power Rails

| Rail | Source | Voltage | Max current | Consumers |
|---|---|---|---|---|
| VBAT | LiPo | 3.0–4.2 V | 500 mA | PMIC input |
| VDD_3V3 | BQ25895 LDO / boost | 3.3 V ± 2% | 800 mA | ESP32-S3, sensors, display |
| VDD_1V8 | LDO from 3.3 V | 1.8 V | 100 mA | Display core (if required) |
| VBUS | USB-C | 5 V | 500 mA | Charging only |

### 3.5 ESD and Protection

- TVS diode on USB-C VBUS.
- ESD protection (e.g., PRTR5V0U2X) on USB D+/D−.
- Series resistors (22 Ω) on I2C lines.
- Ferrite bead on VDD_3V3 supply to sensor block.
- Ground pour on all layers tied with stitching vias every 2 mm.

---

## 4. Touchscreen Display

### 4.1 Display Selection: GC9A01

| Property | Specification |
|---|---|
| Driver IC | GC9A01A |
| Resolution | 240 × 240 pixels |
| Shape | Round (1.28 inch diameter) |
| Interface | SPI 4-wire |
| Color depth | 16-bit RGB565 |
| Brightness | 300–400 nits (configurable via PWM backlight) |
| Viewing angle | 170° IPS |
| Operating voltage | 3.3 V logic, 2.8 V display core |
| Touch controller | CST816S (I2C capacitive single-touch) |

Reference board for bring-up: **Waveshare ESP32-S3-Touch-LCD-1.28**.
After bring-up, port the verified display/touch driver to the custom PCB.

### 4.2 Display Driver Library

Use **LVGL 8.3+** as the UI framework.

- Configure LVGL with a 40 × 240 partial-buffer DMA flush strategy to keep RAM usage below 150 KB.
- Render at 30 fps minimum, target 60 fps.
- Use `lv_timer_handler()` in a dedicated FreeRTOS task on Core 1.
- BLE, sensors, and filesystem run on Core 0.
- Implement a `flush_cb` using ESP32-S3 SPI DMA for zero-copy rendering.

### 4.3 Watch Face Design Requirements

Every watch face must follow these rules:
- **Round-safe**: no content in the outer 12 px (corners are cut off by the round bezel).
- **Anti-aliased fonts**: use LVGL's built-in font engine with Montserrat or a Cambric custom font.
- **Dark background default**: white text on dark background uses less power and looks better.
- **Touch zones**: all interactive elements must be at least 48 × 48 px.
- **Transition animations**: use LVGL's built-in page transitions at 200–300 ms.

Required watch faces (minimum for v1.0):
1. Main clock face: large digital time, date, battery, heart rate, step ring.
2. Health face: HR, SpO2, steps, sleep score in quadrant layout.
3. Activity face: step ring, calories, active minutes, distance.
4. AI Assistant: embedded Gemini chat widget (scrollable list + text entry via long-press voice or on-screen keyboard).
5. Settings face: brightness, BLE toggle, power mode.

### 4.4 Haptic Feedback

Use **DRV2605L** haptic controller with an LRA (Linear Resonant Actuator) motor.
- Wired over I2C (address 0x5A).
- Pre-loaded with effects: `click` (1), `double-click` (10), `strong_click` (1), `alert` (47).
- Call via a non-blocking FreeRTOS queue so haptic playback does not block BLE or sensor tasks.

---

## 5. Power System

### 5.1 Battery

| Property | Requirement |
|---|---|
| Chemistry | Lithium Polymer (LiPo) 1S |
| Capacity | 300 mAh minimum. 400 mAh preferred. |
| Dimensions | Must fit within enclosure after PCB (target ≤ 25 × 30 × 5 mm) |
| Protection circuit | MUST have onboard PCM: overcurrent, overcharge, overdischarge |
| Connector | JST-PH 2-pin OR direct solder pads |
| Operating temperature | 0–45 °C charge, −20–60 °C discharge |
| Cycle life | ≥ 300 full cycles to 80% capacity |

**Approved cells (confirm current pricing before ordering):**
- Shenzhen GREPOW 603030 LiPo 300 mAh
- Adafruit 1578 (350 mAh) — suitable for prototype-to-production bridge

### 5.2 Charge Management IC: BQ25895

- Supports USB-C 5 V input at 500 mA.
- I2C programmable charge current (set to 300 mA for this cell size).
- Power-path: the watch runs from USB during charging, not directly from the battery.
- Ship-mode support: set via I2C before packaging to prevent battery drain in transit.
- NTC thermistor input: wire a 10 kΩ NTC from the battery to the THM pin to disable charging outside 0–45 °C.

### 5.3 Power Budget

| Mode | Estimated current | Notes |
|---|---|---|
| Deep sleep | 50 µA | RTC running, BLE off, display off |
| BLE advertising | 1.5 mA | 500 ms interval |
| Active sampling (sensors + BLE + display) | 35–50 mA | Normal wear |
| Display max brightness | +15 mA | Reduce via PWM to 60% in normal mode |
| Charging (USB) | 300 mA input | Power-path isolates from battery |

Expected battery life at 400 mAh:
- 24/7 wear with active sampling: **6–8 days** (estimated, must be measured on hardware).
- Display always-on: reduces to ~2 days.
- Sleep mode nights (display off, BLE every 30 s): 7–10 days.

### 5.4 Charging UI

- When USB connected: display charging animation (animated battery icon, % shown).
- When full: steady battery icon, no animation.
- When battery < 10%: red pulsing battery icon + haptic alert once per hour.
- When battery < 5%: enter power-save mode (display off except button press, BLE every 60 s).

---

## 6. Sensor Suite

### 6.1 Heart Rate and SpO2: MAX30102

Retained from the prototype. Production changes:
- Use a custom optical window in the enclosure back (sapphire glass lens over the sensor).
- Confirm the MAX30102 is spec'd at 3.3 V (it is — confirm the module you use).
- Apply red + IR LED current calibration during factory test (store calibration constants in NVS).
- Target accuracy: HR ±5 BPM vs. clinical reference oximeter in calm conditions. **Must be validated on hardware before claiming any accuracy.**

### 6.2 Accelerometer and Gyroscope: QMI8658C

Replaces MPU6050 for production. Reasons:
- Lower power consumption (6-axis, 90 µA at 52 Hz).
- Smaller package (2.5 × 2.5 mm LGA).
- Faster interrupt response for fall detection.
- Better step-counting pedometer built into the sensor (hardware step counting, not firmware threshold crossings).

Interface: SPI (preferred for high speed) or I2C at 400 kHz.
Configure in step-counter mode: INT2 pin triggers on every 10 steps → ESP32-S3 increments step count (no polling loop needed).

### 6.3 Barometric Pressure / Altitude: BMP280 (Optional v1.1)

Not required for v1.0. Add in the next hardware revision for:
- Altitude tracking (stairs, floors climbed).
- Weather trend display.
- Sleep breathing pressure anomaly detection.

Reserve a footprint on the v1.0 PCB layout so it can be added without a board respin.

### 6.4 Skin Temperature: STTS22H (Optional v1.1)

Not required for v1.0. Wrist skin temperature is not core body temperature. If added, always display as "skin temperature" and never imply it is a fever reading.

### 6.5 Sensor Validation Requirements

Every sensor must pass factory test before the watch ships (see Section 10).

---

## 7. Firmware Architecture (Production)

### 7.1 Upgrade from Prototype

The prototype firmware is a single-file Arduino sketch. The production firmware is a **structured ESP-IDF + FreeRTOS project** with separate tasks.

### 7.2 FreeRTOS Task Structure

| Task | Core | Priority | Stack | Purpose |
|---|---|---|---|---|
| `task_sensors` | 0 | 5 | 8 KB | MAX30102 + QMI8658C polling every 25 ms |
| `task_ble` | 0 | 4 | 12 KB | BLE advertising, connection, GATT |
| `task_storage` | 0 | 3 | 8 KB | LittleFS writes, prune, sync |
| `task_display` | 1 | 5 | 16 KB | LVGL render loop, touch input |
| `task_haptic` | 1 | 6 | 4 KB | DRV2605 queue consumer |
| `task_power` | 0 | 2 | 4 KB | BQ25895 I2C poll, battery % |

Communication between tasks: FreeRTOS queues and semaphores. No global variables shared between tasks without a mutex.

### 7.3 BLE Protocol (v2)

The production firmware upgrades the BLE protocol from v1 (prototype) to v2.

New characteristics (all inside the same service UUID):

| Characteristic | UUID suffix | Direction | Purpose |
|---|---|---|---|
| Live | `26a8` | NOTIFY | 1-second vitals JSON (unchanged) |
| History | `26a1` | NOTIFY | History streaming (unchanged) |
| Info | `26a2` | READ | Watch info JSON (v2 adds firmware_hash) |
| Command | `26f0` | WRITE | Commands (v2 adds `ota_start`, `ota_chunk`, `ota_finish`) |
| Notifications | `26b0` | WRITE | Phone → watch notification (title, body) |
| Watch face | `26b1` | WRITE | Live watch face data push |

BLE security: retain Secure Connections with 6-digit passkey. Upgrade to bonding persistence in v2 (store bonding keys in NVS so the user does not re-pair after every reboot).

### 7.4 OTA Firmware Update (BLE OTA)

The production firmware supports OTA updates delivered over BLE from the phone app.

Flow:
1. Phone downloads new firmware binary from GitHub releases.
2. Phone sends `{"op":"ota_start","size":XXXX,"sha256":"XXXX"}` via command characteristic.
3. Firmware enters OTA mode, opens `esp_ota_begin()`.
4. Phone sends binary in 512-byte chunks via `ota_chunk` commands.
5. After all chunks: phone sends `ota_finish`. Firmware verifies SHA256, calls `esp_ota_set_boot_partition()`, reboots.
6. On first boot from new partition: firmware verifies itself and calls `esp_ota_mark_app_valid_cancel_rollback()`.
7. If verification fails: automatic rollback to previous partition.

Two OTA partitions required in the partition table. Use `partitions_ota.csv`.

### 7.5 Step Count Reset Policy

Steps reset at midnight UTC (the watch sends a `{"op":"reset_steps"}` response at 00:00 UTC if time has been set by the phone). Steps are persisted to NVS every minute (already implemented in prototype firmware 4.1.0+).

### 7.6 Watch-Side Notification Display

The watch can display phone notifications (calls, messages, apps) received via BLE:
- Max 48-character body.
- Title in bold, body in normal weight.
- Auto-dismiss after 8 seconds or on button press.
- No more than 5 notifications in queue. Oldest dropped if queue full.

### 7.7 Low-Power Sleep Mode

When the user is not wearing the watch (HR = 0 for 5 continuous minutes AND no motion):
1. Suspend `task_sensors` (turn off MAX30102 LED drivers via `shutdown()` call).
2. Reduce BLE advertising interval to 2 seconds.
3. Turn off display (keep backlight PWM = 0).
4. Set `task_display` tick to 500 ms (only wakes for button presses).

On motion detection from QMI8658C interrupt or button press: resume all tasks within 500 ms.

---

## 8. Flutter App — Production Requirements

### 8.1 Minimum Feature Set (v1.0 Retail App)

| Feature | Status |
|---|---|
| BLE scan, connect, pair | Implemented (prototype) |
| Live vitals display | Implemented (prototype) |
| History sync from watch | Implemented (prototype) |
| Sleep tracking from history | Implemented (fixed in this release) |
| Real HR min/max tracking | Implemented (fixed in this release) |
| Gemini AI assistant | Implemented (this release) |
| OTA firmware update via BLE | Required for retail — not yet implemented |
| Watch notification bridge | Required for retail — not yet implemented |
| LVGL watch face editor (app) | Optional v1.1 |
| Apple Health / Google Fit sync | Optional v1.1 |
| Menstrual cycle tracking | Optional v1.1 |

### 8.2 App Design Language

Follow the existing Cambric design language already in the app:
- Primary color: `#526B7D` (slate blue-grey).
- Gradients on hero cards.
- Material 3 components.
- Cards with 20 px border radius, `BoxShadow` at 5% black 20 px blur.
- All screens must be responsive to phone screen widths from 360 px to 430 px.

### 8.3 Performance Requirements

- Cold launch to home screen: < 2 seconds on a mid-range Android device.
- BLE scan to connected: < 5 seconds typical.
- Gemini AI first response: < 3 seconds on 4G, < 6 seconds on 3G.
- Memory: app must not exceed 150 MB RAM on Android.
- App size: < 30 MB download from Play Store.

### 8.4 Privacy Requirements

- All health data stays on device (LocalStore).
- The only external network call is to the Gemini API (with user consent on first launch).
- No analytics SDK, no crash reporting SDK that uploads personal data.
- The Gemini system prompt must NOT include the user's real name unless the user has set it.
- User must be able to delete all local data in Settings (already implemented).

### 8.5 Store Requirements

**Google Play:**
- Target API level: 34 (Android 14).
- Required permissions declared in manifest: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `INTERNET` (Gemini), `RECEIVE_BOOT_COMPLETED` (notifications).
- Health permissions screen: show a clear explanation before requesting permissions.
- Privacy policy URL required.

**Apple App Store:**
- Target iOS 15+.
- Bluetooth usage description string in Info.plist.
- HealthKit integration optional v1.1.

---

## 9. Enclosure and Industrial Design

### 9.1 Design Requirements

| Property | Requirement |
|---|---|
| Form factor | Round watch, 44 mm case diameter |
| Case thickness | ≤ 12 mm including crystal |
| Case material | Zinc alloy die-cast (ZA-8) or machined aluminum 6061-T6 |
| Crystal | 1 mm sapphire crystal over the round display |
| Crown | Physical crown button (right side, 3 o'clock position) |
| SOS button | Side button (left side, 9 o'clock position) |
| Charging | Magnetic pogo-pin charger (2-pin, 5 V, attached to case bottom) |
| Strap | 20 mm standard quick-release lug. Silicone strap included. |
| Water resistance | IP67 (tested to IEC 60529). All ports sealed. |
| Color options (v1.0) | Midnight black, cloud silver |

### 9.2 Internal Layout

Stack from bottom to top:
1. Case back (sealed, charges through magnetic pins in the back).
2. Battery (flat, against the back, thermally isolated from PCB).
3. PCB (components face up).
4. Display FPC ribbon (routed carefully to avoid battery pressure).
5. GC9A01 display module.
6. Sapphire crystal (bonded to case with UV-cured adhesive, waterproof ring).
7. Case front with bezel.

No screws visible from the outside. Case snaps or is crimped after assembly.

### 9.3 IP67 Sealing

- O-ring on all mating surfaces (crown button shaft, SOS button, charging port).
- Crown and SOS button use internal labyrinth seals + O-ring compression.
- Charging port is a magnetic pogo-pin connector (no open holes for water entry).
- The speaker/microphone (if added) must use a hydrophobic mesh (Gore-Tex equivalent).
- IP67 test: immerse in 1 m of fresh water for 30 minutes, operate all functions after drying.

### 9.4 Drop Test

Per IEC 60068-2-27:
- 1.2 m drop onto concrete surface, 6 faces.
- Display must not crack or delaminate.
- No component shorts after drop.

---

## 10. Testing and Quality Gates

### 10.1 Factory Test Procedure (Per Unit)

Every unit must pass all these checks before packaging:

| Test | Method | Pass criteria |
|---|---|---|
| Power on | Apply 3.7 V to battery connector | Boots in < 3 seconds, OLED/display shows boot logo |
| HR sensor | Finger on MAX30102 for 10 seconds | HR reading between 50–120 BPM, SNR > 10 dB |
| SpO2 check | Same finger, 10 seconds | SpO2 reading between 90–100% |
| Accelerometer | Tilt board ±45° on each axis | Accelerometer values change correctly |
| Pedometer | Shake watch 20 times | Step count increments 15–25 |
| Display | Full-screen solid red, green, blue | No dead pixels, no row defects |
| Touch | Touch 5 points on screen | All 5 register correctly |
| BLE | Scan from test phone | Veyro appears, pairing succeeds |
| Haptic | Trigger click effect | LRA vibrates, can be felt |
| Battery ADC | Apply known voltage at BAT+ | ADC reading ±3% of expected |
| Charge circuit | Connect USB-C, check STAT LED | STAT LED shows charging |
| Button response | Press each button | GPIO interrupt fires correctly |
| Water resistance | IP67 immersion test (sample-based) | No functional failure after 30 min at 1 m |
| Drop test | IEC 60068-2-27 (sample-based) | No crack or short after 6-face drop |

### 10.2 Firmware Hash Verification

After flashing production firmware:
1. Read back the SHA256 of the firmware partition via UART/JTAG.
2. Compare to the release manifest hash.
3. Log the watch serial number + hash to the factory database.
4. A watch with an unverified hash is not allowed to proceed to packaging.

### 10.3 Batch Sampling

In addition to per-unit tests:
- 1% batch sample: full clinical HR validation against a Nonin PureSAT pulse oximeter.
- 1% batch sample: battery life test (run to 5% from full charge, measure hours).
- 0.1% batch sample: drop test, IP67 immersion.

### 10.4 HR Accuracy Validation

For the HR sensor to be sold as "accurate within ±5 BPM":
- Test on 20 human subjects, ages 18–60, male and female.
- Compare 1-minute average Veyro HR vs. clinical reference at rest, light activity, and moderate activity.
- Must achieve ±5 BPM mean absolute error across all subjects at rest and light activity.
- If not achieved, adjust MAX30102 LED current and sampling algorithm before release.

---

## 11. Manufacturing and Production

### 11.1 Supply Chain

| Component | Supplier (reference) | Lead time (typical) |
|---|---|---|
| ESP32-S3-MINI-1 | Espressif Systems, via Mouser/Digi-Key | 8–12 weeks at low volumes |
| MAX30102 | Maxim/Analog Devices, via Digi-Key | 4–8 weeks |
| QMI8658C | QST Corporation | 4–6 weeks |
| GC9A01A display | Shenzhen suppliers (Waveshare, Aliexpress bulk) | 2–4 weeks |
| CST816S touch IC | Hynitron, via Chinese distributors | 3–5 weeks |
| BQ25895 PMIC | Texas Instruments, via Mouser | 4–8 weeks |
| DRV2605L haptic | Texas Instruments, via Mouser | 4–8 weeks |
| 300 mAh LiPo | Shenzhen GREPOW or equivalent | 3–4 weeks |
| Sapphire crystal | Shenzhen Sapphire Technology | 4–6 weeks |
| Zinc alloy case | Shenzhen CM (quote required) | 6–10 weeks (tooling) |

### 11.2 PCB Assembly

- Use a JLC PCB or equivalent certified CM for PCB fabrication + SMT assembly.
- All components except the battery, display, and crown assembly are SMT.
- IPC Class 2 soldering standard.
- Automated optical inspection (AOI) required after reflow.
- X-ray inspection required for BGA or QFN packages.

### 11.3 Minimum Order Quantities

For cost reasons, the minimum production run is **500 units per SKU**.
Below 500 units: unit cost exceeds retail price — do not proceed to production.
At 1,000 units: target BOM cost < $35.

### 11.4 Packaging

- Retail box: 95 × 95 × 45 mm, FSC-certified cardboard.
- Contents: watch, magnetic charger cable (40 cm), spare silicone strap, quick-start card.
- Quick-start card: QR code links to Digital Saver app download + setup video.
- No CD, no USB-A. USB-C charger not included (reduce cost, industry standard).

---

## 12. Regulatory, Safety, and Compliance

### 12.1 Required Certifications (MENA Market)

| Certification | Body | Notes |
|---|---|---|
| FCC Part 15 (BLE radio) | FCC | Required for export to US. Budget $5,000–$15,000 |
| CE RED (BLE radio) | EU notified body | Required for export to Europe |
| ETA Egypt | NTRA (Egypt) | Required to sell legally in Egypt. Apply via NTRA portal. |
| RoHS | Self-declaration | No lead, cadmium, mercury in components |
| UN 38.3 | Accredited lab | Lithium battery air/sea shipping compliance |
| IP67 | IEC 60529 accredited lab | Required if claiming IP67 on packaging |

### 12.2 Battery Safety

- Never ship with the battery fully charged (charge to 50% for transport).
- Include the lithium battery warning label on outer packaging (IATA DGR).
- Battery recall plan: maintain batch records linking each battery to a production run so a recall can be targeted.

### 12.3 Skin Safety

- The case back must be biocompatibility tested per ISO 10993-10 (skin sensitization) before production.
- Silicone strap must be medical-grade silicone certified free of phthalates and heavy metals.
- Do not use nickel in any part that contacts skin.

### 12.4 Claims on Packaging

**Allowed:**
- "Heart rate wellness tracking"
- "SpO2 wellness estimate"
- "Activity and step tracking"
- "Sleep duration tracking"
- "IP67 water-resistant"
- "5-day battery life" (after validation)
- "AI-powered health assistant" (Gemini)

**NOT allowed without clinical validation:**
- "Medical-grade accuracy"
- "ECG", "clinical SpO2", "blood pressure measurement"
- "Detects AFib" or any disease claim
- "FDA approved" or "medically certified"

---

## 13. Software Release and OTA Pipeline

### 13.1 Versioning Scheme

```
Firmware: MAJOR.MINOR.PATCH  (e.g., 4.2.0)
App:      MAJOR.MINOR.PATCH+BUILD  (e.g., 1.1.0+42)
```

- MAJOR: breaking BLE protocol change (requires matching app + firmware together).
- MINOR: new feature (backwards-compatible).
- PATCH: bug fix.

Always bump both the firmware version string (`VEYRO_FW_VERSION`) and the app version (`AppVersion.current`) before a release.

### 13.2 Release Checklist

Before tagging a GitHub release:

- [ ] All 5 known gaps from the original prototype are verified fixed.
- [ ] `flutter analyze` passes with zero errors.
- [ ] `flutter test` passes with zero failures.
- [ ] Firmware compiles without warnings (zero warnings policy).
- [ ] Firmware SHA256 recorded in release notes.
- [ ] App APK tested on Android 10, 12, and 14 physical devices.
- [ ] BLE pairing and history sync tested end-to-end on hardware.
- [ ] Gemini AI tested with a real key (confirm responses are correct and safe).
- [ ] `docs/manual.md` updated with any changed procedures.
- [ ] `README.md` updated with new version and features.
- [ ] `SECURITY.md` reviewed (no new attack surface introduced).

### 13.3 OTA Update Flow (BLE OTA — v2 Firmware)

1. Cambric pushes new firmware to GitHub releases with SHA256 checksum.
2. App `AutoUpdateService` polls GitHub API (max once per 24 hours).
3. If update found: show in-app update card ("New firmware available for your Veyro").
4. User taps "Update Watch" — app downloads binary, verifies SHA256 locally.
5. App sends OTA via BLE to watch (chunked, with progress bar).
6. Watch validates, reboots, and confirms with new firmware version on BLE info characteristic.
7. App reads new version, shows "Watch updated to vX.X.X" toast.

Rollback: if the watch fails to confirm after 60 seconds, app shows "Update may have failed — reconnect and try again."

---

## 14. Glossary

| Term | Meaning |
|---|---|
| BOM | Bill of Materials |
| CM | Contract Manufacturer |
| DFU | Device Firmware Update |
| ENIG | Electroless Nickel Immersion Gold (PCB finish) |
| FPC | Flexible Printed Circuit (display ribbon) |
| GATT | Generic Attribute Profile (BLE) |
| IPC | Institute of Printed Circuits (assembly quality standard) |
| LRA | Linear Resonant Actuator (haptic motor) |
| LVGL | Light and Versatile Graphics Library (embedded UI framework) |
| MENA | Middle East and North Africa |
| NVS | Non-Volatile Storage (ESP32 Preferences / NVS partition) |
| OTA | Over-The-Air (firmware update) |
| PCM | Protection Circuit Module (battery safety IC) |
| PMIC | Power Management IC |
| PPG | Photoplethysmography (optical HR/SpO2 sensing) |
| PSRAM | Pseudo-Static RAM (external SPI RAM on ESP32-S3) |
| RoHS | Restriction of Hazardous Substances (EU directive) |
| SMT | Surface Mount Technology (PCB assembly) |
| VNA | Vector Network Analyzer (RF antenna testing) |
| VSWR | Voltage Standing Wave Ratio (antenna match quality) |

---

## Appendix A: GPIO Map (Production ESP32-S3)

| Function | GPIO | Direction | Notes |
|---|---|---|---|
| SPI MOSI (display) | GPIO 11 | OUT | 80 MHz SPI |
| SPI CLK (display) | GPIO 12 | OUT | |
| SPI CS (display) | GPIO 10 | OUT | Active low |
| Display DC | GPIO 8 | OUT | Data/Command |
| Display RST | GPIO 9 | OUT | Active low |
| Display BL (backlight PWM) | GPIO 7 | OUT | LEDC channel 0 |
| Touch I2C SDA | GPIO 4 | I/O | 400 kHz |
| Touch I2C SCL | GPIO 5 | OUT | |
| Touch INT | GPIO 6 | IN | Active low |
| Sensor I2C SDA | GPIO 1 | I/O | Same bus: MAX30102 + QMI8658C |
| Sensor I2C SCL | GPIO 2 | OUT | |
| QMI8658C INT2 (step) | GPIO 3 | IN | Step counter interrupt |
| Crown button | GPIO 0 | IN | Pull-up, active low |
| SOS button | GPIO 13 | IN | Pull-up, active low, 2 s hold |
| RGB LED | GPIO 21 | OUT | WS2812 data or 3× PWM |
| USB D+ | GPIO 20 | I/O | USB 1.1 native |
| USB D− | GPIO 19 | I/O | |
| Battery NTC ADC | GPIO 14 | IN ADC | 10 kΩ NTC |
| PMIC INT | GPIO 15 | IN | BQ25895 alert |
| PMIC I2C SDA | GPIO 17 | I/O | Shared or separate bus |
| PMIC I2C SCL | GPIO 18 | OUT | |

---

## Appendix B: Firmware Feature Checklist vs Prototype

| Feature | Prototype (4.1.0) | Production (5.0.0 target) |
|---|---|---|
| Heart rate PPG | ✅ | ✅ + calibration constants |
| SpO2 estimate | ✅ rough | ✅ improved algorithm |
| Blood pressure | ❌ (0/0) | ❌ Not measured (no PTT sensor) |
| Accelerometer steps | ✅ threshold-based | ✅ QMI8658C hardware pedometer |
| Step persistence | ✅ (fixed 4.1.0+) | ✅ + daily midnight reset |
| Fall detection | ✅ rough threshold | ✅ improved with orientation context |
| Sleep detection | App-side from history | App-side from history (improved) |
| BLE Secure Connect | ✅ | ✅ + bonding persistence |
| OTA update | ❌ | ✅ BLE OTA with rollback |
| LVGL UI | ❌ SSD1306 text only | ✅ GC9A01 LVGL 60 fps |
| Phone notifications | ❌ | ✅ |
| Haptic controller | GPIO direct (vibration motor) | ✅ DRV2605L LRA effects |
| IP67 | ❌ no seal | ✅ sealed enclosure |
| Battery life | MUST MEASURE | Target 5+ days |

---

*Document maintained by Cambric. For questions contact the engineering lead.*
*Next review date: 2027-01-01 or before any production run, whichever is sooner.*
