# Digital Saver / Veyro documentation

Everything except the root `README.md`, `SECURITY.md` and `LICENSE` lives here.
Read the document that matches what you are doing.

## Plan

| Document | Read it when |
|---|---|
| [ROADMAP.md](ROADMAP.md) | You are deciding what to build next. Ordered and authoritative for this repository; Max Tools keeps its own copy. |
| [PLAN.md](PLAN.md) | You need the Cambric-wide phase status rather than the product roadmap. |
| [ARCHITECTURE_STANDARD.md](ARCHITECTURE_STANDARD.md) | You are adding code and need the repository's layout rules. |

## Build the hardware

| Document | Read it when |
|---|---|
| [HARDWARE_DESIGN.md](HARDWARE_DESIGN.md) | You are deciding or buying production hardware. It compares compute options, sources the parts, prices 1,000 and 10,000 units, and lists the measurement gates. Start here for the product. |
| [VEYRO_DEMO_BOM.md](VEYRO_DEMO_BOM.md) | You need the sourced demo-unit BOM (~9,500 EGP). |

## Firmware

| Document | Read it when |
|---|---|
| [FIRMWARE_PLAN.md](FIRMWARE_PLAN.md) | You are planning the RV1106 firmware, or checking why the production target is not the ESP32-S3. |

## App

The companion app's source is `app/`. Its tests are the description of what it
does: `app/test/` holds model, service, screen and interaction tests, and
`app/test/screens/ui_capture_test.dart` renders every screen at a phone and a
laptop width. Run `flutter test` and `flutter analyze` in `app/` before
claiming a change works.

## Conventions

- Every procedure is numbered. Each step states what you should see when it
  worked; if you do not see it, stop at that step.
- Commands are copy-pasteable and name the directory they run in.
- `VERIFIED` means it was run or read, and the text gives the date and the
  command or source. `UNKNOWN` means the repository does not establish the fact.
  `MUST MEASURE` means a bench measurement is still required. A gap is never
  filled with a plausible number.
- If two documents disagree, the source file wins: check `firmware/` or `app/`.
- One safety section per document; it is the part to read before powering
  anything.

## Older guides

The ten numbered guides `01_*.md` … `10_*.md`, `manual.md`, `MASTER_GUIDE.md`,
`GUIDE.md` and `company-manual.md` were removed because they repeated one
template rather than describing the current product. Git history keeps them.
Facts that still hold are in the files listed above; facts that described the
superseded hardware are not carried forward as if they were current.
