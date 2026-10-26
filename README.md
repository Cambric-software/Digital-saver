# Digital Saver and Veyro

Digital Saver is a Flutter companion app for a health-tracking watch. Veyro is
the watch. Two firmware targets exist in this repository, and they are at very
different stages.

| Part | Where | State on 2026-10-21 |
|---|---|---|
| Companion app | `app/` | Built on Flutter; 346 tests pass, analyzer reports no errors |
| Veyro prototype | `firmware/esp32/` | Builds (Flash 62.0%, RAM 12.6%); not hardware-tested in this repository |
| Veyro production target | `firmware/esp32s3/` | **Does not build**; the hardware is under redesign |
| Documentation | `docs/` | Rewritten; start at [docs/README.md](docs/README.md) |

The production watch is a design goal, not a shipped product. The app talks to
the ESP32 prototype over Bluetooth; the ESP32-S3 target has no GATT service yet,
so it cannot be paired with, and its pin map assigns three I2C buses to a chip
with two. [docs/FIRMWARE.md](docs/FIRMWARE.md) records the exact blockers rather
than presenting the target as finished. The redesign, with sourced parts, is
item 4.5 in [docs/ROADMAP.md](docs/ROADMAP.md).

## What the app does

- Shows live and stored heart rate, an SpO2 estimate, HRV, steps, activity and
  a blood-pressure screen that reads the values the watch sends.
- Stores watch history on the phone, with a defined retention window, and works
  without an account or a cloud service.
- Groups everyday tools under a health hub: wellness (breathing, hydration,
  caffeine, a rest timer), fitness (recovery test, zones, workout timer, RPE),
  lifestyle (fasting timer, mood, movement breaks, a BMR estimate) and device
  diagnostics.
- Includes an app lock, an emergency contact card, a daily reflection log and a
  watch-face preview.
- Has an assistant screen that calls a hosted endpoint. It is not an offline
  model, and it says so when the call fails.

## What it is not

- Not a medical device. Nothing in the app or the firmware diagnoses,
  treats or replaces professional care. SpO2 is an estimate; the prototype
  reports no blood pressure; fall detection is a threshold heuristic.
- Not an account system. Data stays on the phone and the watch unless you export
  it. The app lock PIN is checked on the device and cannot be recovered: it can
  only be cleared by reinstalling, which removes the stored data.
- Not finished. The roadmap is ordered and states what is open, including the
  production hardware redesign.

## Repository layout

```text
app/                     Flutter companion app
firmware/esp32/          Veyro prototype (Arduino, PlatformIO, esp32dev)
firmware/esp32s3/        Veyro production target (ESP-IDF, LVGL) - does not build
docs/                    All documentation, including the roadmap
```

## Quick start

App, from `app/`:

```powershell
flutter pub get
flutter test
flutter run
```

Prototype firmware, from `firmware/esp32/DigitalSaverWatch/`:

```powershell
pio run
pio device list
pio run --target upload
pio device monitor
```

The build and flash steps, the expected boot line and the recovery table are in
[docs/FIRMWARE.md](docs/FIRMWARE.md). Hardware and wiring are in
[docs/HARDWARE.md](docs/HARDWARE.md).

## Documentation

- [docs/README.md](docs/README.md) - the index, and which document to read when.
- [docs/ROADMAP.md](docs/ROADMAP.md) - the ordered plan; shared verbatim with
  Max Tools, Cambric's other product.
- [docs/FIRMWARE.md](docs/FIRMWARE.md) - what each firmware target does, and how
  to build and flash the one that builds.
- [docs/HARDWARE.md](docs/HARDWARE.md) - the bench prototype, sourcing and
  power safety, and what the production redesign must decide.
- [docs/SYSTEM.md](docs/SYSTEM.md) - the watch-to-phone data path, BLE contract,
  storage and release checks.

## Licence and security

This is proprietary software; the source is published for inspection and
personal use under the terms in [LICENSE](LICENSE). Security reporting and the
security model are described in [SECURITY.md](SECURITY.md).
