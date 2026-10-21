# Interaction tests

The behaviour suite behind Phase 3.2. It drives the controls on the rebuilt
screens at 390×844 and 1440×900 and asserts what each control changed in the
service or store that owns it — not just that a widget appeared. Rendering is
covered separately by the capture harness.

## Running it

From `app/`:

```powershell
flutter test test\interaction
flutter test
flutter analyze lib test
```

| Command | Result, 2026-10-21 |
|---|---|
| `flutter test test\interaction` | **74 passed** |
| `flutter test` | **346 passed** |
| `flutter analyze lib test` | **0 errors**; 14 issues total (2 warnings, 12 infos) |

The 346 total is the whole suite, interaction tests included. The baseline
before this phase was 272; the harness added 74.

## The rig

`test/support/app_harness.dart` supplies the providers `main.dart` supplies, the
real light theme, both viewports and the finders the suite needs.

- `pumpScreen` renders `SizedBox.shrink()` before the real tree. Without that,
  pumping the same widget type twice reuses providers and `State`, and a
  “reopen the screen” test is not testing a reopen.
- `settleLoads` interleaves six 120 ms pumps with real-event-loop turns so
  `path_provider` can report that no application-support directory exists.
  Without it every history screen stays on its spinner under the fake clock.
- Each test file calls `SharedPreferences.setMockInitialValues({})` in `setUp`.
- Tests that start demo BLE data call `stopDemo()` and replace the tree before
  ending, so the two-second demo timer cannot outlive the test.

## Coverage by screen

Every row below runs at both widths. “Test” is the `flutter test` name fragment.

| Screen | Controls driven and effects asserted |
|---|---|
| Today | Data-source icon toggles demo ↔ disconnected (`Watch connected`, `76%`, `No watch connected`); BP tile opens `What the bands are`; Log water → 1 glass; Breathe → `Box breathing`; Log mood → `Mood and energy`; Pull watch memory disabled with its reason |
| Vitals | Four segments render their own body: `Heart rate variability`, `Steps by hour`, `Stored history could not be read`, and the `MAX30102`/`MPU6050` sensor names |
| Heart | Body renders `Heart rate variability`, `Heart rhythm`, `Training zones` |
| Activity | Body renders `Steps`, `Daily goals`, `Fall detection active` |
| Sleep | Unreadable store shows `Stored history could not be read` and no invented stages |
| Insights | Three segments: `Health trends`, `Reading guidance`, `Milestones` |
| Health hub | Six cards open their screens (Wellness, Fitness, Lifestyle, Device diagnostics, BP, Watch simulator); reflection saves and reads back; four countdowns and three stopwatches start, pause, reset; `Breath hold` records a 2 s best |
| Blood pressure | No `ButtonStyleButton` exists, so no dead control; states `No watch is connected…` and prints no reading |
| Health trends | `24 hours`/`30 days`/`All kept`/`7 days` change the window count 2/1/3/4; reload runs and reports the unreadable store |
| Health guidance | Reload shows `Reading stored history…`, then `Stored history could not be read` |
| Achievements | Reload shows `Counting stored samples…`, then the unreadable-store state |
| Fitness tools | Medication add/cancel/edit/remove; workout start/save/reset and RPE; rating persists; recovery test runs the two-minute wait and cancel; stored profile (30 y, 70 kg, 170 cm) drives max 190 and zone 95–114 |
| Lifestyle tools | 14:10 plan, fast start/end, mood and energy save, tags restore; BMR rejects blanks, then 30/70/175 → 1,649, female → 1,483, moderate → 2,298; stand-up dialog declines and logs a break |
| Wellness tools | Water add/remove/reset and empty-state disabling; caffeine log/reset; emergency card cancel/save/reload/edit; box breathing, 30 s rest and stride slider |
| Watch memory | Unreadable log offers retry; pull disabled without a watch; reload re-runs the loader; injected two rows give count 2, averages 73/62/96; demo pull reports `no new rows` and re-enables |
| Device diagnostics | Face 8 is kept while disconnected and sent only when paired (`Face 8 saved and sent…`, stored as 7); demo pill reads `Demo`; reopen reads the saved face |
| Watch simulator | Digital (`10:10`, `72 bpm`, `8,420`), Rings and Analog previews switch and stay labelled as samples |
| Settings | Theme, dim-after-dark, language, auto-sync and demo switches save to the right service; face/complications/thresholds save and reload; profile and contacts validate, persist, remove; quick replies keep one; app PIN validates, cancels, sets, changes, removes, locks now; CSV/JSON report the read failure |
| Digital Saver AI | Send and chip questions answer from the offline advisor; clear empties the log; tone, focus, language, telemetry and custom notes save and read back |
| App lock | No PIN → content shows; locked → content hidden; short/wrong/correct PIN messages and unlock state |

## Findings and fixes

| Where | Finding | Fix |
|---|---|---|
| Today | The data-source `IconButton` did nothing, though it looked like the live/sample switch | Wired to `demoMode ? stopDemo() : startDemo()` |
| Sleep | A failed history read left the spinner up forever | `_load` catches, and `_UnreadableHistory` shows an error with retry |
| Wellness tools | The emergency dialog disposed its controllers as soon as `showDialog` returned, throwing during the exit animation | Dialog is a `StatefulWidget` that owns and disposes its controllers |
| Digital Saver AI | At 390 px the three settings dropdowns overflowed by 140/101/165 px | `isExpanded: true` and ellipsis on all three |
| Test harness | `pumpScreen` reused `State`, so “reopen” tests never reopened | It pumps `SizedBox.shrink()` first |

These are real defects the suite caught. The suite is not a formality.

## Not exercised, and why

Nothing below is counted as covered above.

| Control or path | Why not |
|---|---|
| Settings — `Scan for Veyro` | Needs platform BLE channels; a widget test only sees `MissingPluginException`. The state machine has unit tests |
| Settings — check/download update | Real HTTP against GitHub. `AutoUpdateService` is covered in `test/services/update_system_test.dart`; a widget test must not hit the network |
| Settings — CSV/JSON success dialogs | Need a real application-support directory, which widget tests do not have |
| Settings — confirm change/remove PIN | Verifying the current PIN costs a 120,000-round PBKDF2 (~1.5 s) per call. Open/cancel is tested; verify, throttle and clear are in `security_test.dart` |
| Settings — painted dark theme | The harness pins the light theme, so the test asserts service and switch state; `theme_service_test.dart` covers selection |
| Lock — five wrong tries / 30 s lockout | Would cost five hashes plus a wall-clock wait; covered in `security_test.dart` with the throttle injected |
| Memory — a pull that copies rows | Demo mode has no command characteristic; the row-copy path belongs to `BleService` |
| Device diagnostics — real pairing | No platform BLE device in the harness; demo mode and disabled states only |
| AI — a real Gemini or relay answer | `flutter_test` returns 400 for every HTTP request; the test asserts the deterministic offline fallback |
| Dashboard — `Pull watch memory` | Intentionally has no handler without a watch; the test asserts it is disabled and says why |
| Heart / Activity / Sleep / BP bodies | No controls of their own, or none at all; reached through their host |

## Reachability at 390 px

No control is unreachable after the AI dropdown fix. Three rows scroll
horizontally, and the tests scroll them into view before tapping: the eight
watch-face segments in Device diagnostics, the AI quick-prompt chips, and the
Vitals/Insights segment labels when they do not fit.
