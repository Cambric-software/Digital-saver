# Digital Saver and Veyro

Digital Saver is a Flutter companion app for a health-tracking watch. Veyro is
the watch. Two firmware targets exist in this repository, and they are at very
different stages.

| Part | Where | State on 2026-11-07 |
|---|---|---|
| Companion app | `app/` | Flutter; 420 tests pass, analyzer reports no errors |
| Veyro prototype | `firmware/esp32/` | Builds (Flash 62.0%, RAM 12.6% as of 2026-10-21); not hardware-tested in this repository |
| Veyro production target | `firmware/esp32s3/` | ESP-IDF source. Builds clean on 2026-11-07 (RAM 28.8%, flash 23.6% of the 4 MB app slot on a 16 MB part), with the NimBLE GATT service, five faces and six themes. Not hardware-tested in this repository |
| Documentation | `docs/` | Start at [docs/README.md](docs/README.md) |

The production watch is a design goal, not a shipped product. The app talks to
the ESP32 prototype over Bluetooth, and the ESP32-S3 target now exposes the same
service and characteristics so the app can pair with it as well. The S3 image
has not been run on a watch in this repository. [docs/ROADMAP.md](docs/ROADMAP.md)
records what is open, including the production hardware redesign in item 4.5.

## What the app does

- Shows live and stored heart rate, an SpO2 estimate, HRV, steps, activity and
  a blood-pressure screen that reads the values the watch sends.
- Stores watch history on the phone, with a defined retention window, and works
  without an account or a cloud service.
- Groups everyday tools under a health hub: wellness (hydration with a goal and
  glass size you set yourself, caffeine, a rest timer), fitness (recovery test,
  zones, workout timer, RPE), lifestyle (fasting timer, mood, movement breaks, a
  BMR estimate) and device diagnostics.
- Schedules alarms, reminders and medication times with the phone's own
  notification system, and shows today's doses. Android may deliver a reminder a
  few minutes late because the app asks for battery-friendly scheduling rather
  than the restricted exact-alarm permission; a desktop build saves the schedule
  but cannot alert.
- Includes guided breathing with box, 4-7-8, coherent and calm rhythms that
  count the real phase and record the seconds practised today.
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
[docs/README.md](docs/README.md); the production firmware plan is
[docs/FIRMWARE_PLAN.md](docs/FIRMWARE_PLAN.md). Production hardware, sourcing
and the measurement gates are in
[docs/HARDWARE_DESIGN.md](docs/HARDWARE_DESIGN.md).

## Documentation

- [docs/README.md](docs/README.md) - the index, and which document to read when.
- [docs/ROADMAP.md](docs/ROADMAP.md) - the ordered plan. Max Tools keeps its
  own copy with its product-specific items.
- [docs/FIRMWARE_PLAN.md](docs/FIRMWARE_PLAN.md) - the production architecture
  and firmware milestones.
- [docs/HARDWARE_DESIGN.md](docs/HARDWARE_DESIGN.md) - the sourced production
  design, 1,000/10,000-unit prices and the gates a build must pass.
- [docs/VEYRO_DEMO_BOM.md](docs/VEYRO_DEMO_BOM.md) - the sourced demo-unit BOM.
- [docs/PLAN.md](docs/PLAN.md) and
  [docs/ARCHITECTURE_STANDARD.md](docs/ARCHITECTURE_STANDARD.md) - the
  Cambric-wide phase status and the repository layout rules.

## Licence and security

This is proprietary software; the source is published for inspection and
personal use under the terms in [LICENSE](LICENSE). Security reporting and the
security model are described in [SECURITY.md](SECURITY.md).
