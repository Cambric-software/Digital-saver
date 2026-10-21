# Upgrade and rollback

What can be updated, in what order, and how to get back. This replaces the old
guide's OTA description, which described firmware that does not exist.

| Piece | Upgrade route that works today |
|---|---|
| Flutter app | Install a new APK, or `flutter run` from source |
| Prototype firmware | USB flash from PlatformIO |
| Prototype filesystem | Created by the firmware; only erased by an explicit erase |
| S3 production firmware | Nothing — it does not build, and has no OTA client |
| Protocol | Nothing negotiated; app and firmware must be edited together |

## Safety

1. **Back up the phone's history before installing a new app build.** There is
   no migration step and no cloud copy; if the OS clears application support,
   the rows are gone.
2. **Do not flash while the watch is worn,** and disconnect the LiPo before
   connecting USB if the build is still on the bench (see
   [HARDWARE.md](HARDWARE.md)).
3. **Never erase flash on a watch whose history you have not synced.** Erase
   removes LittleFS and the saved PIN, not just the firmware.
4. **Keep the previous APK and firmware binary** until the new one has been
   exercised for a day. Rollback is reinstalling that file.

## 1. Procedure — back up the phone history

Run on the development machine, with the phone's app data accessible (debug
build, or a file manager that can reach app-private storage).

1. **Find the store.** The app writes to
   `<application support>/veyro/days/YYYYMMDD.csv`; on Android that is under the
   app's private files directory, not `/sdcard`.
2. **Copy the whole `veyro` folder** somewhere outside the app. You should end
   up with `days/` and its CSV files; the profile and contacts live in
   `SharedPreferences`, not in this folder.
3. **Count the rows.** Open one file; you should see lines beginning with a Unix
   timestamp and eight more comma-separated fields. If the folder is empty, the
   app had nothing synced — back that up too by writing down the watch's sample
   count from the Device diagnostics screen.
4. **Copy the watch PIN** if you will reinstall the app. It is in secure storage
   and will not survive an uninstall; without it you must re-pair using the PIN
   shown on the watch.

## 2. Procedure — upgrade the app

In `app/`:

1. **Fetch and test.** `flutter pub get`, then `flutter test`. You should see all
   tests pass before you install anything.
2. **Build.** `flutter build apk --release`. You should get
   `build/app/outputs/flutter-apk/app-release.apk`.
3. **Install over the old build.** `flutter install`, or copy the APK to the
   phone and open it. You should see the same app with the same history and
   profile, because the package name did not change.
4. **Check the version.** Settings should show `1.0.3` (build 3) or whatever
   version you built. If it shows the old number, the install did not replace
   the app.
5. **Pair and sync once.** Connect to the watch. You should see the PIN accepted
   without retyping, and the Memory screen should not duplicate rows that were
   already stored (dedupe is by timestamp).

If the new build cannot connect, roll back with §5 before changing the watch.

## 3. Procedure — upgrade the prototype firmware

In `firmware/esp32/DigitalSaverWatch`:

1. **Build first, with the watch disconnected.** `pio run`. You should see
   `SUCCESS` and a flash figure near 62%.
2. **Find the port.** `pio device list`. You should see the DevKit's COM port.
3. **Flash.** `pio run --target upload --upload-port COMx`. You should see
   `Hash of data verified` and a hard reset.
4. **Read the banner.** `pio device monitor --port COMx --baud 115200`. You
   should see `Veyro <version> PIN <six digits> PPG=1 MPU=1 OLED=1`. A zero flag
   means the firmware halted; the old firmware is gone, so fix the hardware.
5. **Check what survived.** Steps and the PIN are in Preferences (NVS); history
   is in LittleFS. A normal upload keeps both. An erase does not — see §4.
6. **Sync before trusting the new build.** On the phone, open Memory and sync.
   You should see the watch's existing rows arrive; if the count is zero, either
   the clock was never set or the filesystem was erased.

A firmware downgrade uses the same procedure with an older source tree or a
saved `firmware.bin`. There is no on-watch rollback: the prototype has no OTA
slot selection in code.

## 4. Procedure — start from a clean watch

Use this only when the filesystem or Preferences are corrupt, or when you
deliberately want an empty watch.

1. **Sync and back up first.** Follow §1; there is no way to recover rows after
   this procedure.
2. **Erase the flash** with PlatformIO's erase target (`pio run --target erase`)
   or the equivalent esptool command for your board. The erase target is part of
   PlatformIO, but it was **not run in this rewrite**; confirm the command
   against your PlatformIO version before using it on hardware you care about.
3. **Re-flash.** `pio run --target upload`. You should see a successful upload
   and, on the next boot, a **new** six-digit PIN because Preferences is empty.
4. **Update the phone.** The old PIN will fail. Enter the new one; the app
   replaces the stored PIN only after `paired` comes back true.
5. **Expect an empty history.** The Storage screen should show `Rows today: 0`
   until the clock is set and a sample qualifies.

## 5. Procedure — roll back

1. **App:** uninstall the new build only if installing the old APK over it fails.
   Installing over keeps data; uninstalling does not. Then reinstall the APK you
   saved, and re-pair if secure storage was cleared.
2. **Firmware:** check out the older source or keep the older `firmware.bin`,
   then repeat §3 steps 1–4.
3. **Confirm the rollback.** The boot banner must show the older version string,
   and the app's Device diagnostics must show the same firmware version. If they
   disagree, you flashed one board and connected to another.
4. **Re-sync.** Rows written by the newer firmware use the same nine columns, so
   the older build can still read them. Nothing needs converting.

## 6. Data compatibility

The current firmware (`4.1.0`) and app use nine columns:
`unix,hr,spo2,sys,dia,hrv,steps,fall,bat`. The phone parser accepts eight or
more columns and treats a missing battery as `0` (`local_store.dart:38-52`), so
adding a tenth column later is safe as long as it is appended at the end. Do not
reorder columns: old rows would be silently misread.

Two format facts to remember when writing a migration:

- The watch names day files in **UTC**; the phone names them in **local** time.
  A migration that groups by file name will move rows across midnight.
- Dedupe is `line.startsWith('$unix,')`. Two different samples with the same
  timestamp cannot both be stored.

## 7. Protocol changes

The app and firmware share UUIDs copied by hand: `protocol.h` and
`veyro_protocol.dart`. Changing either without the other breaks pairing with
`Incomplete Veyro BLE service` or with commands that are accepted and ignored.

The rules that follow from the current code:

1. **Bump and check the version together.** The firmware sends `"v":1`; the app
   declares `version = 2` but never checks it. Before changing payloads, make the
   app reject a version it does not understand — otherwise a new firmware will
   be decoded with old assumptions and produce plausible wrong numbers.
2. **Add commands, do not rename them.** `pair`, `time`, `face`, `sync`, `next`
   and `prune` are matched by exact string. An unknown `op` is ignored without
   an error (`DigitalSaverWatch.ino:241-296`), so a typo looks like a dead watch.
3. **Never change the PIN rule.** Pairing is checked in two places: BLE Secure
   Connections with the static PIN, and the `pair` command body. Changing one
   leaves the other failing.
4. **The S3 target is not a v2 peer yet.** Its UUID constants match, but it
   registers no characteristics (`veyro_main.c:108-129`). Do not point the app
   at it expecting an upgrade path.
