# Digital Saver / Veyro documentation

Everything except the root `README.md`, `SECURITY.md` and `LICENSE` lives here.
Start with the section that matches what you are doing.

## Plan

| Document | Read it when |
|---|---|
| [ROADMAP.md](ROADMAP.md) | You are deciding what to build next. Authoritative and ordered; shared verbatim with Max Tools. |

## Build the hardware

| Document | Read it when |
|---|---|
| [manual.md](manual.md) | You are building the ESP32-WROOM-32 prototype on a bench, step by step. |
| [company-manual.md](company-manual.md) | You are producing the ESP32-S3 watch: design stages, tooling, assembly and QA gates. |
| [05_HARDWARE_BOM.md](05_HARDWARE_BOM.md) | You are ordering parts or checking a substitute. |
| [06_ASSEMBLY_SAFETY.md](06_ASSEMBLY_SAFETY.md) | You are soldering, wiring, or powering a board for the first time. |
| [11_PRODUCTION_WATCH_SPEC.md](11_PRODUCTION_WATCH_SPEC.md) | You need the production S3 specification and unit economics. |

## Firmware

| Document | Read it when |
|---|---|
| [07_FIRMWARE_GUIDE.md](07_FIRMWARE_GUIDE.md) | You are building, flashing or debugging either firmware target. |
| [FIRMWARE_FEATURES.md](FIRMWARE_FEATURES.md) | You need to know which prototype features exist, and which are proposed. |
| [UPGRADE_GUIDE.md](UPGRADE_GUIDE.md) | You are migrating firmware or app data, or rolling a release back. |

## App

| Document | Read it when |
|---|---|
| [08_APP_DEVELOPMENT.md](08_APP_DEVELOPMENT.md) | You are setting up and running the Flutter app. |
| [APP_GUIDE.md](APP_GUIDE.md) | You are working inside the app: entry point, providers, BLE, sync, storage. |
| [04_BLE_PROTOCOL.md](04_BLE_PROTOCOL.md) | You are changing the watch↔phone protocol. |

## System reference

| Document | Read it when |
|---|---|
| [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) | You need the product scope and its boundaries. |
| [02_SYSTEM_ARCHITECTURE.md](02_SYSTEM_ARCHITECTURE.md) | You need the component and data-flow map. |
| [03_OFFLINE_DATA.md](03_OFFLINE_DATA.md) | You are changing retention, storage layout or local export. |
| [MASTER_GUIDE.md](MASTER_GUIDE.md) | You want the condensed technical reference in one place. |
| [GUIDE.md](GUIDE.md) | You want the fastest path from a clean machine to a running bench setup. |

## Test and ship

| Document | Read it when |
|---|---|
| [09_TESTING_VALIDATION.md](09_TESTING_VALIDATION.md) | You are writing tests or validating a build. |
| [10_RELEASE_MANUFACTURING.md](10_RELEASE_MANUFACTURING.md) | You are cutting a release or running manufacturing acceptance. |

## Conventions

- Procedures are numbered steps. Each step states the answer, not just the
  action.
- Commands are copy-pasteable and name their working directory.
- Anything unverified is marked as unverified. Do not fill a gap with a guess.
- If two documents disagree, the number and the source file win: check the code.
