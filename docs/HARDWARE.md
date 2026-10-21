# Hardware

The only hardware that exists today is the **bench prototype**: an ESP32-WROOM-32
DevKit, a 0.96″ OLED, a MAX30102, an MPU6050 and two buttons. Its firmware builds;
the boot path is described in [FIRMWARE.md](FIRMWARE.md).

The **production watch is under redesign** in Phase 4.5 of
[ROADMAP.md](ROADMAP.md). The ESP32-S3 board, sensor list and pin map in
`firmware/esp32s3/` are a sketch of a design that has not been built, and the
7,500 EGP target in [11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md)
is a commercial goal, not a settled design. Nothing in this document should be
read as a production hardware specification.

Pin facts come from `firmware/esp32/DigitalSaverWatch/pins.h`. If this page and
that file disagree, the file wins.

## Safety — read before you power anything

1. Never flash firmware while wearing the device.
2. Wire and re-wire with USB **and** the LiPo disconnected. Connect USB first,
   LiPo last.
3. Never connect a LiPo directly to the ESP32 `3V3` pin, and never connect a
   battery to a GPIO. A protected cell is not a substitute for correct wiring.
4. Do not drive the vibration motor from a GPIO. It draws more current than a
   pin can supply; use the transistor in step 7 of Procedure 1.
5. Stop immediately on smoke, a burning smell, swelling, or unexpected heat.
   Do not touch a swollen cell. Move it outside, away from anything flammable.
6. A TP4056 board without load sharing must not power the watch while it
   charges. It has no power path, so the cell is charged through the same
   terminals the watch draws from. Use a board that states load sharing, or
   charge with the watch switched off.
7. Do not wear the prototype. It has no case, no strain relief and no water
   protection.

## 1. What the prototype is

| | Prototype |
|---|---|
| Board | ESP32-WROOM-32 DevKit, 4 MB flash, no PSRAM (`platformio.ini:1-10`) |
| Display | SSD1306, 128×64, I²C address `0x3C` (`pins.h:17-19`) |
| Sensors | MAX30102 optical and MPU6050 accelerometer on the shared I²C bus; MPU6050 AD0 to GND (`0x68`) |
| Input / output | Mode button GPIO 17, SOS GPIO 32; red LED 4, green LED 16, coin motor via 2N3904 on GPIO 25 |
| Power / radio | Protected 1S LiPo through a charger board, 2:1 divider on GPIO 34; Bluetooth LE only |

It measures heart rate, an SpO₂ estimate, steps, a fall event and battery
voltage. It does **not** measure blood pressure — the firmware always reports
`0/0` and the app shows `N/A`. It is a wellness device, not a medical device.

## 2. Buy the bench parts

Prices are the ranges recorded in the old `manual.md`, converted at roughly
50 EGP = 1 USD in September 2026. They are **indicative, not quotes**: check the
current rate and the seller's page before ordering. Sources named are the ones
that document actually used; no other supplier is implied.

| # | Part | What it must be | Where it was sourced | USD | EGP |
|---|---|---|---:|---:|---:|
| 1 | ESP32 DevKit | ESP32-WROOM-32, 4 MB flash, 38-pin, USB-UART bridge | Robos.io; AliExpress; [Espressif DevKitC](https://www.espressif.com/en/products/devkits/esp32-devkitc) | 5–10 | 250–500 |
| 2 | MAX30102 module | MAX30102 breakout with SDA/SCL/INT/VCC/GND, 3.3 V | Robos.io; [SparkFun SEN-14045](https://www.sparkfun.com/products/14045) | 3–8 | 150–400 |
| 3 | MPU6050 module | GY-521 breakout with AD0 and INT, 3.3 V | Robos.io; [Adafruit 3886](https://www.adafruit.com/product/3886) | 2–4 | 100–200 |
| 4 | OLED | SSD1306, 128×64, I²C, 4-pin, 0.96″, 3.3 V | Robos.io; [Adafruit 938](https://www.adafruit.com/product/938) | 2–5 | 100–250 |
| 5 | LiPo cell | 3.7 V, 400–500 mAh, **built-in protection PCM**, JST-PH 2.0 | Robos.io; [Adafruit 1578](https://www.adafruit.com/product/1578) | 5–10 | 250–500 |
| 6 | Charger board | 1S LiPo charger with JST-PH port and **load sharing** | [Adafruit 1944](https://www.adafruit.com/product/1944); AliExpress “MCP73831 module” | 5–9 | 250–450 |
| 7 | Vibration motor | 3 V ERM coin motor, ~90 mA stall, solder leads | Robos.io; [Adafruit 1201](https://www.adafruit.com/product/1201) | 1–3 | 50–150 |
| 8 | Transistor | 2N3904 NPN, TO-92 | Digi-Key `2N3904FS-ND`; local component shop | 0.05–0.20 | 3–10 |
| 9 | Diode | 1N4148, DO-35 | Digi-Key `1N4148-TAPCT-ND` | 0.05–0.10 | 2–5 |
| 10 | Resistors | 2.2 kΩ ×1, 330 Ω ×2, 100 kΩ ×2, ¼ W | Local component shop; Digi-Key `CF14JT2K20CT-ND` (2.2 kΩ) | ~0.20 | ~10 |
| 11 | LEDs | One red (~2 V), one green (~2.1 V), 3 or 5 mm | Local component shop | 0.10–0.20 | 5–10 |
| 12 | Buttons | 6×6 mm momentary NO tactile, through-hole, ×2 | Digi-Key `CKN9112CT-ND`; Robos.io | 0.20–0.40 | 10–20 |
| 13 | Breadboard | 400-point half-size, or 5×7 cm perfboard | Robos.io; AliExpress | 1–3 | 50–150 |
| 14 | Jumper wires | Male-to-male Dupont, 20 cm, ~40 pieces | Robos.io; AliExpress | 1–3 | 50–150 |
| 15 | USB cable | **Data** cable matching the DevKit socket, not charge-only | Phone shop; confirm a COM port appears | 1–3 | 50–150 |
| 16 | Multimeter | DC volts, continuity, resistance (DT830D class is enough) | Local hardware shop | 5–15 | 250–750 |
| 17 | Soldering iron | Temperature-controlled, 30–60 W, fine tip | Robos.io; AliExpress | 10–30 | 500–1500 |

Total as recorded: about 2,000–3,500 EGP from AliExpress, 2,750–5,000 EGP from
Egyptian shops, and 1,250–2,500 EGP if you already own the meter and iron.
Ordering the wrong charger board is the expensive mistake: a bare TP4056 has no
load sharing and cannot run the watch while charging.

## 3. Procedure 1 — wire the board

Do this with USB and the LiPo disconnected.

1. **Place the DevKit** with the USB socket facing away and the pin labels
   readable. You should see numbered pins on the silkscreen.
2. **Run the I²C pair.** GPIO 21 → SDA and GPIO 22 → SCL on the OLED, MAX30102
   and MPU6050. You should have two wires that each reach three modules. I²C
   needs pull-ups: most breakouts include them, so **MUST CONFIRM** on yours;
   if absent, add 4.7 kΩ from SDA and SCL to `3V3`.
3. **Power the modules.** Each VCC → `3V3`, each GND → a DevKit GND. You should
   have no module on the 5 V pin.
4. **Tie MPU6050 AD0 to GND.** That sets address `0x68`, the one the firmware
   probes. You should be able to trace AD0 to the ground rail.
5. **Wire the LEDs.** GPIO 4 → 330 Ω → red anode; GPIO 16 → 330 Ω → green anode;
   both cathodes → GND. You should trace each resistor to one LED.
6. **Wire the buttons.** GPIO 17 → mode → GND; GPIO 32 → SOS → GND. No series
   resistor; the firmware enables internal pull-ups (`pins.h:10-11`). You should
   see each button short its pin to ground only while pressed.
7. **Build the motor driver.** GPIO 25 → 2.2 kΩ → 2N3904 base (middle pin, flat
   face toward you). Emitter (right) → GND. Collector (left) → one motor wire;
   the other motor wire → `3V3`. 1N4148 across the motor: cathode (stripe) to
   `3V3`, anode to collector. You should see the motor connected only through
   the transistor, never to a GPIO.
8. **Build the battery divider.** Charger `BAT+` → 100 kΩ → GPIO 34 → 100 kΩ →
   GND. You should see GPIO 34 at the junction and nothing else on it.
9. **Connect the charger ground**, and leave its output disconnected until
   Procedure 2 passes. You should have exactly one wire from charger GND to
   DevKit GND.

The pin map, in one table, is `pins.h:4-15`:

| Signal | GPIO |
|---|---:|
| I²C SDA | 21 |
| I²C SCL | 22 |
| Vibration driver | 25 |
| Red LED | 4 |
| Green LED | 16 |
| Mode button (to GND) | 17 |
| SOS button (to GND) | 32 |
| Battery divider midpoint | 34 (input only) |

GPIO 34 is input-only and has no internal pull-up (`pins.h:13-15`). If you skip
the divider, battery percentage stays `0` and the OLED shows `--%`.

## 4. Procedure 2 — check the wiring with no power

Multimeter on continuity (beep). Keep USB and the LiPo disconnected.

1. **Probe GPIO 21 to each SDA pin** in turn. You should hear a beep at the OLED,
   the MAX30102 and the MPU6050.
2. **Probe GPIO 22 to each SCL pin** in turn. You should hear a beep at all
   three modules.
3. **Probe `3V3` to GND.** You should hear **nothing**. A beep is a short: find
   it before applying power.
4. **Probe GPIO 25 to GND, then to `3V3`.** You should hear nothing both times.
   A beep means the motor is wired straight to the pin or to the rail.
5. **Probe GPIO 34 to the divider midpoint.** You should hear a beep, and
   nothing should beep from GPIO 34 to either rail except through a 100 kΩ
   resistor (a resistance reading, not a beep).
6. **Probe each button pin to GND while pressing its button.** You should beep
   only while pressed.

If any check fails, fix the wire and repeat the whole procedure. Do not skip to
power because one check passed.

## 5. Procedure 3 — apply power and measure

**Read this before connecting the charger output.** The old manual said to feed
`BAT+` (3.7–4.2 V) into `VIN`/`5V`. That only works if the DevKit's regulator
holds 3.3 V at 3.7 V input, and most DevKitC clones use a regulator with enough
dropout that it does not. This is a **MUST MEASURE** point, not a documented
fact: the repository contains no measurement of it.

1. **Connect USB only**, LiPo still disconnected. You should see the DevKit
   power LED, and the OLED should show something within a second or two.
2. **Measure `3V3` to GND** with the meter on DC volts. You should read
   3.2–3.4 V. If you read 0 V, the cable is charge-only or the board is dead.
3. **Measure `5V` (or `VIN`) to GND.** You should read 4.8–5.2 V on USB.
4. **Measure GPIO 34 to GND.** With no battery you should read near 0 V. That is
   correct: the divider has no source.
5. **Connect the LiPo to the charger board**, USB still connected. You should
   see the charger's charge indicator behave as its datasheet says (the repo
   does not record which LED pattern your board uses).
6. **Measure the divider midpoint.** At a 3.7 V cell you should read about
   1.85 V. At 0 V, one resistor is open or the cell is not connected.
7. **Decide the power path.** If the charger board has a regulated 5 V output,
   use it. If it only exposes `BAT+`, connect it to `VIN`, **disconnect USB** so
   the cell is the only source, and measure `3V3` again. You should still read
   3.2–3.4 V. If it falls below 3.0 V, stop: use a boost converter to 5 V or a
   3.3 V regulator instead of feeding `BAT+` to `VIN`.

The firmware derives percentage from that midpoint: it doubles the measured
voltage and maps 3.30 V → 0% and 4.15 V → 100% (`DigitalSaverWatch.ino:99-107`).
It returns `0` when the raw ADC reading is below 80, which is how an unwired
divider is detected. It does not model the cell's discharge curve, so the
percentage is a straight line, not a fuel gauge.

Continue with [FIRMWARE.md](FIRMWARE.md) to build, flash and read the boot
banner. Come back here for the bench checks below.

## 6. Procedure 4 — prove the bench build

Run these after the boot banner reports `PPG=1 MPU=1 OLED=1`.

1. **Read the banner.** You should see one line of the form
   `Veyro 4.1.0 PIN 483921 PPG=1 MPU=1 OLED=1`. A `0` in any flag means that
   part did not answer on I²C; the firmware halts rather than pretending.
2. **Write down the PIN.** You should see six digits. It is stored in
   Preferences and survives reboot (`DigitalSaverWatch.ino:609-615`); it is
   **not** regenerated every boot.
3. **Press the mode button repeatedly.** You should cycle through eight
   screens — clock, vitals, activity, motion, battery, storage, connection,
   device — and return to clock.
4. **Read the battery screen.** You should see a percentage, not `--%`, once the
   cell is connected and the divider is wired.
5. **Hold SOS for two seconds.** You should see the motor pulse for about
   600 ms, the red LED come on, and `FALL? hold SOS` on the OLED until the next
   minute sample. That row records `fall=1`. There is no serial message for it.
6. **Cover the MAX30102 with a fingertip and hold still for 30 s.** You should
   see a heart rate in the plausible resting range and an SpO₂ estimate. The
   firmware reports `0` until it has a lock; that is a missing reading, not a
   measurement of zero.

Do not wear the device at any point in this procedure.

## 7. Bench measurements and what is still unknown

| Quantity | What the repository establishes | Status |
|---|---|---|
| `3V3` rail | 3.2–3.4 V expected on USB | MUST MEASURE on your board |
| `BAT+` → `VIN` dropout | Not measured anywhere | MUST MEASURE; use a boost/LDO if `3V3` sags |
| Battery percentage | Linear 3.30–4.15 V map, doubled divider (`DigitalSaverWatch.ino:99-107`) | IMPLEMENTED, not calibrated |
| Battery runtime | No measurement recorded | UNKNOWN |
| Charge current | Set by the charger board, not the firmware | UNKNOWN — read your board's datasheet |
| Motor current | ~90 mA stall from the part class in the old manual | UNKNOWN for your specific motor |
| Sleep current | No sleep mode in the prototype firmware | UNKNOWN |
| Optical accuracy | No calibration or validation data | UNKNOWN; wellness estimate only |
| Step accuracy | Threshold crossing on the accelerometer | UNKNOWN; the old “±20%” claim has no recorded test |
| Case temperature | No case exists | UNKNOWN |

A value in the UNKNOWN rows must not be quoted as a product specification. The
production acceptance gates in
[11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md) are targets for the
future design; no unit has been measured against them.

## 8. The production target is under redesign (Phase 4.5)

What exists in `firmware/esp32s3/` is a **sketch**, not a build. It assumes an
ESP32-S3-MINI-1U-N16R8 (`veyro_main.c:3`, 16 MB flash / 8 MB PSRAM — the spec's
`N8R8` is wrong), a 360×360 round AMOLED over SPI, and these I²C devices:

| Device | Role | Address | Bus (code) |
|---|---|---:|---|
| VC31B | Wrist PPG: HR, SpO₂, HRV | `0x33` | B, GPIO 1/2 |
| QMI6858C | IMU with hardware pedometer (the code comment says 6858; the BOM says QMI8658CULT — **UNKNOWN which**) | `0x6A` | B |
| BMP581 | Pressure / altitude | `0x47` | B |
| STTS22H | Skin temperature | `0x3C` | B |
| DRV2605L | Haptic driver | `0x5A` | B |
| FT6336G | Touch controller | `0x38` | A, GPIO 4/5 |
| BQ25895 | PMIC | `0x6B` | C, GPIO 17/18 |

Source: `firmware/esp32s3/main/veyro_main.c:1-18, 61-93`. The bus lettering is
the code's own. Bus C is declared as `I2C_NUM_2`, which does not exist on a
chip with two I²C controllers — one of the blockers recorded in
[ROADMAP.md](ROADMAP.md) 4.1. Phase 4.5 may replace this architecture entirely,
so **do not order parts from this table**.

The redesign has to decide, explicitly: whether a Linux-class application
processor plus a companion MCU is needed for the large custom OS, or whether an
RTOS on a microcontroller is enough; Wi-Fi/BLE versus cellular; display
technology, size and touch controller; battery, thermal and water-resistance
budget; and the BOM at 7,500 EGP. The acceptance gates (80 µA sleep, 9-point
touch, optical SNR, ≤38 °C case, IP67 vacuum) are the tests that design must
pass, not results.

### Proposed production BOM — carried over, not re-verified

These rows are the previous proposal, kept because each names a source and a
quantity-1000 price. They are inputs to 4.5, and no row has been re-checked
against a current distributor page. Treat every price as stale until quoted.

| Part | Suggested part number | Source named in `company-manual.md` | USD @1k |
|---|---|---|---:|
| MCU | ESP32-S3-MINI-1U-N16R8 | Mouser `972-ESP32-S3-MINI-1U-N16R8`, Digi-Key, LCSC | 4.00–5.00 |
| PPG | VC31B | LCSC `C2678164`; vcare-tech.com | 1.80–2.80 |
| IMU | QMI8658CULT | LCSC `C2851264` | 0.80–1.20 |
| Pressure | BMP581BEAA | Digi-Key `828-BMP581BEAA-ND`; LCSC `C2842781` | 1.20–1.80 |
| Skin temp | STTS22HQTR | Digi-Key `497-STTS22HQTR-ND` | 0.60–1.00 |
| Display | 1.43″ AMOLED 360×360 round, SPI | Alibaba/AliExpress OEM panel, driver JD9613 or compatible | 12.00–18.00 |
| Touch | FT6336GQQ | LCSC `C2678163` | 0.60–1.00 |
| PMIC | BQ25895RTWR | Mouser `595-BQ25895RTWR` | 1.50–2.50 |
| Haptics | DRV2605LYZF4 + JMC0630A LRA | Digi-Key `296-38834-1-ND`; LCSC | 1.70–3.00 |
| Cell | GREPOW 654040, 600 mAh, PCM | grepowsales; Alibaba | 3.50–5.00 |
| NTC | NCP15WF104F03RC | Digi-Key `490-2143-1-ND` | 0.05–0.10 |
| LDO | AP2112K-3.3TRG1 | Digi-Key `1262-1082-1-ND` | 0.10–0.20 |
| USB-C + ESD | UJC-HP-3-SMT-TR, PRTR5V0U2XS | Digi-Key; LCSC | 0.30–0.60 |
| Passives, LED, buttons | 0402 R/C, WS2812B-2020, TS-1187A | LCSC | ~1.00 |

The recorded total was **$28–46 per unit at 1,000 pieces**, before enclosure,
assembly, tax and warranty. The 7,500 EGP model in
[11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md) allocates 1,850 EGP
to the PCBA, which at the September 2026 rate is about $37: the BOM fits only if
it lands below that. That is an arithmetic observation on stale ranges, not a
quote.

## 9. Troubleshooting

| You see | Likely cause | Do this |
|---|---|---|
| No COM port | Charge-only cable or missing USB-UART driver | Try another data cable; check Device Manager |
| Upload stuck at `Connecting...` | Board not in download mode | Hold `BOOT`, start upload, release when writing begins |
| `PPG=0` | MAX30102 not answering at its address | Check SDA/SCL, `3V3`, and that the module is a 3.3 V part |
| `MPU=0` | MPU6050 not answering | Check AD0 to GND, SDA/SCL, `3V3` |
| `OLED=0` | SSD1306 not at `0x3C` | Check the module's address jumper and wiring |
| `3V3` below 3.0 V on battery | `BAT+` fed to `VIN` with a high-dropout regulator | Use a 5 V boost or 3.3 V regulator (Procedure 3, step 5) |
| Battery shows `--%` | Divider missing, or raw ADC under 80 | Recheck GPIO 34 divider; measure the midpoint |
| Heart rate stays `0` | No finger contact, or sensor not initialised | Cover the sensor, hold still, recheck `PPG=1` |
| Board resets when the motor runs | Motor drawing through the MCU supply | Check the transistor and diode; power the motor from `3V3` only through the driver |
| Boot loop after a bad flash | Corrupt image | Erase flash and re-upload; see [FIRMWARE.md](FIRMWARE.md) |
