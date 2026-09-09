# Veyro Watch Manual

## Read this first

This manual is the direct build and operating order for the Veyro prototype. It is written for a bench build. It is not a medical-device assembly guide. Veyro readings are wellness estimates only. Do not wear the first build, charge it unattended, or use it for diagnosis or emergency decisions.

The exact firmware truth is in `firmware/esp32/DigitalSaverWatch`. The app truth is in `app/lib`. The longer explanations and safety gates are in the numbered guides in `docs/`.

Important product boundary: this manual builds the current SSD1306/button prototype. It does not produce a touchscreen or store-grade Apple Watch equivalent. The required production touchscreen, custom PCB, power system, enclosure, and touch operating-system target are specified separately in [docs/11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md). Do not promise those results from the prototype parts.

For the next hardware revision, use the chosen candidate stack in [docs/11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md): first bring up the Waveshare ESP32-S3-Touch-LCD-1.28 reference board, then move the verified display/touch/power/sensor interfaces to a custom carrier. The existing `esp32dev` steps below remain for the current prototype only.

## 1. Parts to obtain

Prices below are USD reference prices checked against the linked vendor pages on 2026-09-09. Prices, stock, tax, shipping, regional availability, and product revisions change. Open the link before ordering and confirm the exact part, voltage, connector, and price at checkout. A similar-looking part is not an approved substitution.

| Part | Required specification | Reference source and price | Quantity |
|---|---|---|---:|
| ESP32-WROOM-32 DevKit | ESP32-WROOM-32, 4 MB flash, 3.3 V logic, USB, no PSRAM required | Espressif product family: https://www.espressif.com/en/products/devkits/esp32-devkitc ; budget USD 10-15, exact board price must be confirmed | 1 |
| MAX30102-compatible optical module | MAX30102 module with red/IR LED and I2C breakout; confirm 3.3 V operation | SparkFun MAX30105 optical sensor breakout, compatible library family: https://www.sparkfun.com/products/1528 ; page reference observed around USD 19.95-24.95, confirm the exact sensor marking before purchase | 1 |
| MPU6050 breakout | MPU6050 accelerometer/gyroscope breakout, 3.3 V logic, I2C | Adafruit MPU-6050 product page: https://www.adafruit.com/product/3886 ; reference page price must be confirmed at checkout | 1 |
| SSD1306 OLED | 128x64, I2C, 0x3C-compatible, 3.3 V-safe breakout; prototype display only, no touch | Adafruit 128x64 OLED product family: https://www.adafruit.com/product/938 ; reference page price must be confirmed at checkout | 1 |
| Protected 1S LiPo | 3.7 V nominal, protected cell, connector and capacity selected after current/fit measurement | Adafruit LiPo battery family: https://www.adafruit.com/category/574 ; price varies by capacity; confirm protection, dimensions, connector, and current rating | 1 |
| LiPo charger with power path | Documented 1S charger with protection and load sharing; do not assume a bare TP4056 board has these | Adafruit Micro Lipo Charger family: https://www.adafruit.com/product/1904 ; reference page price must be confirmed at checkout | 1 |
| 5 V regulator or approved DevKit power path | Regulated output suitable for DevKit VIN/5V and ESP32 transmit peaks | Use the charger/regulator datasheet, not a marketplace title; price and exact part remain MUST CONFIRM | 1 |
| Vibration motor | Small coin motor; GPIO25 must drive a transistor or motor-driver input, never the motor directly | Adafruit vibration motor family: https://www.adafruit.com/category/84 ; exact motor voltage and stall current must be confirmed | 1 |
| NPN motor driver stage | 2N3904 or equivalent transistor, base resistor, flyback diode, and motor supply sized from the motor datasheet | Digi-Key transistor search: https://www.digikey.com/en/products/filter/transistors-bjt-single/276 ; price varies by quantity | 1 |
| Red and green LEDs | 3 mm or 5 mm LEDs with one current-limiting resistor per LED | Digi-Key LED search: https://www.digikey.com/en/products/filter/led-indication-discrete/105 ; price varies by quantity | 2 |
| LED resistors | Start with measured LED and rail values; 330 ohm is a conservative bench starting point, then measure current | Digi-Key resistor search: https://www.digikey.com/en/products/filter/chip-resistor-surface-mount/52 ; price varies by quantity | 2+ |
| Mode and SOS buttons | Momentary normally-open buttons, physically accessible, connected to ground with `INPUT_PULLUP` | Digi-Key tactile switch search: https://www.digikey.com/en/products/filter/tactile-switches/197 ; price varies by quantity | 2 |
| Battery divider resistors | Two measured 100 kohm resistors, BAT+ -> R1 -> GPIO34 -> R2 -> GND | Digi-Key resistor search above; price varies by quantity | 2 |
| Prototype board and wire | Insulated wire, headers, perfboard or a prototype PCB, heat-shrink, strain relief | Digi-Key prototyping family: https://www.digikey.com/en/products/filter/prototyping-products/54 ; price varies by size | 1 set |
| Enclosure and strap | Enclosure must fit the measured parts without compressing the cell; no water-resistance claim | Choose after a cardboard/CAD fit test; price and skin safety are MUST CONFIRM | 1 |
| USB data cable | Known-good data cable for the DevKit | Use a known-good cable already tested for data; do not rely on a charge-only cable | 1 |
| Bench tools | Digital multimeter, calipers, soldering iron, eye protection, current-limited supply if available | Use tools already safety-rated for the work; do not skip the multimeter | 1 set |

### Rejected parts

Do not buy an unprotected LiPo. Do not connect a bare TP4056 module to a LiPo unless its protection, load-sharing behavior, charge current, and thermal behavior are identified from its actual board and datasheet. Do not buy a blood-pressure sensor just to satisfy a feature list; this firmware has no validated blood-pressure measurement path.

## 2. After you have all parts

Get the part name, put it exactly where shown, and use the specified tool.

| Part name | Put it exactly here | Use this tool or method |
|---|---|---|
| ESP32-WROOM-32 DevKit | Center of the bench prototype; USB connector remains accessible | PlatformIO, USB data cable, multimeter |
| MAX30102 module | On the wrist-facing edge, optical window clear and stable | 3.3 V wiring, I2C scan, calipers |
| MPU6050 breakout | Rigidly on the same prototype board as the ESP32 | 3.3 V wiring, I2C scan |
| SSD1306 128x64 OLED | Face-up with the display visible; I2C address must be verified | I2C scan and serial monitor |
| Protected 1S LiPo | Isolated from headers, motor, solder joints, and enclosure screws | Visual inspection, calipers, multimeter; never compress it |
| Charger/power-path board | Outside the wearable enclosure for the first bench test | Datasheet, multimeter, current-limited supply |
| Motor driver and motor | Motor on GPIO25 driver output; motor body isolated from the battery | Soldering iron, diode check, current measurement |
| Red LED | GPIO4 through its resistor | Multimeter current check |
| Green LED | GPIO16 through its resistor | Multimeter current check |
| Mode button | GPIO17 to ground, normally open | Continuity meter |
| SOS button | GPIO32 to ground, normally open | Continuity meter |
| Battery divider R1/R2 | BAT+ -> R1 -> GPIO34 -> R2 -> GND | Ohmmeter before power; voltage measurement after power |
| Enclosure | Only after the wired bench build passes | Cardboard mockup, calipers, visual inspection |

### Wiring map

- I2C SDA: GPIO21.
- I2C SCL: GPIO22.
- Vibration driver input: GPIO25.
- Red LED: GPIO4 through a resistor.
- Green LED: GPIO16 through a resistor.
- Mode button: GPIO17 to ground.
- SOS button: GPIO32 to ground.
- Battery divider midpoint: GPIO34.
- OLED: 128x64 I2C, expected address `0x3C`.
- All grounds must share one verified ground reference.

Never drive the motor from GPIO25 directly. Never feed the LiPo directly into the ESP32 3V3 pin. Confirm every breakout's logic voltage before connecting it.

## 3. Software before assembly

Do this before soldering the final enclosure. The software files already exist in the repository. Do not rename them.

### App and firmware locations

- Firmware project directory: `firmware/esp32/DigitalSaverWatch`.
- Firmware source file: `firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino`.
- Firmware pin file: `firmware/esp32/DigitalSaverWatch/pins.h`.
- Firmware BLE contract: `firmware/esp32/DigitalSaverWatch/protocol.h`.
- Firmware build file: `firmware/esp32/DigitalSaverWatch/platformio.ini`.
- Flutter BLE service: `app/lib/services/ble_service.dart`.
- Flutter BLE contract mirror: `app/lib/services/veyro_protocol.dart`.
- Local history storage: `app/lib/services/local_store.dart`.

### Install the tools

1. Install VS Code.
2. Install the PlatformIO IDE extension.
3. Install Flutter and the Android/desktop toolchains needed for the app.
4. Open the repository folder in VS Code.
5. Open the firmware folder as a PlatformIO project or open the repository and use a terminal.

### Build and flash the ESP32

Open a terminal in `firmware/esp32/DigitalSaverWatch` and run:

```text
pio device list
pio run
pio run --target upload
pio device monitor
```

Use `--upload-port` if more than one port exists. The monitor is `115200`. Disconnect the LiPo while flashing. If the board does not enter upload mode, hold `BOOT` when the upload starts and release it after writing begins.

The boot line is similar to:

```text
Veyro 4.1.0 PIN [redact] PPG=1 MPU=1 OLED=1
```

Do not publish the PIN. Stop if a required sensor reports missing.

The firmware does not advertise the operational BLE service when PPG, MPU6050, OLED, or LittleFS initialization fails. It also does not send live health notifications until the current BLE session has passed PIN pairing. A session must pair again after reconnecting.

The current firmware keeps the prototype inexpensive and efficient: battery readings are sampled every five seconds, history row counts are cached instead of rescanning flash every live update, the OLED redraws at a restrained rate, and the mode button does not block BLE or sensor work. The app clears stale watch state when the watch disconnects.

### Build and run the app

Open a second terminal in `app`:

```text
flutter pub get
flutter analyze
flutter test
flutter run
```

The app scans for the Veyro BLE service, pairs with the six-digit PIN shown on the OLED, sends the clock after pairing, and stores history locally. There is no cloud or Supabase requirement.

## 4. Assemble and test

1. Keep the build on the bench.
2. Check continuity and the power rails with the battery disconnected.
3. Connect the ESP32, OLED, MPU6050, and optical module.
4. Run an I2C scan and record every address.
5. Connect the LEDs, buttons, and motor driver.
6. Test the motor through the driver with a current limit.
7. Test the battery divider against a multimeter.
8. Flash the firmware and capture the redacted boot line.
9. Open the app and pair only after the firmware checks pass.
10. Confirm live heart-rate data is changing from the real sensor, not demo mode.
11. Run a history sync and confirm rows are present in the local app history.
12. Hold SOS for two seconds and verify vibration, red LED, and a persisted event row. This is only a local prototype event; it does not call emergency services.
13. Only after all bench checks pass, make a cardboard enclosure mockup.
14. Do not wear the prototype until battery, motor, optical contact, skin clearance, heat, and enclosure checks pass.

## 5. What the watch actually provides

Implemented: BLE pairing, session-gated live heart-rate estimate, rough experimental SpO2 estimate, accelerometer activity, threshold motion/fall flag, battery estimate, OLED screens, non-blocking vibration, LEDs, local LittleFS history, 60-day pruning, secure phone PIN storage, and app-side local history.

Unavailable or not validated: blood pressure, medical diagnosis, clinical SpO2, validated fall detection, emergency calling, cloud sync, OTA updates, BLE peer identity beyond the current secure paired session, water resistance, and safe wearable fit.

Read `docs/01_PRODUCT_VISION.md` for product boundaries, `docs/03_OFFLINE_DATA.md` for storage, `docs/04_BLE_PROTOCOL.md` for the command contract, `docs/05_HARDWARE_BOM.md` and `docs/06_ASSEMBLY_SAFETY.md` for hardware safety, and `docs/07_FIRMWARE_GUIDE.md` for firmware troubleshooting.

## 6. Stop conditions

Stop immediately for smoke, swelling, chemical odor, unexpected heat, exposed battery conductor, unstable current, a short circuit, a motor that runs without command, a damaged LiPo, a missing sensor, a conflicting I2C address, failed LittleFS, or a BLE connection that reports success without data. Disconnect power only when safe. Keep the unit off the wrist until the cause is understood.
