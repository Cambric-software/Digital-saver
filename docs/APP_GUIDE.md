# App — Digital Saver

The Flutter app. Version `1.0.3+3`, displayed as `1.0.3-beta`
(`app/pubspec.yaml:4`, `app/lib/services/app_version.dart:28-46`). Android is the
working target; the web build serves a landing page, not the app, and desktop is
not a supported target.

The app is a viewer for a watch plus a local health diary. It stores what the
watch sends, draws it on twenty screens, and can ask an AI assistant about it.
The BLE contract is in [SYSTEM.md](SYSTEM.md) §3; this page is about working
inside the app.

## Safety

1. **The app is not a medical device and does not diagnose.** Every value on
   screen is a wellness estimate. The assistant is told not to give a diagnosis,
   but a language model can still be wrong; treat its answer as text, not advice.
2. **No automatic emergency call is made.** The SOS button on the watch records
   an event. Emergency contacts are stored for the reader to dial, not dialled
   by the app.
3. **Demo mode fabricates numbers.** `startDemo()` produces 68–75 bpm and 97%
   SpO₂ on a timer (`ble_service.dart:417-427`). Never show a demo screen to
   someone who thinks it is their own reading.
4. **The AI conversation leaves the phone.** See §7 before enabling it with real
   health data.
5. **A reinstall can delete 60 days of history.** There is no cloud backup.

## 1. What the app does

| Area | Behaviour |
|---|---|
| Pairing | Scans for BLE devices, connects, sends the six-digit watch PIN, then syncs |
| Live | Decodes one JSON notification per second into HR, SpO₂, HRV, steps, fall, battery |
| History | Pulls `/d/YYYYMMDD.csv` rows one at a time, dedupes by timestamp, keeps 60 days |
| Screens | 20 screens (the lock is one of them) plus a web landing page |
| Assistant | Gemini with health context; offline template answers when the request fails |
| Updates | Polls GitHub releases, verifies a published SHA-256, hands off to the OS installer |
| Storage | Local CSVs and preferences; only the watch PIN is in secure storage |

It does **not** measure blood pressure (`0/0` from the watch, shown as N/A), does
not work without a watch except in demo mode, and does not upload history.

## 2. Procedure — run the app from source

Run each command in `app/`. You need Flutter with an Android toolchain;
`flutter doctor` should show Flutter and the Android toolchain green.

1. **Fetch packages.** `flutter pub get`. You should see `Got dependencies!`.
2. **Check for errors.** `flutter analyze lib test`. Every line should be `info`
   or `warning`; there must be no `error`. On 2026-10-21 the result was
   `14 issues found` — 2 warnings, 12 infos, no errors — and the command exits 1
   because issues exist. Info-level lints are not a reason to stop; an error is.
3. **Run the tests.** `flutter test`. You should see
   `All tests passed!` — 346 on the verified run.
4. **Start on a phone or emulator.** `flutter run`. You should see the splash,
   then either the lock screen or Today. An emulator has no Bluetooth: scanning
   will report that Bluetooth is off, which is correct there.
5. **Build a release APK.** `flutter build apk --release`. You should get
   `build/app/outputs/flutter-apk/app-release.apk`.
6. **Record the hash.** `Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256`
   (Windows) or `sha256sum` elsewhere. You should get one 64-character digest;
   publish it with the APK so a download can be checked.

To compile in a Gemini key, add `--dart-define=GEMINI_API_KEY=...` to step 4 or
5. Without it the app uses the compiled-in relay described in §7.

## 3. Structure

```
app/lib/   main.dart, models/, services/, screens/, widgets/
app/test/  interaction/ (74), screens/, services/, support/app_harness.dart
```

Providers are set up once in `main.dart:31-40`:

| Provider | Supplies |
|---|---|
| `BleService` | connection state, live values, sync progress, demo mode |
| `AppLock` | app PIN, watch PIN in secure storage, lock state |
| `ThemeService` | light/dark themes, theme mode |
| `LocaleService` | locale and text direction |
| `AutoUpdateService` | release check, download, manual-install hand-off |
| `HeartRateTracker` | session min/max/average heart rate |

Screens read these with `context.watch`/`context.read`. A screen must not create
its own `BleService`; a second instance would show a disconnected watch while
the real one is connected.

`home` is `WebLandingPage` on web, and `LockGate → _UpdateWrapper →
EnhancedSplashScreen` everywhere else (`main.dart:96-116`). The update dialog
appears four seconds after start if a newer release is known
(`main.dart:130-141`).

## 4. Screens

All twenty are reachable. The bottom bar holds Today, Vitals, Insights, Coach
and More; More lists every destination the bar cannot hold, and the rail appears
at 1100 px and up (`ROADMAP.md` 3.1a).

| Screen | What it is for |
|---|---|
| Today (`dashboard_screen`) | Summary: current HR, steps, battery, quick actions, recent state |
| Vitals (`vitals_screen`, `heart_screen`) | HR, SpO₂, HRV, temperature slot, status; heart detail with pulse ring and session range |
| Activity and sleep (`activity_screen`, `sleep_screen`) | Steps and hourly activity; sleep derived from history, empty when there is none |
| Insights (`insights_screen`, `health_trends_screen`, `health_tips_screen`) | Trends, guidance, progress, longer-range charts and static tips |
| Health hub (`health_hub_screen`, `bp_screen`, `fitness_tools_screen`, `lifestyle_tools_screen`, `wellness_tools_screen`, `achievements_screen`) | Door to the tool suites, BP explanation (N/A), fitness/lifestyle/wellness helpers, milestones |
| Memory and device (`memory_screen`, `device_diagnostics_screen`, `watch_simulator_screen`) | Sync and stored rows; connection/firmware/sample/free-space; eight watch faces without hardware |
| Settings and assistant (`settings_screen`, `ai_assistant_screen`) | Profile, pairing, lock, contacts, theme, updates; the Gemini chat |
| Lock (`lock_screen`) | App PIN gate, shown before the splash content |

Screens with no data show an empty state naming what is missing rather than
invented numbers (`ROADMAP.md` 3.1). A zero reading always renders as `--`
(`ROADMAP.md`, standing rules).

## 5. BLE behaviour, app side

The wire contract is in [SYSTEM.md](SYSTEM.md) §3. The app's side:

1. **Scan** requests Bluetooth scan/connect and location permission, refuses to
   scan with the adapter off, and runs a 20-second scan
   (`ble_service.dart:103-156`). A device is marked Veyro if its name contains
   “veyro” or it advertises the Veyro service prefix.
2. **Connect** has a 20-second timeout, then discovers services
   (`ble_service.dart:164-187`).
3. **Wire** subscribes to live and history, reads info, and locates the command
   characteristic. It throws `Incomplete Veyro BLE service` unless all five
   exist (`ble_service.dart:189-243`).
4. **Pair** is automatic when a PIN is already saved, otherwise the user types
   the six digits from the watch (`ble_service.dart:244-286`). On success the
   app saves the PIN to secure storage, sends the time, and starts sync.
5. **Sync** sends `sync`, stores each row, and acknowledges with `next` until
   `done` (`ble_service.dart:288-294, 361-381`). Progress is `syncingMemory` and
   `memoryRows`.
6. **Disconnect** clears subscriptions, command handles and sync progress
   (`ble_service.dart:383-415`). The watch forgets the pairing on its side, so a
   reconnect re-sends the saved PIN.

The app never negotiates an MTU and never checks the protocol version byte. Both
are gaps, recorded in [SYSTEM.md](SYSTEM.md) §6, not features.

## 6. Storage

History lives in `<application support>/veyro/days/YYYYMMDD.csv`, named by the
**local** date, with the same nine columns the watch writes. Reads dedupe by
timestamp prefix; the store prunes files older than 60 days. Profile and
emergency contacts are JSON in `SharedPreferences`; the watch PIN is in
`flutter_secure_storage`. Full detail and file/line citations are in
[SYSTEM.md](SYSTEM.md) §4.

Two traps when debugging “missing” data:

- The watch names files by UTC day and the phone by local day, so the file
  names differ by one around midnight.
- Nothing is stored until the watch clock has been set by the `time` command.
  A watch that has never paired writes nothing at all.

## 7. The assistant

`gemini_service.dart` is the only network code path that carries health data.

| Fact | Value |
|---|---|
| Primary model | `gemini-3.8-flash` |
| Fallbacks, in order | `gemini-2.5-flash`, `gemini-1.5-flash` (the last is legacy) |
| Endpoint with a key | `https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent` |
| Endpoint without a key | The compiled-in Cloudflare Worker URL `https://digital-saver-ai.asser-k-dev.workers.dev` |
| Key source | `--dart-define=GEMINI_API_KEY=...`, compiled in; there is no in-app key field |
| Sampling | temperature 0.7, topP 0.9, max 1024 output tokens |
| History window | `_maxHistoryTurns * 2` turns, oldest removed |
| On failure | `_offlineHealthAdvisor` local template answer |

The health context sent with a question includes the profile (name, age, gender,
BMI, conditions, medications) and current health values
(`gemini_service.dart:298-340`). The Worker URL is non-empty, so “no key” does
not mean “no network”: the request goes to the Worker, and only a failed request
falls back to local text. The old manual's “works with or without a key, locally”
is wrong.

## 8. Tests

| Command (in `app/`) | Verified result, 2026-10-21 |
|---|---|
| `flutter test` | 346 passed |
| `flutter test test/interaction` | 74 passed |
| `flutter analyze lib test` | 14 issues, 0 errors (2 warnings, 12 infos) |

The interaction suite drives controls at 390×844 and 1440×900 through one
harness, `test/support/app_harness.dart`, and asserts against the service or
store that owns each effect. [INTERACTION-TESTS.md](INTERACTION-TESTS.md) lists
what is covered and what cannot honestly be driven in a widget test.

## 9. Limits

- **Bluetooth cannot be tested in the suite.** No test connects to a real watch;
  BLE paths are exercised with fakes and the demo timer.
- **The build is not warning-free.** Two analyzer warnings and twelve infos
  remain. They are not errors, and this document does not claim a clean
  analyzer.
- **Web is a landing page, not the app.** `kIsWeb` returns `WebLandingPage`, and
  storage calls return early on web because there is no application-support
  directory.
- **The update download is not covered by tests.** The OS installer hand-off is
  platform code that a widget test cannot complete.
- **The protocol version constant is dead code.** `VeyroProtocol.version = 2`
  is never read; the wire format is v1.

## 10. Troubleshooting

| You see | Cause | Do this |
|---|---|---|
| `Turn Bluetooth on` | Adapter off, or an emulator | Use a real phone |
| `Incomplete Veyro BLE service` | Watch firmware lacks a characteristic, or is the S3 target | Flash the ESP32 prototype build |
| Scan list empty | Permission denied, or watch not advertising | Grant “Nearby devices”; reboot the watch; move within 2 m |
| `Wrong PIN` | Digits do not match the watch | Read the six digits from the OLED; the PIN persists across reboots |
| Sync stuck at 0 rows | Clock never set, or no sample qualifies | Pair again (sends `time`), then leave the watch running for a few minutes |
| Screens blank after sync | Store pruned or app data cleared | Check the Memory screen's row count before assuming the watch lost data |
| Assistant answers in templates | Worker or Gemini request failed | Check connectivity; a missing key is not the only cause |
| `flutter run` fails with a Gradle error | Toolchain mismatch | Run `flutter doctor`, fix the Android toolchain, then `flutter clean` |
