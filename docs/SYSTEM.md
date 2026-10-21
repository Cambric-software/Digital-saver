# System

How the three pieces fit: firmware on the watch, Bluetooth LE in between, the
Flutter app on the phone. The bench prototype is the only part of this system
that runs today. The production target in `firmware/esp32s3/` builds no GATT
service, so it cannot be paired with the app at all (see
[FIRMWARE.md](FIRMWARE.md)).

This page is the contract. Each fact cites the file that owns it. If a document
and a source file disagree, the source file wins — the corrections found in this
rewrite are listed in §6.

## Safety

1. **The data is not a medical record.** Heart rate, SpO₂, HRV, steps and fall
   events are wellness estimates from hobby-grade sensors. Nothing here is
   clinically validated, and no reading should be used to make a health decision.
2. **Losing the phone loses the history.** There is no cloud backup and no
   export that runs by itself. A reinstall of the app removes the 60-day store
   unless the OS kept its application-support directory.
3. **Bluetooth pairing is convenience, not strong authentication.** The PIN is
   six digits, displayed on the watch, and the watch re-requires it after every
   disconnect. Anyone who can see the screen can pair.
4. **A paired phone can read all stored history.** There is no per-record
   authorisation. Unpair by clearing the app's saved PIN, not only by walking
   away.

## 1. Architecture

```
MAX30102 / MPU6050 / SSD1306 ─ I²C 21/22 ─┐
buttons 17/32, motor 25, LEDs 4/16 ──────┼─ ESP32-WROOM-32 ─ LittleFS /d/YYYYMMDD.csv
                                          │
                        BLE GATT, JSON    │
                                          ▼
                       Digital Saver (Flutter)
                        ├ LocalStore CSV (app support)
                        ├ SharedPreferences (profile, contacts)
                        └ flutter_secure_storage (watch PIN)
```

| Component | Responsibility | Source |
|---|---|---|
| `DigitalSaverWatch.ino` | Sampling loop, faces, storage, GATT server | `firmware/esp32/DigitalSaverWatch/` |
| `protocol.h` | UUIDs, protocol version, cadences, retention | `protocol.h:1-14` |
| `ble_service.dart` | Scan, connect, pair, sync, live decode | `app/lib/services/ble_service.dart` |
| `local_store.dart` | Phone CSV store, profile, contacts | `app/lib/services/local_store.dart` |
| `veyro_protocol.dart` | UUID constants used by app and tests | `app/lib/services/veyro_protocol.dart:1-14` |

The watch samples continuously but **writes a history row once per minute**
(`SAMPLE_EVERY_MS 60000`, `protocol.h:13`) and **notifies live data once per
second** (`LIVE_EVERY_MS 1000`, `protocol.h:14`). Data flows one way for live
values; the phone sends commands back on the same connection.

## 2. Watch storage

| Property | Value | Source |
|---|---|---|
| Filesystem | LittleFS, partition table `min_spiffs.csv` | `platformio.ini:14-15` |
| Directory | `/d` | `DigitalSaverWatch.ino:122-129` |
| File name | `/d/YYYYMMDD.csv`, **UTC** day from `gmtime_r` | `DigitalSaverWatch.ino:122-129` |
| Columns | `unix,hr,spo2,sys,dia,hrv,steps,fall,bat` | `DigitalSaverWatch.ino:168-173` |
| Row cadence | one per minute while the watch has a reading | `DigitalSaverWatch.ino:670-681` |
| Retention | 60 days, pruned by comparing the date in the file name | `protocol.h:12`, `DigitalSaverWatch.ino:131-159` |
| Sample counter | counts newline characters across `/d` | `DigitalSaverWatch.ino:180-195` |
| Flash size | 4 MB total; app image uses 62% of the 1.97 MB app slot | verified build, 2026-10-21 |

A row is only written when there is something to write: the loop checks
`hrBpm > 30 || steps > 0 || fall` before appending. A watch sitting still with
no finger contact produces no rows, not rows of zeros. Blood pressure columns
are always `0` — the hardware cannot measure them.

There is no time source on the watch. Until the phone sends `time`, `nowUnix()`
returns `0` and nothing is written (`DigitalSaverWatch.ino:95-97, 162`). That is
the single most common reason a "working" watch syncs zero samples.

## 3. BLE contract

### Service and characteristics

Service `4fafc201-1fb5-459e-8fcc-c5c9c331914b` (`protocol.h:6`):

| Characteristic | UUID | Property | Payload |
|---|---|---|---|
| Live | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | notify | `{"v":1,"hr":..,"spo2":..,"bps":0,"bpd":0,"hrv":..,"steps":..,"fall":0/1,"bat":..,"ts":..}` |
| History | `beb5483e-36e1-4688-b7f5-ea07361b26a1` | notify | `{"v":1,"row":"<csv line>"}` or `{"v":1,"done":1}` |
| Info | `beb5483e-36e1-4688-b7f5-ea07361b26a2` | read | `{"v":1,"fw":"4.1.0","name":"Veyro","paired":bool,"samples":n,"retain_d":60,"free_kb":n,"bat":n}` |
| Command | `beb5483e-36e1-4688-b7f5-ea07361b26f0` | write | JSON `{"op":...}` |

Sources: `protocol.h:6-10`, `DigitalSaverWatch.ino:197-210, 367-378`.

The app also listens for the standard Heart Rate service (`180D` /
characteristic `2a37`) if a device exposes it (`ble_service.dart:198-213`), but
`_wire` still requires all five Veyro characteristics before it stops throwing
(`ble_service.dart:241-243`). A non-Veyro watch can therefore be discovered and
even decoded, but not used: the scan path is broader than the connect path.

### Commands

All are JSON written to the command characteristic. `pair` is the only one
accepted before pairing; every other command is silently ignored until `pair`
succeeds (`DigitalSaverWatch.ino:241-296`).

| Command | Body | Effect | Reply |
|---|---|---|---|
| Pair | `{"op":"pair","pin":"123456"}` | Compares against the stored PIN, sets `paired`, updates info, 80 ms buzz | Info characteristic now has `paired:true` |
| Time | `{"op":"time","unix":1760000000}` | Sets the clock base used for history and `ts` | none |
| Face | `{"op":"face","face":0..7}` | Switches screen, wraps with `% 8`, saves to Preferences | none |
| Sync | `{"op":"sync"}` | Starts paging every `/d` file from the beginning | First history notify, or `done` if empty |
| Next | `{"op":"next"}` | Sends the next history line | Next row, or `done` |
| Prune | `{"op":"prune"}` | Deletes day files older than 60 days, refreshes info | Info characteristic |

### Pairing, in order

1. The watch boots, generates a PIN if none is stored, and advertises the
   service (`DigitalSaverWatch.ino:603-620`).
2. The phone connects. The firmware requires an encrypted Secure Connections
   link with MITM protection and bonding, using that PIN as the static passkey
   (`DigitalSaverWatch.ino:336-343`).
3. The app discovers characteristics and requires **all five** Veyro
   characteristics to exist; missing any one throws
   `Incomplete Veyro BLE service` (`ble_service.dart:189-243`).
4. The app writes `pair` with the PIN the user typed or the one it saved from a
   previous session (`ble_service.dart:244-254, 274-286`).
5. On success the app immediately sends `time` and then `sync`
   (`ble_service.dart:249-253`). You should see the watch clock correct itself
   and the app's memory row count start rising.
6. On disconnect the firmware sets `paired = false` (`DigitalSaverWatch.ino:217-223`).
   The app therefore re-sends `pair` on every reconnect using the saved PIN.
   That is why "it forgets me after reboot" is expected, and why the PIN itself
   must not change — it does not.

The PIN is generated once and stored in Preferences (`DigitalSaverWatch.ino:609-615`).
The old manual said it changes every reboot; that is false.

### History sync, in order

1. Phone writes `{"op":"sync"}`.
2. Watch lists up to 62 files under `/d`, opens the first, and sends one row as
   a notification (`DigitalSaverWatch.ino:226-239, 298-328`).
3. Phone stores the row, then writes `{"op":"next"}` (`ble_service.dart:361-381`).
4. Repeat until the watch sends `{"done":1}`, which clears the app's syncing
   flag.
5. There is no flow control other than this request/response pair, and no MTU
   negotiation in either direction. Throughput is one round trip per row.
   A full 60-day store is tens of thousands of rows; expect minutes, not
   seconds.

If the phone disconnects mid-sync, the watch keeps `histSending` until the
connection callback clears it. Reconnecting and sending `sync` starts from the
first file again; the phone's dedupe (§4) makes the repeat harmless.

## 4. Phone storage

| Item | Where | Source |
|---|---|---|
| History | `<application support>/veyro/days/YYYYMMDD.csv` | `local_store.dart:57-64, 93-106` |
| File day | **Local** date of each sample (`sample.at`) | `local_store.dart:34, 96-100` |
| Row format | Same nine columns as the watch | `local_store.dart:36` |
| Dedupe | Skips a row whose `unix` already starts a line in that day file | `local_store.dart:101-104` |
| Retention | Deletes files older than `retainDays` (60) by file-name date | `local_store.dart:66-85` |
| Profile | `SharedPreferences` key `veyro_profile` | `local_store.dart:139-175` |
| Emergency contacts | `SharedPreferences` key `veyro_contacts` | `local_store.dart:177-197` |
| Watch PIN | `flutter_secure_storage` via `AppLock` | `app/lib/services/app_lock.dart` |

Two consequences worth knowing:

- **The watch names files by UTC day; the phone names them by local day.** A
  sample at 23:30 UTC on a phone set ahead of UTC lands in the watch's file for
  that UTC date and the phone's file for the next local date. Nothing breaks —
  rows carry their own `unix` and screens sort by it — but the file names do not
  match between the two devices, and a person comparing them will think data
  moved.
- **Rows are deduped by the leading `unix,` string, not by content.** Two
  samples with the same timestamp collapse to one. The firmware writes at most
  one row per minute, so this is only a risk if the clock is reset backwards.

`SharedPreferences` is XML/plist, **not encrypted**. Only the PIN uses secure
storage. The old upgrade guide claimed encrypted preferences; it was wrong.

## 5. Live data and the demo mode

`ble_service.dart` decodes live notifications into `HeartRateData`,
`OxygenData`, `BloodPressureData`, `ActivityData` and `AccelData`
(`ble_service.dart:338-359`). Missing keys become `0`, and screens must render
`0` as `--`, not as a measurement.

`startDemo()` fabricates readings: 68–75 bpm, 97% SpO₂, 76% battery, on a
two-second timer (`ble_service.dart:417-427`). It exists so screens can be shown
without hardware. Any screen that displays demo values must say so; the demo
flag is `bleService.demoMode`.

## 6. Version mismatch, and other corrections

**Protocol version differs by design or by mistake — the repository does not
say which.** The firmware stamps every payload with `"v":1`
(`protocol.h:5`), and the app's constant says `version = 2`
(`veyro_protocol.dart:3`). No app code reads `VeyroProtocol.version`, and no
code checks incoming `v`, so today the mismatch is invisible. Treat the wire
format as **v1** and the app constant as stale. If a `v2` is ever defined, the
app must start checking it before the firmware starts sending it.

Corrections made in this rewrite, each against the file that proves it:

| Old claim | Reality | Evidence |
|---|---|---|
| App negotiates protocol v2 | No negotiation; constant unused | `veyro_protocol.dart:3` is never read |
| 512-byte MTU for fast sync | No MTU request or set anywhere | no `requestMtu`/`setMTU` in `firmware/` or `app/lib` |
| Encrypted preferences | Only the PIN is in secure storage | `local_store.dart` uses `SharedPreferences` |
| PIN changes every reboot | PIN persists until erased | `DigitalSaverWatch.ino:609-615` |
| Steps reset daily on firmware 5.0 | No daily reset exists; steps are cumulative and persisted | `DigitalSaverWatch.ino:607, 676-681` |
| 3.2 MB OTA slots | Partition table gives 4 MB to each app slot | `firmware/esp32s3/partitions.csv` |
| Prototype uses SPIFFS *or* LittleFS | Prototype uses LittleFS; S3 target uses SPIFFS | `platformio.ini:15`; `veyro_main.c:40` |
| Watch cannot select faces 4–7 | Fixed: firmware wraps at 8 | `DigitalSaverWatch.ino:260-268` |

Two version numbers are also stale in prose: the app is `1.0.3+3`
(`app/pubspec.yaml:4`), not `1.0.2-beta`, and the AI's primary model is
`gemini-3.8-flash`, not “Gemini 1.5 Flash” (that name survives only as the last
fallback).

## 7. Security and privacy

- **The watch has no network stack.** There is no Wi-Fi code in the prototype;
  history leaves only over BLE, and only while connected.
- **The AI assistant is not local, with or without a key.** A Cloudflare Worker
  URL is compiled in (`gemini_service.dart:12`) and is always considered
  available, so with no key the app posts the conversation plus health context
  to that Worker; with a key it posts directly to
  `generativelanguage.googleapis.com`. Only when the request fails does
  `_offlineHealthAdvisor` answer locally. “Local-only” is true for stored
  history and false for the assistant (`gemini_service.dart:173-288`).
- **The fall/SOS button does not call anyone.** It records an event, buzzes and
  lights the red LED. Emergency contacts are stored but never dialled by
  firmware.
- **Demo data is not labelled at the service layer.** `demoMode` is the only
  signal; a screen that ignores it presents invented numbers as readings.

## 8. Procedure — build, test and release

Run each command in the directory named. These were executed on 2026-10-21 on
this machine.

1. **Build the firmware.** In `firmware/esp32/DigitalSaverWatch`: `pio run`.
   You should see `SUCCESS` and a memory line; the verified run reported
   `RAM 12.6%` and `Flash 62.0%`.
2. **Run the app's unit and widget tests.** In `app`: `flutter test`. You should
   see `All tests passed!` — 346 tests on the verified run.
3. **Run the interaction suite.** In `app`: `flutter test test/interaction`.
   You should see 74 tests pass; see [INTERACTION-TESTS.md](INTERACTION-TESTS.md).
4. **Check the analyzer.** In `app`: `flutter analyze lib test`. Every reported
   line should be `info` or `warning`; there must be no `error`. The verified run
   reported `14 issues found` (2 warnings, 12 infos), and exits 1 because issues
   exist. Do not claim “no issues”; the correct claim is “no errors”.
5. **Build a release APK.** In `app`: `flutter build apk --release`. You should
   get `build/app/outputs/flutter-apk/app-release.apk`. A Gemini key is only
   compiled in if passed with `--dart-define=GEMINI_API_KEY=...`.
6. **Record the artifact hash** so a downloaded build can be checked:
   `Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256`
   on Windows, or `sha256sum` elsewhere. You should get one 64-character hash;
   publish it next to the APK.

There is no release procedure for the production firmware because it does not
build. When it does, its OTA partitions are `ota_0`/`ota_1` at 4 MB each
(`firmware/esp32s3/partitions.csv`), and the app's OTA characteristic
(`...26c0`) is declared but not implemented on either side.

## 9. Diagnostics — where did the data stop?

| Symptom | Check, in order |
|---|---|
| No device in the scan list | Watch booted to the PIN screen; Bluetooth on; “Nearby devices” granted; within 2 m |
| Connects, then `Incomplete Veyro BLE service` | Watch is running the S3 target, or a build without all five characteristics |
| Connected but sync never starts | `paired` is false: the app has no saved PIN, or `pair` was rejected. Pair again with the PIN on screen |
| Sync completes with zero rows | Watch clock was never set, or no row met `hr>30 || steps>0 || fall`. Pair again (the app sends `time`), then leave it running for a few minutes |
| Rows arrive, screens stay empty | Phone store empty or pruned; check `veyro/days` in the app support directory |
| Duplicate rows after re-sync | Should not happen — dedupe is by `unix`. If it does, two rows share a timestamp |
| Heart rate `0` while connected | Sensor has no contact. `0` means no reading, not zero beats |
| Battery `--` | Divider unwired; see [HARDWARE.md](HARDWARE.md) §7 |
