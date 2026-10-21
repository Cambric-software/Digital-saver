# Interaction tests

Phase 3.2 drives the controls on the rebuilt screens at the two design widths,
390×844 and 1440×900, and asserts what each control changed. Rendering alone was
already covered by the capture harness; this suite is about behaviour. Controls
that a widget test cannot honestly drive are listed under “Not exercised, and
why” instead of being claimed as covered.

## Running it

From `app/`:

```powershell
C:\src\flutter\bin\flutter.bat test test\interaction
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat analyze lib test
```

Current results (2026-10-21):

| Command | Result |
| --- | --- |
| `flutter test test\interaction` | **74 passed** |
| `flutter test` | **346 passed** |
| `flutter analyze lib test` | **0 errors**; 14 pre-existing infos/warnings, none in the new tests or new code |

The 346 total includes the 74 interaction tests, the 41 capture tests and the
rest of the existing suite. The pre-interaction baseline was 272; the harness in
this phase added 74.

## The rig

`test/support/app_harness.dart` supplies:

- `appHarness(child, {embedded})` — the providers `main.dart` supplies, the real
  light theme and a `Scaffold`. `embedded: true` adds the `DsPage` that a Vitals
  or Insights tab body gets from its host.
- `pumpScreen(tester, child, {size})` — sets the viewport, tears down any previous
  tree, renders `child` and calls `settleLoads`. The tear-down matters: pumping
  the same widget type twice otherwise reuses the providers and `State`, and a
  "reopen the screen" assertion would be made against widgets the test never
  left.
- `settleLoads(tester)` — six 120 ms pumps interleaved with short
  `runAsync` turns. The real-event-loop turns are what let `path_provider` report
  that it has no application-support directory; without them every history
  screen stays on its spinner under the fake clock.
- `buttonWithText`, `cardWithText`, `inCard`, `buttonInCard`, `sectionWithText`,
  `inSection`, `buttonInSection`, `serviceOf`, `scrollTo`, `enterByLabel` and
  `chooseFromDropdown`.

Each test file calls `SharedPreferences.setMockInitialValues({})` in `setUp`.
Timers are pumped by fixed durations, never `pumpAndSettle` while a progress
indicator is on screen. Tests that start demo BLE data call `stopDemo()` and
replace the tree with `SizedBox.shrink()` before ending.

## Coverage by screen

Every test below runs twice, once at each width. The test-name column is the
description used by `flutter test`.

### Today / dashboard

| Control | Effect asserted | Test |
| --- | --- | --- |
| Data-source icon (`sensors_rounded`) | Switches the demo source on: `Watch connected` and `76%` appear | `data-source button switches modes and BP tile navigates` |
| Data-source icon (`science_outlined`) | Switches back: `No watch connected` | same |
| Blood-pressure metric tile | Pushes a screen whose unique heading is `What the bands are` | same |
| Quick action `Log water` | Increments `DailyLog.hydrationGlasses` to 1 and shows `1 glass today.` | `quick actions log water and open both tools` |
| Quick action `Breathe` | Opens `Box breathing`; `pageBack` returns | same |
| Quick action `Log mood` | Opens `Mood and energy`; `pageBack` returns | same |
| Card `Pull watch memory` | Disabled (`onTap == null`) with `Connect the watch to pull its memory.` | same |

### Vitals

| Control | Effect asserted | Test |
| --- | --- | --- |
| Heart & HRV segment | Body shows `Heart rate variability` | `all four tabs render their own body` |
| `Motion` segment | Body shows `Steps by hour` | same |
| `Sleep & HRV` segment | Body loads history and reports `Stored history could not be read` | same |
| `Sensors` segment | Body shows `MAX30102 Optical PPG` and `MPU6050 6-axis IMU` | same |

### Heart

| Control | Effect asserted | Test |
| --- | --- | --- |
| None — body only | Loads as a Vitals tab and renders `Heart rate variability`, `Heart rhythm` and `Training zones` | `body renders its four panels` |

### Activity

| Control | Effect asserted | Test |
| --- | --- | --- |
| None — body only | Renders `Steps`, `Daily goals` and `Fall detection active` | `body renders its five panels` |

### Sleep

| Control | Effect asserted | Test |
| --- | --- | --- |
| None — body only | Unreadable store shows `Stored history could not be read`, and no invented stage data | `body says what is missing rather than inventing a night` |

### Insights

| Control | Effect asserted | Test |
| --- | --- | --- |
| `Trends` segment | Body shows `Health trends` | `all three segments render their own body` |
| `Guidance` segment | Body shows `Reading guidance` | same |
| `Progress` segment | Body shows `Milestones` | same |

### Health hub

| Control | Effect asserted | Test |
| --- | --- | --- |
| `Wellness` card | Opens `Wellness tools` | `every suite card opens its own screen` |
| `Fitness` card | Opens `Fitness tools` | same |
| `Lifestyle` card | Opens `Lifestyle tools` | same |
| `Device & sensors` card | Opens `Device diagnostics` | same |
| `Blood pressure` card | Opens the BP screen (`What the bands are`) | same |
| `Watch simulator` card | Opens the simulator (`Preview only`) | same |
| Reflection field + `Save` | Writes `StorageService.todayReflection`, shows `Reflection saved`, and a fresh screen reads the note back | `a reflection is saved and read back` |
| `Wash your hands` Start/Pause/Reset | 00:20 → 00:19, frozen while paused, back to 00:20 | `all four countdowns and three stopwatches run and stop` |
| `Brush your teeth` Start/Pause/Reset | 02:00 → 01:59, frozen, reset | same |
| `Eye break (20-20-20)` Start/Pause/Reset | 00:20 → 00:19, frozen, reset | same |
| `Focused work` Start/Pause/Reset | 25:00 → 24:59, frozen, reset | same |
| `Morning light` Start/Pause/Reset | 00:00 → 00:01, frozen, reset | same |
| `Cold exposure` Start/Pause/Reset | 00:00 → 00:01, frozen, reset | same |
| `Breath hold` Record | Disabled before a hold; after 2 s, records `StorageService.breathHoldBest() == 2` and shows `New longest hold: 2s` | same |
| `Breath hold` Start/Reset | Counts up and returns to 00:00 | same |

### Blood pressure

| Control | Effect asserted | Test |
| --- | --- | --- |
| None | The screen has no `ButtonStyleButton`, so there is no dead control; it states `No watch is connected, so there is nothing to show.` and prints no invented reading | `states why there is no reading and has no dead controls` |

### Health trends

| Control | Effect asserted | Test |
| --- | --- | --- |
| `24 hours` segment | Readings in window drops from 2 to 1 | `period segments change the window and reload is live` |
| `30 days` segment | Readings in window becomes 3 | same |
| `All kept` segment | Readings in window becomes 4 | same |
| `7 days` segment | Readings in window returns to 2 | same |
| Reload icon | Shows `Reading stored history…`, then the unreadable-store state because the harness has no filesystem | same |

### Health guidance

| Control | Effect asserted | Test |
| --- | --- | --- |
| Reload icon | Loads, shows `Reading stored history…`, then `Stored history could not be read` | `reload runs the stored read and reports its failure` |

### Achievements

| Control | Effect asserted | Test |
| --- | --- | --- |
| Reload icon | Shows `Counting stored samples…`, then the unreadable-store state | `reload runs the stored count and reports its failure` |

### Fitness tools

| Control | Effect asserted | Test |
| --- | --- | --- |
| `Add one` → `Cancel` | Dialog closes; `StorageService.medications()` stays empty | `medication can be cancelled, added, edited and removed` |
| `Add one` → name/dose → `Save` | Snackbar, row appears, one medication stored | same |
| Edit tooltip → rename → `Save` | Row and stored name change | same |
| Remove tooltip | Row disappears, store is empty, `Nothing on the list yet` | same |
| `Running` activity | Selected activity drives the session | `workout session and effort survive the next rebuild` |
| Session `Start` | Timer shows 00:02 after two seconds | same |
| Session `Save session` | Writes `LAST SAVED SESSION` and `Running · 00:02`; energy note explains the missing weight | same |
| Session `Reset` | Timer returns to 00:00 | same |
| RPE slider | Drag reaches `RPE 10 / 10` | same |
| Rating note + `Save today's rating` | `DailyLog.rpe == 10` and the note survives a fresh open | same |
| `Record resting rate` | In demo mode records a rate and starts the two-minute wait | `recovery test reads demo rates and stops its timers` |
| `Two-minute wait` Start/Pause | 01:59 after one second; still 01:59 after another second while paused | same |
| `Cancel test` | Returns to `Record resting rate` | same |
| Two-minute wait completion | Shows `TWO MINUTES LATER` and `Start a new test` | same |
| `Start a new test` | Returns to the resting-rate control | same |
| Stored profile | 30 y / 70 kg / 170 cm gives max 190, zone 95–114 and the 70 kg calorie note; demo live rate reads `Below zone 1` | `a stored profile drives the zones and the calorie note` |

### Lifestyle tools

| Control | Effect asserted | Test |
| --- | --- | --- |
| `14:10` plan | `Target: 14 hours.`; `DailyLog.fastingPlan()` is 14:10 | `fasting plan, fast and mood entry are stored` |
| `Start fast` / `End fast` | Running state, then `Not started` and a cleared start time | same |
| `Save today` | Disabled until a mood is chosen; reason stated as `Nothing saved for today yet.` | same |
| Mood `Good` | Selected mood shown | same |
| `Slept well` / `Busy day` chips | Tags stored as `Busy day, Slept well` and restored as selected | same |
| Energy slider | Reaches 10 / 10 and stores it | same |
| `Save today` with mood | Snackbar, `Saved today: Good · energy 10/10`, and a fresh open reads it back | same |
| `Save these numbers to my profile` with blanks | Shows the age-range error and does not save | `BMR rejects bad numbers and saves the good ones` |
| Age/Weight/Height fields | 30 / 70 / 175 yields BMR 1,649 and TDEE 2,267 | same |
| `Female (−161)` | Recomputes BMR 1,483 and TDEE 2,039 | same |
| `Moderate` | Recomputes TDEE 2,298 | same |
| Save to profile | Writes `LocalStore` profile (age 30, 70 kg, 175 cm) | same |
| Stand-up `Start` + 30 min | `Time to move` dialog appears | `the break dialog both declines and logs a break` |
| Dialog `Not now` | No break counted; dialog closes | same |
| `Start again` then `Start` + 30 min, dialog `Done` | Break count becomes 1 in the UI and `DailyLog.breaks` | same |

### Wellness tools

| Control | Effect asserted | Test |
| --- | --- | --- |
| Hydration `Add a glass` ×3 | 3 of 8 glasses, 750 ml, `DailyLog.hydrationGlasses == 3` | `water and coffee counters add, remove and reset` |
| Hydration `Remove one` | 2 glasses, store 2 | same |
| Hydration `Reset today` | 0 glasses, store 0 | same |
| Hydration `Remove one` / `Reset today` when empty | Both disabled with the empty state | same |
| Caffeine `Log one` ×2 | 2 coffees and teas, `Last at …`, store 2 | same |
| Caffeine `Reset today` | 0 coffees, store 0 | same |
| `Add details` → `Cancel` | Dialog closes, `No emergency details yet` remains | `emergency card cancels, saves, reloads and edits` |
| Emergency fields + `Save` | Blood type/contact/allergies/notes stored and shown | same |
| Reopen screen | Saved card is read from storage | same |
| `Edit details` | Changes blood type to AB+ and leaves O+ absent | same |
| Box breathing `Start` | 00:16 → 00:12 after four seconds and `Phase 2 of 4` | `breathing, rest and stride controls tick and save` |
| Box breathing `Pause` | Stops at 00:12 | same |
| Box breathing `Reset` | Returns to 00:16 | same |
| `30 s` + rest `Start`/`Pause`/`Reset` | 00:30 → 00:27, paused, reset | same |
| Stride slider | `120 cm per step`, stored, and restored on reopen | same |

### Watch memory

| Control | Effect asserted | Test |
| --- | --- | --- |
| Failing loader → `Try again` | Error card `Stored samples could not be read`; retry re-runs the loader and shows `No samples yet` | `an unreadable log offers retry, and reload asks again` |
| Pull control with no watch | Disabled with `Pull is disabled until a watch is connected…` | same |
| Reload icon | Re-runs the loader (call count rises) | same |
| Injected two-row log | Sample count 2, averages 73 / 62 / 96, fall flags 0, analyzer notes and retention date shown | `a stored log shows measured averages and the pull reports` |
| Pull with demo watch | Finishes with `The pull finished. The watch had no new rows to copy.`; no progress bar left behind; control re-enabled | same |

### Device diagnostics

| Control | Effect asserted | Test |
| --- | --- | --- |
| Face segment `8` while disconnected | Label becomes `Send face 8`; the choice is not stored yet | `face choice is kept while disconnected and sent when paired` |
| `Send face 8` while disconnected | Disabled, with `Connect and pair a watch to send a face…` | same |
| Demo source | Connection pill reads `Demo` and the generated-data note appears | same |
| `Send face 8` with a paired source | Snackbar `Face 8 saved and sent to the watch.`; `StorageService.watchFace() == 7` | same |
| Reopen screen | Face 8 is read from storage while the watch is absent | same |

### Watch simulator

| Control | Effect asserted | Test |
| --- | --- | --- |
| `Digital` segment | `10:10`, `TUE 20 OCT`, `72 bpm`, `8,420`, `SAMPLE` | `all three previews are selectable and labelled as samples` |
| `Rings` segment | `steps · sample` and `8,420`; the digital face is gone | same |
| `Analog` segment | No sample text from the other two faces | same |

### Settings

Settings is split into six tests so a failure names its section.

| Control | Effect asserted | Test |
| --- | --- | --- |
| `Dark theme` switch | `ThemeService.themeModeType == AppThemeMode.dark`; switch shows true | `theme, language and sync switches save where they belong` |
| `Dim after dark` switch on | `StorageService.dimAfterDark() == true`; subtitle states the 20:00–07:00 window | same |
| `Dim after dark` switch off | Preference false; boundary timer cancelled | same |
| `App language` dropdown | `LocaleService.currentLanguage == 'العربية'` | same |
| `Remember auto-sync choice` | `StorageService.autoSyncHistory() == false` | same |
| `Demo mode` switch | Preference true and the switch reflects it | same |
| `Active watch face` dropdown | `StorageService.watchFace() == 2` | `face, complications and thresholds save and reload` |
| `Top slot` dropdown | `StorageService.complicationTop() == 'Battery Level'` | same |
| `Bottom slot` dropdown | `StorageService.complicationBottom() == 'None'` | same |
| High heart-rate slider | Dragged to max: `Saved at 180 BPM or above.`, store 180 | same |
| Low oxygen slider | Dragged to min: `Saved at 80% or below.`, store 80 | same |
| Reopen screen | All five choices and both sliders read back from storage | same |
| `Save profile` with a blank name | Inline name error, nothing saved | `profile and contact forms validate, persist and remove` |
| Name/Age/Weight + save | Snackbar; `LocalStore.loadProfile()` has Sam, 30, 72.5 kg | same |
| `Add contact` with blanks | Inline `A contact needs a name and a phone number.` | same |
| Contact name/phone/relation + save | Snackbar; `LocalStore.loadContacts()` has Alex, 555 0100, Sister | same |
| Reopen screen | `Sam`, `Alex` and the phone are read back from `LocalStore` | same |
| Remove-contact tooltip | Snackbar, empty store, `No emergency contacts yet…` | same |
| Delete reply when only one exists | Disabled (`onPressed == null`) with `Keep at least one reply` and the stated reason | `quick replies validate, add, remove and keep one` |
| `Add a reply` → `Add` empty | `Write something first.` | same |
| `Add a reply` → `Cancel` | No reply added | same |
| `Add a reply` → text → `Add` | Stored list grows; snackbar | same |
| Remove one of two replies | Stored list shrinks to the kept reply; the last one is disabled again | same |
| `Set a 6-digit PIN` → short / mismatched | `Use exactly 6 digits, 0 to 9.` and `The two new PINs do not match.`; no hash written | `the PIN dialog validates, cancels, then sets a PIN` |
| PIN dialog `Cancel` | `AppLock.hasLock` stays false | same |
| Valid PIN + `Set PIN` | Dialog closes, success snackbar, `hasLock == true`, `PIN set` card appears | same |
| `Change PIN` / `Remove PIN` dialogs | Open with the current-PIN field / removal explanation and cancel cleanly | same |
| `Lock now` | `AppLock.unlocked == false` | same |
| `View CSV` / `View JSON` | Report `Stored samples could not be read:` rather than inventing rows; no dialog | `CSV and JSON read the stored log and report the failure` |

### Digital Saver AI

| Control | Effect asserted | Test |
| --- | --- | --- |
| Composer + send icon | Message bubble appears and the offline advisor answers `Normal resting heart rate…`; the thinking row stops | `chat sends, a quick chip sends, and clear resets the log` |
| `Explain my sleep quality` chip | Sends the chip question and answers `7 to 9 hours` | same |
| `Clear Chat` icon | Conversation replaced by `Chat history cleared…`; greeting and answers gone; chip row remains | same |
| `Tone of Voice` dropdown | Selected tone survives the save and a fresh open | `personality settings save and are read back` |
| `Primary Health Focus` dropdown | Selected focus survives | same |
| `Conversation Language` dropdown | Selected language survives | same |
| Watch-telemetry switch | Turns off and `ai_include_telemetry` is false after save | same |
| Custom notes field | `ai_custom_instructions` saved and restored in the field | same |
| `Save Personality & Instructions` | Snackbar `AI Personality & Instructions Saved!`; all six preferences read back from `SharedPreferences` | same |

### App lock

| Control | Effect asserted | Test |
| --- | --- | --- |
| `LockGate` with no PIN | Shows the app content (nothing is hidden by a lock that was never set) | `the gate refuses a short and a wrong PIN, then opens` |
| `LockGate` with a set PIN + `lockNow` | Hides `app content`, shows `Digital Saver is locked` | same |
| PIN field + `Unlock`, fewer than six digits | `The PIN is six digits.`; content stays hidden | same |
| PIN field + `Unlock`, wrong six digits | `That PIN is not right.`; field cleared; content stays hidden | same |
| PIN field + `Unlock`, correct PIN | Content appears and `AppLock.unlocked == true` | same |

## Findings and fixes

| Where | Finding | Fix | Covered by |
| --- | --- | --- | --- |
| Today | The data-source `IconButton` did nothing. It looked like the way to switch between live and sample readings. | Wired to `ble.demoMode ? ble.stopDemo() : ble.startDemo()` | `data-source button switches modes and BP tile navigates` |
| Sleep | A failed history read left the spinner up forever. | `_load` now catches, and `_UnreadableHistory` says `Stored history could not be read` with a retry. | `body says what is missing rather than inventing a night` |
| Wellness tools | The emergency-card dialog disposed its `TextEditingController`s as soon as `showDialog` returned, throwing "used after being disposed" during the exit animation. | The dialog is a `_IceDialog` `StatefulWidget` that owns and disposes its controllers, mirroring `_MedicationDialog`. | `emergency card cancels, saves, reloads and edits` |
| Digital Saver AI | At 390 px the three settings dropdowns overflowed their field by 140 px, 101 px and 165 px, clipping the selected label. | Added `isExpanded: true` and `TextOverflow.ellipsis` to the three `DropdownButtonFormField`s, matching Settings. | `personality settings save and are read back` |
| Test harness | `pumpScreen` rendered the same widget type again without clearing the tree, so providers and `State` were reused; "reopen the screen" tests were not actually reopening it. | `pumpScreen` pumps `SizedBox.shrink()` before the real tree. | The reload assertions in the health, tools, AI and settings tests |

## Not exercised, and why

These are controls that exist but were deliberately not driven, or paths that a
widget test cannot reach. None of them is asserted to work elsewhere in this
document, and none is counted in the tables above as covered.

| Screen / control | Why not |
| --- | --- |
| Settings — `Scan for Veyro` | Calls `FlutterBluePlus.startScan`, which needs platform BLE channels and permission handling. A widget test can only observe `MissingPluginException`, not a scan. The service's state machine is covered by its own unit tests. |
| Settings — `Check for updates`, `Download and verify update` | Performs a real HTTP GET against the GitHub releases feed. `AutoUpdateService` is covered in `test/services/update_system_test.dart`; the widget test must not make a network request. |
| Settings — CSV/JSON success dialogs | Reaching them needs `LocalStore.loadAll()`, which requires `path_provider`'s application-support directory. Widget tests have none, so the agents assert the honest error snackbar instead of fabricating a store. |
| Settings — confirming `Change PIN` / `Remove PIN` | Both verify the current PIN, which costs a 120,000-iteration PBKDF2 (~1.5 s) per call. The dialogs are opened and cancelled; the verify, throttle and clear paths are covered by `test/services/security_test.dart`, and the set path is covered here at both widths. |
| Settings — dark theme paint | `ThemeService.setTheme` is in-memory, and the test harness pins `AppTheme.light` on `MaterialApp`, so the suite asserts the service and switch state, not repainted colours. `theme_service_test.dart` covers theme selection. |
| Lock — the five-wrong-tries / 30 s lockout | Driving it in the UI costs five hashes plus a wall-clock wait, contradicting the "keep lock tests few" rule. `security_test.dart` covers the throttle with the service injected. |
| Memory — a pull that copies rows | Demo mode has no command characteristic, so `startMemorySync` correctly reports "no new rows". The row-copy path belongs to `BleService` and the protocol; the screen's success branch for rows > 0 is not reachable in a widget test. |
| Device diagnostics — real pairing | There is no platform BLE device in the harness. The test uses `BleService.startDemo()` and asserts the demo copy and the disabled disconnected states. |
| AI — a real Gemini/relay answer | `flutter_test`'s HTTP client returns 400 for every request. The test asserts the app's deterministic offline fallback, which is the same path a person gets with no relay. |
| Dashboard — `Pull watch memory` | It has no handler by design without a connected watch. The test asserts it is disabled and states the reason; it is not a dead control that was removed. |
| Heart / Activity / Sleep / Blood pressure | Bodies with no controls of their own (or, for BP, no controls at all). They are covered through their host or through the navigation that opens them. |

## Reachability at 390 px

No control was unreachable at 390 px after the AI dropdown fix. Three rows need
a horizontal scroll and the tests perform it:

- The eight watch-face segments in Device diagnostics scroll horizontally; `8`
  is reached with `ensureVisible` before tapping.
- The AI quick-prompt chips scroll horizontally; the second chip is revealed by
  dragging the chip row before tapping.
- The Vitals and Insights segments scroll horizontally when their labels do not
  fit; the tests scroll each option into view first.

The AI dropdown overflow was a real clipping defect, not merely a control that
needed scrolling; it is fixed in `lib/screens/ai_assistant_screen.dart`.
