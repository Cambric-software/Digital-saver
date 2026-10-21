# Firmware features — what exists today

One page of status. “Implemented” means visible in the source and, for the
prototype, built successfully on 2026-10-21. **No bench step has been run for
this rewrite**: there was no hardware on the desk, so every hardware outcome is a
prediction from the code, not a measurement. “Missing” means the code does not
contain it, even if another document describes it.

| | Prototype | Production target |
|---|---|---|
| Path | `firmware/esp32/DigitalSaverWatch` | `firmware/esp32s3` |
| Version string | `4.1.0` | `5.0.0` |
| Framework | Arduino + PlatformIO | ESP-IDF + FreeRTOS + LVGL 8.3.11 |
| Builds | **Yes** — `pio run` SUCCESS | **No** |
| Runs | Not verified in this rewrite; build and code path only | Not flashed; no GATT service |

Build/flash commands and boot diagnostics are in [FIRMWARE.md](FIRMWARE.md).

## Prototype — implemented

| Feature | How it works | Source |
|---|---|---|
| Boot banner | `Veyro 4.1.0 PIN <six digits> PPG=x MPU=x OLED=x` at 115200 baud | `DigitalSaverWatch.ino` `setup()` |
| Hardware gate | Halts with `Veyro halted: required hardware or storage missing` unless PPG, MPU, OLED and LittleFS all initialise | same |
| Heart rate | MAX30102 IR beat detection; exponential smoothing `0.8·old + 0.2·new` | `DigitalSaverWatch.ino:416-439` |
| HRV | Root-mean-square of successive RR differences over up to 20 beats | `DigitalSaverWatch.ino:430-438` |
| SpO₂ | See “the numbers are estimates” below | `DigitalSaverWatch.ino:441-457` |
| Steps | Accelerometer magnitude crossing 1.15 → 1.25 g with a 240 ms debounce | `DigitalSaverWatch.ino:394-400` |
| Step persistence | Count saved to Preferences when it changes, at most once per minute | `DigitalSaverWatch.ino:676-681` |
| Fall event | Free-fall below 0.4 g for >80 ms followed by a spike above 2.4 g; buzz + red LED | `DigitalSaverWatch.ino:402-413` |
| SOS button | Hold 2 s: sets the fall flag, 600 ms buzz, red LED | `DigitalSaverWatch.ino:650-661` |
| Battery | Divider on GPIO 34, doubled, linear 3.30–4.15 V map | `DigitalSaverWatch.ino:99-107` |
| OLED UI | Eight screens, mode button cycles, face saved to Preferences | `DigitalSaverWatch.ino:461-557` |
| BLE | Secure Connections + MITM + bonding, static PIN, four characteristics | `DigitalSaverWatch.ino:336-365` |
| Commands | `pair`, `time`, `face`, `sync`, `next`, `prune` | `DigitalSaverWatch.ino:241-296` |
| Live notify | JSON once per second | `DigitalSaverWatch.ino:367-378` |
| History | One CSV row per minute to LittleFS, 60-day prune | `DigitalSaverWatch.ino:161-195` |
| PIN persistence | Generated once, stored in Preferences | `DigitalSaverWatch.ino:609-615` |

The eight screens are, in button order: **CLOCK**, **VITALS EST.**,
**ACTIVITY**, **MOTION**, **BATTERY**, **STORAGE**, **CONNECTION**, **DEVICE**
(`DigitalSaverWatch.ino:480-551`). Before pairing, every screen is replaced by
the PIN display.

## Prototype — missing or deliberately absent

| Feature | Status |
|---|---|
| Blood pressure | Not measured. Firmware always writes `0/0`; it says so in a comment (`DigitalSaverWatch.ino:451-453`) |
| ECG | No sensor and no code |
| Sleep staging | Nothing on the watch; the app derives it from history |
| Wi-Fi / internet | No Wi-Fi code in this target |
| OTA update | No OTA path; the only update route is re-flashing over USB |
| Deep sleep / low power | No sleep mode; the loop runs continuously |
| Daily step reset | None. Steps are cumulative and persist across reboots |
| Notifications from the phone | No such characteristic implemented |
| Accurate clock | Only after the phone sends `time`; there is no RTC |
| Water resistance | No case, no sealing |

## The numbers are estimates — say so

These are the formulas, so nobody has to guess what a displayed value means:

- **SpO₂ is a placeholder, not pulse oximetry.** When IR is above 50 000 the
  firmware computes `110 − 12 × (IR / red)`, clamps it to 85–100, and smooths it
  by 90/10. The comment in the source says a real algorithm needs red/IR
  buffers. A reading of 85 can simply mean the clamp, not low oxygen.
- **Heart rate is smoothed** at 20% per beat and accepts only beat intervals
  between 300 and 2000 ms. It reports `0` until it has beats.
- **Steps are a single threshold crossing.** No cadence model, no false-step
  rejection. The old “±20%” claim has no recorded test.
- **Fall detection is “very rough” by its own comment** and will fire on a hard
  table slam. It is an event flag, not a medical alarm.
- **Battery percentage is a straight line** between two voltages. It is not a
  fuel gauge and is not calibrated per cell.

`0` always means “no reading”. The OLED prints `--` for battery when it has
none, and the app is required to render zero as `--`.

## Production target — declared, not working

| Area | What the source contains | Status |
|---|---|---|
| MCU / board | ESP32-S3-MINI-1U-N16R8, 16 MB flash, 8 MB PSRAM | Declared in a comment; `sdkconfig.defaults` exists |
| Display | 360×360 round AMOLED over SPI, LVGL, double buffer | `display.c` builds an arc + labels |
| Watch faces | Five IDs (`ANALOG_CLASSIC`, `DIGITAL_MINIMAL`, `FITNESS_PRO`, `CYBER_PIXEL`, `CHRONO_DASH`) | Layout is built once; `display_set_watchface` is an empty stub (`display.c:221-225`) |
| Themes | Six palette IDs | No widget is re-coloured; `display_set_theme` is an empty stub (`display.c:227-231`) |
| Brightness, complications, AOD | Declared in `display.h:55-58` | **No definition** — link would fail |
| Sensors | VC31B, QMI6858C, BMP581, STTS22H, DRV2605L, BQ25895, FT6336G | Init code exists; three I²C buses declared on a two-bus chip. The IMU name is unresolved: the code says 6858, the BOM says QMI8658CULT |
| BLE | UUID constants only | No GATT service or characteristics; the app would find nothing (`veyro_main.c:108-129`) |
| History | SPIFFS, 60-day retention | Present in code; not flashed or tested |
| OTA | Partition table with `ota_0`/`ota_1` at 4 MB each | Partition only; no update client |

So the S3 target is a **scaffold**: it contains pieces of an interface, but it
cannot be paired, cannot show a selectable face, and does not compile as
committed. That is why [ROADMAP.md](ROADMAP.md) pauses 4.4 and sends the hardware
back to 4.5 rather than patching the bus map.

## Parity at a glance

| Capability | Prototype | S3 target |
|---|---|---|
| Builds with the committed configuration | Yes | No |
| Pairs with the app | Yes | No (no GATT table) |
| Live vitals | Yes, 1 Hz | Sensors declared, no BLE |
| History sync | Yes | Storage code only |
| Selectable watch faces | 8 screens, works | 5 IDs, stub |
| Themes | None | 6 IDs, stub |
| Touch | None (two buttons) | FT6336G declared, no UI use |
| OTA | No | Partitions only |
| Low-power sleep | No | Declared in the design, not implemented |

## Claims this page exists to stop

- “The watch measures blood pressure.” It does not.
- “SpO₂ is clinically meaningful.” It is a clamped formula.
- “The production firmware supports five faces and six themes.” The IDs exist;
  the switching functions do nothing.
- “The S3 target is the product.” It is under redesign in 4.5.
- “The PIN changes every reboot.” It persists.
- “Steps reset daily.” They do not.
