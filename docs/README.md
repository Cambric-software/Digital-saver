# Digital Saver / Veyro documentation

Everything except the root `README.md`, `SECURITY.md` and `LICENSE` lives here.
Read the document that matches what you are doing.

## Plan

| Document | Read it when |
|---|---|
| [ROADMAP.md](ROADMAP.md) | You are deciding what to build next. Ordered and authoritative; shared with Max Tools. |

## Build the hardware

| Document | Read it when |
|---|---|
| [HARDWARE.md](HARDWARE.md) | You are buying parts, wiring the ESP32 bench prototype, or checking what the bench build still has to measure. Start here for the bench. |
| [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) | You are deciding or buying production hardware. It selects the architecture, sources the parts and prices 1,000 and 10,000 units. Start here for the product. |
| [11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md) | You need the 7,500 EGP commercial target and the acceptance gates. Its hardware sections are superseded by `HARDWARE_DESIGN.md`. |

## Firmware

| Document | Read it when |
|---|---|
| [FIRMWARE.md](FIRMWARE.md) | You are building, flashing or diagnosing either firmware target. **Start here for firmware.** |
| [FIRMWARE_FEATURES.md](FIRMWARE_FEATURES.md) | You need one page saying which prototype features are implemented and which are not. |
| [UPGRADE_GUIDE.md](UPGRADE_GUIDE.md) | You are changing firmware or app versions, or rolling a release back. |

## App and protocol

| Document | Read it when |
|---|---|
| [APP_GUIDE.md](APP_GUIDE.md) | You are working inside the Flutter app: entry point, providers, BLE, storage, screens. |
| [SYSTEM.md](SYSTEM.md) | You need the whole data path: watch storage, BLE contract, phone storage, security, build and release checks. |
| [INTERACTION-TESTS.md](INTERACTION-TESTS.md) | You are changing a screen and need to know which controls are covered by behaviour tests, and which are not. |

## Conventions

- Every procedure is numbered. Each step states what you should see when it
  worked; if you do not see it, stop at that step.
- Commands are copy-pasteable and name the directory they run in.
- `VERIFIED` means it was run or read on 2026-10-21. `UNKNOWN` means the
  repository does not establish the fact. `MUST MEASURE` means a bench
  measurement is still required. A gap is never filled with a plausible number.
- If two documents disagree, the source file wins: check `firmware/` or `app/`.
- One safety section per document; it is the part to read before powering
  anything.

## What was removed in Phase 4.2 (2026-10-21)

The ten numbered guides `01_*.md` … `10_*.md` were deleted. Each was a copy of
one template: the same Purpose, Scope, Evidence rules, Safety stop and
ten-stage checklist, with 860 `acceptance:` lines of which only 86 items were
distinct — every item was repeated once per stage. The checklist occupied
92–95% of each file. The surviving facts were moved into
[HARDWARE.md](HARDWARE.md), [SYSTEM.md](SYSTEM.md),
[FIRMWARE_FEATURES.md](FIRMWARE_FEATURES.md), [UPGRADE_GUIDE.md](UPGRADE_GUIDE.md)
and [APP_GUIDE.md](APP_GUIDE.md). `manual.md`, `MASTER_GUIDE.md`, `GUIDE.md` and
`company-manual.md` were folded in for the same reason: real procedure was
buried in placeholder text, broken links or a design that is now under
redesign.

| Deleted file | Lines | Acceptance lines / distinct | Facts kept |
|---|---:|---|---|
| `01_PRODUCT_VISION.md` | 941 | 860 / 86 | Wellness-not-medical boundary; prototype pin facts; flash workflow; eight screens |
| `02_SYSTEM_ARCHITECTURE.md` | 941 | 860 / 86 | Watch→BLE→phone data path; component boundaries |
| `03_OFFLINE_DATA.md` | 933 | 860 / 86 | LittleFS day files, CSV columns, 60-day retention, local-only storage |
| `04_BLE_PROTOCOL.md` | 935 | 860 / 86 | UUIDs; pairing-before-command rule; live/history/info payloads; `done` marker |
| `05_HARDWARE_BOM.md` | 942 | 860 / 86 | Bench parts; conditional TP4056 warning; protected-charger power path |
| `06_ASSEMBLY_SAFETY.md` | 954 | 860 / 86 | Wiring order, continuity checks, flash preparation |
| `07_FIRMWARE_GUIDE.md` | 963 | 860 / 86 | `esp32dev`, 921600/115200, boot banner, recovery, artifact hash |
| `08_APP_DEVELOPMENT.md` | 931 | 860 / 86 | Flutter setup, BLE permissions, scan/connect/pair, local storage |
| `09_TESTING_VALIDATION.md` | 954 | 860 / 86 | Test scopes; electrical/sensor/BLE/data checks |
| `10_RELEASE_MANUFACTURING.md` | 941 | 860 / 86 | Artifact hash, configuration record, release gates |

Git history keeps the deleted files. The audit numbers are reproducible from
that history; they are not repeated in the surviving guides.
