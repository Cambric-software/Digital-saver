# Veyro Prototype Watch — Build Manual
**Cambric · Firmware 4.1.0 · App 1.0.2-beta**

This manual builds a working Veyro prototype smartwatch from parts. It is written for someone who has never done this before. Every step has an exact action, an exact tool, and an exact expected result. Nothing is left as "confirm later." If you do not get the expected result, stop and read the troubleshooting note before continuing.

This manual builds the **prototype** — an ESP32 DevKit with an OLED screen and physical buttons. It is not the production touchscreen watch. For the production watch, read `docs/company-manual.md`.

---

## What you will have when finished

- A Veyro watch running firmware 4.1.0 on an ESP32-WROOM-32 DevKit.
- A paired Android or iOS phone running the Digital Saver app.
- Live heart rate, SpO2 estimate, step count, and fall detection working over Bluetooth.
- Local health history stored on the phone for 60 days.
- Digital Saver AI powered by Gemini answering health questions.

---

## Safety rules — read once, follow always

1. Never flash firmware while wearing the device.
2. Disconnect the LiPo battery before plugging in USB. Connect USB first, LiPo last.
3. Stop immediately if you smell burning, see smoke, see swelling, or feel unexpected heat. Do not touch a swollen battery.
4. Never connect the LiPo directly to the ESP32 3.3 V pin. Use the charger board's output only.
5. Never drive the vibration motor directly from a GPIO pin. Always use the transistor driver.
6. Do not wear the prototype until Section 4 (bench test) passes completely.

---

## Part 1 — Buy the parts

Buy exactly these parts. Do not substitute. Each part has a specific reason for being chosen.

EGP prices are based on the USD/EGP exchange rate of approximately 50 EGP = 1 USD as of September 2026. Check the current rate before ordering — it changes. For Egypt, the best local sources are **Robos.io** (https://robos.io), **Makerslab Egypt** (https://makerslab.eg), **Electrony Egypt** (https://electrony.net), and **AliExpress** (ships to Egypt in 2–4 weeks). For international orders, use **AliExpress**, **SparkFun**, **Adafruit**, or **Digi-Key**.

### Required parts

| # | Part name | Exact specification | Where to buy | Price (USD) | Price (EGP) |
|---|---|---|---|---|---|
| 1 | ESP32-WROOM-32 DevKit | ESP32-WROOM-32, 4 MB flash, USB-UART bridge, 38-pin board | Egypt: Robos.io search "ESP32 DevKit" — https://robos.io · Global: AliExpress "ESP32-WROOM-32 DevKit 38 pin" · Official: https://www.espressif.com/en/products/devkits/esp32-devkitc | $5–10 | 250–500 EGP |
| 2 | MAX30102 optical sensor module | MAX30102 chip on a breakout board with SDA, SCL, INT, VCC, GND pins; 3.3 V compatible | Egypt: Robos.io search "MAX30102" or Electrony.net · Global: AliExpress "MAX30102 heart rate sensor module" · SparkFun SEN-14045: https://www.sparkfun.com/products/14045 | $3–8 | 150–400 EGP |
| 3 | MPU6050 accelerometer module | MPU6050 on a GY-521 breakout with SDA, SCL, VCC, GND, AD0, INT; 3.3 V compatible | Egypt: Robos.io "MPU6050 GY-521" or Makerslab.eg · Global: AliExpress "MPU6050 GY-521 module" · Adafruit 3886: https://www.adafruit.com/product/3886 | $2–4 | 100–200 EGP |
| 4 | SSD1306 OLED 128×64 | SSD1306 driver, 128×64 pixels, I2C, 4 pins (VCC GND SDA SCL), 3.3 V safe, 0.96 inch | Egypt: Robos.io "SSD1306 OLED" or Electrony.net · Global: AliExpress "SSD1306 0.96 inch OLED I2C 128x64" · Adafruit 938: https://www.adafruit.com/product/938 | $2–5 | 100–250 EGP |
| 5 | Protected 1S LiPo battery | 3.7 V, 400–500 mAh, with built-in protection PCM, JST-PH 2.0 mm connector | Egypt: Robos.io "LiPo 3.7V 400mAh" or Makerslab.eg · Global: AliExpress "3.7V 400mAh lipo battery JST" · Adafruit 1578: https://www.adafruit.com/product/1578 | $5–10 | 250–500 EGP |
| 6 | MCP73831 LiPo charger board | MCP73831-based 1S charger with JST-PH 2.0 mm battery port, USB input, and load sharing | Egypt: Robos.io "lipo charger" or Electrony.net "TP4056 load sharing" — confirm it has load sharing, not bare TP4056 · Global: Adafruit 1944: https://www.adafruit.com/product/1944 · AliExpress "MCP73831 lipo charger module" | $5–9 | 250–450 EGP |
| 7 | 2N3904 NPN transistor | 2N3904, TO-92 package, through-hole | Egypt: Any electronics component shop on El-Gomhoreya Street, Cairo, or Robos.io · Global: Digi-Key 2N3904FS-ND · AliExpress "2N3904 transistor TO-92" pack of 50 | $0.05–0.20 | 3–10 EGP |
| 8 | 1N4148 diode | 1N4148 fast switching diode, DO-35 package | Egypt: Any electronics component shop · Robos.io · Global: Digi-Key 1N4148-TAPCT-ND · AliExpress "1N4148 diode" pack of 100 | $0.05–0.10 | 2–5 EGP |
| 9 | 2.2 kΩ resistor ×1 | 2.2 kΩ, ¼ W, through-hole | Egypt: Any electronics component shop, sold in bags of 10 · Robos.io · Global: Digi-Key CF14JT2K20CT-ND | $0.05 | 2 EGP |
| 10 | 330 Ω resistor ×2 | 330 Ω, ¼ W, through-hole (one per LED) | Egypt: Same as above | $0.05 each | 2 EGP each |
| 11 | 100 kΩ resistor ×2 | 100 kΩ, ¼ W, through-hole (battery voltage divider) | Egypt: Same as above | $0.05 each | 2 EGP each |
| 12 | Red LED ×1 | 3 mm or 5 mm red LED, ~2 V forward voltage | Egypt: Any electronics component shop · Robos.io | $0.05–0.10 | 2–5 EGP |
| 13 | Green LED ×1 | 3 mm or 5 mm green LED, ~2.1 V forward voltage | Egypt: Same as above | $0.05–0.10 | 2–5 EGP |
| 14 | Coin vibration motor | 3 V ERM coin motor, ~90 mA stall current, with solder leads, 10 mm or 12 mm diameter | Egypt: Robos.io "vibration motor coin" · Global: AliExpress "10mm coin vibration motor 3V" · Adafruit 1201: https://www.adafruit.com/product/1201 | $1–3 | 50–150 EGP |
| 15 | Tactile push buttons ×2 | 6 mm × 6 mm momentary normally-open tactile button, through-hole, 4-pin | Egypt: Any electronics component shop · Robos.io "tactile switch 6x6" · Global: Digi-Key CKN9112CT-ND | $0.10–0.20 each | 5–10 EGP each |
| 16 | Breadboard or perfboard | 400-point half-size breadboard OR 5 cm × 7 cm perfboard with 2.54 mm holes | Egypt: Robos.io "breadboard 400" or "perfboard" · Makerslab.eg · Global: AliExpress "400 point breadboard" | $1–3 | 50–150 EGP |
| 17 | Jumper wires | Male-to-male dupont wires, 20 cm, assorted colours, pack of 40 | Egypt: Robos.io "jumper wires dupont" · Global: AliExpress "40pcs dupont wire 20cm" | $1–3 | 50–150 EGP |
| 18 | USB data cable | USB-A to USB-Micro-B or USB-C depending on your DevKit; must be a data cable (not charge-only) | Egypt: Any phone shop or electronics market · Confirm by plugging into a PC and checking if a COM port appears | $1–3 | 50–150 EGP |
| 19 | Digital multimeter | Any multimeter with DC voltage, continuity beep, and resistance modes | Egypt: Any hardware or electronics shop — a DT830D or DT9205A is sufficient · AliExpress "DT830D multimeter" | $5–15 | 250–750 EGP |
| 20 | Soldering iron | Temperature-controlled soldering iron, 30–60 W, 350–380 °C range, fine tip | Egypt: Any electronics market or Robos.io · A basic Yihua 936 or equivalent is sufficient · AliExpress "soldering iron temperature control 60W" | $10–30 | 500–1500 EGP |

### Total prototype cost estimate

| Scenario | USD | EGP |
|---|---|---|
| Buying everything from AliExpress (ships to Egypt, 2–4 weeks) | $40–70 | 2000–3500 EGP |
| Buying from Egypt local shops (Robos.io + component shops) | $55–100 | 2750–5000 EGP |
| If you already have a multimeter and soldering iron | $25–50 | 1250–2500 EGP |

### You do not need

- A blood pressure sensor. The firmware does not measure blood pressure.
- A bare TP4056 module without load sharing. Use the MCP73831 board listed above.
- Any Wi-Fi module. The watch uses Bluetooth only.

---

## Part 2 — Set up the software (do this before touching hardware)

### 2.1 Install tools on your computer

Do this in order. Each step depends on the previous one.

**Step 1 — Install VS Code**
Download from https://code.visualstudio.com/ and install it.

**Step 2 — Install PlatformIO**
Open VS Code → click the Extensions icon (left sidebar, square icon) → search "PlatformIO IDE" → click Install. Wait for it to finish (takes 2–5 minutes).

**Step 3 — Install Flutter**
Go to https://flutter.dev/docs/get-started/install → choose your operating system → follow the instructions exactly. At the end run this command in a terminal to confirm it worked:
```
flutter doctor
```
You need to see `[✓] Flutter` at minimum. Android toolchain errors are OK for now.

**Step 4 — Install Android Studio** (for Android phone deployment)
Download from https://developer.android.com/studio and install it. During setup, install the Android SDK when prompted. After install, run `flutter doctor` again — you should now see `[✓] Android toolchain`.

**Step 5 — Clone or download the repository**
If you have Git installed:
```
git clone https://github.com/Cambric-software/Digital-saver.git
cd Digital-saver
```
If you do not have Git: go to https://github.com/Cambric-software/Digital-saver → click "Code" → "Download ZIP" → extract it.

### 2.2 Build and verify the firmware (no hardware yet)

Open a terminal. Navigate to the firmware folder:
```
cd Digital-saver/firmware/esp32/DigitalSaverWatch
```
Build the firmware (this downloads all libraries and compiles):
```
pio run
```
Expected result: the last line says `SUCCESS` and shows a firmware size like `Linking .pio/build/esp32dev/firmware.elf`. If it says `ERROR`, read the error message — the most common cause is a missing PlatformIO library that needs internet access. Check your connection and run `pio run` again.

### 2.3 Build and verify the app (no hardware yet)

Open a second terminal. Navigate to the app folder:
```
cd Digital-saver/app
flutter pub get
flutter analyze
```
Expected result: `flutter analyze` says `No issues found!` or only shows info-level messages. Errors in red must be fixed before continuing.

---

## Part 3 — Wire the hardware

Do all wiring with the USB cable disconnected and the LiPo disconnected. Only connect power at the end of this section after checking continuity.

### 3.1 Wiring diagram

All signals connect to these exact GPIO pins on the ESP32-WROOM-32 DevKit:

| What | ESP32 pin | Notes |
|---|---|---|
| I2C SDA (all I2C devices) | GPIO 21 | One wire connects to SDA on OLED, MAX30102, and MPU6050 |
| I2C SCL (all I2C devices) | GPIO 22 | One wire connects to SCL on OLED, MAX30102, and MPU6050 |
| MAX30102 VCC | 3.3 V on DevKit | |
| MAX30102 GND | GND on DevKit | |
| MPU6050 VCC | 3.3 V on DevKit | |
| MPU6050 GND | GND on DevKit | |
| MPU6050 AD0 | GND on DevKit | Sets I2C address to 0x68 |
| OLED VCC | 3.3 V on DevKit | |
| OLED GND | GND on DevKit | |
| Vibration motor driver input | GPIO 25 | Goes to base resistor of 2N3904 (see Section 3.2) |
| Red LED anode | GPIO 4 | Through 330 Ω resistor |
| Green LED anode | GPIO 16 | Through 330 Ω resistor |
| Red LED cathode | GND | |
| Green LED cathode | GND | |
| Mode button pin 1 | GPIO 17 | |
| Mode button pin 2 | GND | |
| SOS button pin 1 | GPIO 32 | |
| SOS button pin 2 | GND | |
| Battery divider midpoint | GPIO 34 | See Section 3.3 |
| Charger board BAT+ output | DevKit VIN or 5 V pin | Check your DevKit pinout — use whichever accepts 3.7–4.2 V |
| Charger board GND | GND on DevKit | |

### 3.2 Vibration motor driver circuit

Do not connect the motor directly to GPIO 25. Follow these exact steps:

1. Connect GPIO 25 → 2.2 kΩ resistor → base of 2N3904 (middle pin, flat face toward you).
2. Connect emitter of 2N3904 (right pin) → GND.
3. Connect collector of 2N3904 (left pin) → one motor wire.
4. Connect the other motor wire → 3.3 V.
5. Place the 1N4148 diode between the motor wires: cathode (striped end) to 3.3 V side, anode to collector side. This protects against motor back-EMF.

### 3.3 Battery voltage divider

This circuit lets the firmware read battery percentage via GPIO 34.

1. Connect BAT+ (positive output of the charger board) → first 100 kΩ resistor → GPIO 34.
2. Connect GPIO 34 → second 100 kΩ resistor → GND.

That is it. Two resistors forming a voltage divider. Do not connect BAT+ directly to GPIO 34.

### 3.4 Check wiring before applying power

With everything wired but USB and LiPo still disconnected:

1. Set your multimeter to continuity mode (beep mode).
2. Check: GPIO 21 beeps to SDA pin on OLED. ✓
3. Check: GPIO 21 beeps to SDA pin on MAX30102. ✓
4. Check: GPIO 21 beeps to SDA pin on MPU6050. ✓
5. Check: GPIO 22 beeps to SCL on all three devices. ✓
6. Check: 3.3 V rail does NOT beep to GND (no short). ✓
7. Check: GPIO 25 does NOT beep to GND or 3.3 V directly. ✓
8. Check: GPIO 34 beeps to the midpoint of the two 100 kΩ resistors. ✓

If any check fails, trace the wire and fix it before continuing.

### 3.5 Connect power and verify voltages

1. Connect the USB cable to the ESP32 DevKit (LiPo still disconnected).
2. Set your multimeter to DC voltage mode.
3. Measure: 3.3 V pin to GND → should read 3.2–3.4 V. ✓
4. Measure: 5 V pin to GND → should read 4.8–5.2 V. ✓
5. Measure: GPIO 34 midpoint to GND → with no battery connected this will read near 0 V. That is correct for now.
6. If 3.3 V reads 0 V: the DevKit is not powered — check the USB cable (must be a data cable).

---

## Part 4 — Flash the firmware and run the bench test

### 4.1 Find the serial port

With the ESP32 connected via USB, open a terminal in `Digital-saver/firmware/esp32/DigitalSaverWatch` and run:
```
pio device list
```
Expected result: you see one entry like `COM3` (Windows) or `/dev/ttyUSB0` (Linux) or `/dev/cu.usbserial-XXXXX` (Mac). That is your ESP32 port.

If no port appears: your USB cable is charge-only. Replace it with a data cable.
If you see multiple ports: unplug the DevKit, run `pio device list` again to see which disappears — that was the DevKit port.

### 4.2 Upload the firmware

```
pio run --target upload --upload-port YOUR_PORT
```
Replace `YOUR_PORT` with the port from the previous step, for example `COM3` or `/dev/ttyUSB0`.

If the upload gets stuck at "Connecting...": hold the `BOOT` button on the DevKit while the upload starts (you will see dots appearing), release `BOOT` after the progress bar starts moving.

Expected result: the terminal shows `Writing at 0x00001000... (100 %)` and then `Hash of data verified. Leaving... Hard resetting via RTS pin...`

### 4.3 Open the serial monitor and read the boot line

```
pio device monitor --port YOUR_PORT --baud 115200
```

Press the `EN` (reset) button on the DevKit. You will see a boot line like:
```
Veyro 4.1.0 PIN 483921 PPG=1 MPU=1 OLED=1
```

**The PIN is a 6-digit number. Write it down. You need it to pair the app.**
Do not share the PIN in screenshots or bug reports.

Check the flags:
- `PPG=1` means MAX30102 found. If `PPG=0`: check SDA/SCL wiring, check VCC, confirm module is 3.3 V.
- `MPU=1` means MPU6050 found. If `MPU=0`: check SDA/SCL, check AD0 is tied to GND, check VCC.
- `OLED=1` means SSD1306 found. If `OLED=0`: check SDA/SCL, check the OLED address — it must be 0x3C.

**Do not continue if any flag is 0.** Fix the hardware first.

### 4.4 Verify the OLED display

The OLED should show "Veyro boot" for a moment then show the PIN screen:
```
Veyro  --%
PIN
483921
```
(Your PIN will be different.)

If the OLED is blank: check that OLED VCC is on 3.3 V, not 5 V. Check SDA and SCL connections.

### 4.5 Test the mode button

Press the mode button (wired to GPIO 17) once. The OLED should cycle to the next screen (vitals). Press it again — cycles to activity. Keep pressing — it goes through all 8 screens: clock, vitals, activity, motion, battery, storage, connection, device. The 8th press brings it back to clock.

If pressing the button does nothing: check the button is wired GPIO 17 → button → GND with no other components in series.

### 4.6 Test the vibration motor

In the serial monitor, the firmware will trigger a short vibration on successful pairing. For now, test it is wired correctly: use your multimeter on DC voltage mode, probe GPIO 25 to GND — it should read 0 V at rest. The motor test happens in Section 4.9.

### 4.7 Test the battery divider

Connect the LiPo battery to the charger board now (USB still connected). Measure the voltage at the GPIO 34 midpoint with your multimeter:
- If battery is at 3.7 V: midpoint should read approximately 1.85 V (half of battery voltage due to equal resistors).
- If midpoint reads 0 V: one or both resistors are not connected correctly.

The OLED battery screen (face 4) should now show a percentage instead of `--%`.

### 4.8 SOS button test

Hold the SOS button (GPIO 32) for 2 full seconds. Expected result:
- Vibration motor activates for about 600 ms.
- Red LED turns on.
- Serial monitor shows the watch has flagged a fall event.

If nothing happens: check GPIO 32 → button → GND wiring. Check that the motor driver circuit is correct (Section 3.2).

### 4.9 All bench checks summary

You must get every result below before moving to the app:

| Check | Expected result | Your result |
|---|---|---|
| Boot line | `PPG=1 MPU=1 OLED=1` | |
| OLED shows PIN | 6-digit number visible | |
| Mode button cycles screens | 8 screens, returns to clock | |
| Battery % shown | Non-zero percentage on battery screen | |
| SOS hold 2 s | Motor vibrates, red LED on | |
| 3.3 V rail | 3.2–3.4 V measured | |
| GPIO 34 midpoint | ~half of battery voltage | |

---

## Part 5 — Install and pair the app

### 5.1 Install the Digital Saver app

**Option A — Download the release APK (Android)**
Go to https://github.com/Cambric-software/Digital-saver/releases and download `digital_saver_android_v1.0.2-beta.apk`. On your Android phone, go to Settings → Install unknown apps → allow your file manager → open the APK and install.

**Option B — Build from source**
Open a terminal in `Digital-saver/app` and connect your phone via USB with USB debugging enabled:
```
flutter pub get
flutter run
```
The app will install and launch on your phone.

### 5.2 Enable Bluetooth and grant permissions

Open Digital Saver on your phone. The first time it opens, it asks for Bluetooth and location permissions. Grant all of them. On Android 12+, grant "Nearby devices" permission. Without these the app cannot scan for the watch.

### 5.3 Scan and connect

1. On the Dashboard screen, tap "Scan & Connect".
2. The app shows a list of nearby Bluetooth devices. Your watch appears as "Veyro".
3. Tap "Veyro" in the list.
4. A PIN entry field appears. Enter the 6-digit PIN from the OLED screen (from Section 4.3).
5. Tap "Pair".

Expected result:
- The watch OLED shows "phone OK" on the clock screen.
- The green LED on the watch turns on.
- The watch vibrates once (short buzz — confirmation of pairing).
- The app Dashboard shows a live heart rate number and step count (may take 30 seconds for heart rate to stabilize).

If pairing fails with "Wrong PIN": press the `EN` reset button on the watch to generate a new PIN, read the new PIN from the OLED, and try again.

### 5.4 Test live data

Hold the MAX30102 sensor firmly against your fingertip for 30 seconds. You should see:
- Heart rate in the app updating to a realistic value (60–100 BPM at rest).
- SpO2 showing 90–100%.
- Steps incrementing if you walk with the device.

If heart rate stays at 0: the sensor is not detecting your finger. Press more firmly, keep still, and wait 30 seconds.

### 5.5 Test history sync

After pairing, the app automatically syncs any history stored on the watch. If this is a fresh build there will be no history yet. Leave the watch paired for 2 minutes while keeping your finger on the sensor — it will write one CSV sample. Then go to the "Watch Memory" tab in the app and tap the sync icon. You should see "1 sample" appear.

---

## Part 6 — Set up Digital Saver AI (Gemini)

The AI works with or without an API key. Without a key it gives basic local responses. With a key it uses Gemini 1.5 Flash and gives full medical-context answers.

### 6.1 Get a free Gemini API key

1. Go to https://aistudio.google.com/
2. Sign in with a Google account.
3. Click "Get API key" → "Create API key".
4. Copy the key (it starts with `AIza...`).

The free tier includes enough quota for normal daily use with no credit card required.

### 6.2 Add the key to the app

If you are running from source:
```
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

If you downloaded the release APK from GitHub: the Gemini key is already baked into the release build by the Cambric GitHub Actions workflow. You do not need to do anything.

### 6.3 Test the AI

Open the app → tap "Assistant" in the bottom navigation. Ask: "How's my heart rate?" — you should get a response that includes your current heart rate value and explains what it means.

If you see "Configure API key for full AI" in the app bar: you are running from source and the key was not passed. Use the `--dart-define` command above.

---

## Part 7 — What the watch measures and what it does not

### What works

| Feature | How it works |
|---|---|
| Heart rate | MAX30102 optical PPG sensor. Reliable at rest with good sensor contact. |
| SpO2 | MAX30102 optical estimate. Wellness trend only — not a clinical reading. |
| Steps | MPU6050 accelerometer threshold crossing. Accurate ±20% in normal walking. |
| Step persistence | Steps survive reboots — saved to NVS every minute. Reset daily at midnight after firmware 5.0. |
| Fall detection | MPU6050 free-fall + spike detection. Triggers on genuine falls but also on hard table slams and some sports. |
| Battery % | Two 100 kΩ resistors on GPIO 34 measure battery voltage. Accurate ±5%. |
| OLED display | 8 screens: clock, vitals, activity, motion, battery, storage, connection, device. |
| BLE connection | Encrypted Secure Connections with 6-digit PIN. Requires re-pair after every reboot (bonding persistence is a production-only feature). |
| History | One CSV row per minute saved to LittleFS. 60-day rolling retention. |
| Sleep tracking | App derives sleep data from history (low HR at night). Shows demo data if no history yet. |
| AI assistant | Gemini 1.5 Flash with full medical knowledge and Veyro troubleshooting context. |

### What does not work

| Feature | Reason |
|---|---|
| Blood pressure | The MAX30102 cannot reliably measure BP. The firmware always outputs 0/0. The app shows "N/A". |
| ECG | Not a sensor on this hardware. |
| Water resistance | No sealing on the prototype. Do not expose to water. |
| Emergency calls | The SOS button records a local event only. It does not call anyone automatically. |
| Clinical accuracy | None of these readings are medically validated. They are wellness estimates. |

---

## Part 8 — Troubleshooting

### Watch not found in Bluetooth scan
- Confirm the watch is powered and the OLED is showing the PIN screen (not blank).
- Confirm Bluetooth is on and all permissions are granted on the phone.
- On Android 12+: go to Settings → Apps → Digital Saver → Permissions → enable "Nearby devices".
- Move the phone within 2 metres of the watch and scan again.
- If still not found: press EN on the watch to reboot it, wait 5 seconds, scan again.

### Wrong PIN error
- The PIN changes every time the watch reboots.
- Read the current PIN from the OLED (it is on screen until pairing succeeds).
- Enter exactly the 6 digits shown. No spaces.

### Heart rate reads 0 after pairing
- Place your finger firmly and flat on the MAX30102 sensor window. Do not move.
- Wait 30 seconds — the algorithm needs several beats to lock on.
- If still 0: check PPG=1 in the boot line. If PPG=0, re-check SDA/SCL wiring.

### SpO2 reads 85%
- This usually means poor sensor contact, not actual low oxygen.
- Press the sensor firmly against your fingertip. Warm your hand if it is cold.

### OLED is blank
- Confirm OLED VCC is 3.3 V (not 5 V).
- Confirm SDA and SCL are wired to GPIO 21 and 22.
- Run an I2C scan: download the Arduino I2C scanner sketch, upload it, and check if address 0x3C appears.

### App crashes on launch
- Run `flutter pub get` then `flutter run` again.
- If the crash mentions Bluetooth: ensure permissions are granted in phone settings.

### Build fails with PlatformIO errors
- The most common cause is a missing library. Run `pio run` with internet access.
- If the error is `esptool.py not found`: reinstall PlatformIO from the VS Code Extensions panel.

### Steps reset after reboot
- This is fixed in firmware 4.1.0+. Confirm your firmware version in the serial boot line says `Veyro 4.1.0`.
- If you built from source and it still resets, confirm the `steps = prefs.getULong("steps", 0)` line is in `setup()` in `DigitalSaverWatch.ino`.

---

## Part 9 — File locations reference

| File | Purpose |
|---|---|
| `firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino` | Main firmware source |
| `firmware/esp32/DigitalSaverWatch/pins.h` | All GPIO pin assignments |
| `firmware/esp32/DigitalSaverWatch/protocol.h` | BLE service UUID and characteristic UUIDs |
| `firmware/esp32/DigitalSaverWatch/platformio.ini` | PlatformIO build config, upload speed, libraries |
| `app/lib/services/ble_service.dart` | BLE scan, connect, pair, live data, history sync |
| `app/lib/services/local_store.dart` | Phone-side CSV history storage |
| `app/lib/services/gemini_service.dart` | Gemini API client and medical system prompt |
| `app/lib/services/digital_saver_ai.dart` | AI assistant logic and context injection |
| `app/lib/services/heart_rate_tracker.dart` | Session and history HR min/max tracking |
| `app/lib/services/auto_update_service.dart` | GitHub release polling and update install |
| `app/lib/services/veyro_protocol.dart` | BLE UUID constants (must match protocol.h) |
| `app/lib/screens/dashboard_screen.dart` | Main app home screen |
| `app/lib/screens/heart_screen.dart` | Heart rate detail screen |
| `app/lib/screens/sleep_screen.dart` | Sleep tracking screen |
| `app/lib/screens/ai_assistant_screen.dart` | Gemini AI chat screen |
| `app/lib/screens/settings_screen.dart` | Profile, watch pairing, app lock, emergency contacts |
| `app/lib/screens/memory_screen.dart` | Watch history sync and analysis |
| `docs/company-manual.md` | Production watch build guide (touchscreen, custom PCB, market) |

---

## Part 10 — What to build next

When you have the prototype working and want to build the real production watch — touchscreen, round case, 5-day battery, IP67 — read `docs/company-manual.md`. That document is written for professional developers and manufacturers and covers everything from PCB design to factory testing to regulatory certification.
