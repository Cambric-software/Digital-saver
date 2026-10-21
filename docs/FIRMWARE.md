# Firmware

Two firmware targets exist in `firmware/`. They are not two versions of the
same thing: one is the bench prototype, the other is an unfinished production
target. This page says what each one actually does today, and separates what
was executed on 2026-10-21 from what was only read.

| | Prototype | Production target |
|---|---|---|
| Path | `firmware/esp32/DigitalSaverWatch` | `firmware/esp32s3` |
| Board | ESP32-WROOM-32 DevKit, 4 MB flash, no PSRAM | ESP32-S3, 16 MB flash, AMOLED |
| Framework | Arduino, PlatformIO env `esp32dev` | ESP-IDF + FreeRTOS + LVGL 8.3.11, env `esp32s3_watch` |
| Version | `4.1.0` (`VEYRO_FW_VERSION`) | `5.0.0` |
| Display | SSD1306 128×64 over I2C | 360×360 panel over SPI, LVGL |
| Sensors | MAX30102, MPU6050 | VC31B, QMI6858C in the code comment (the BOM says QMI8658CULT — unresolvable from the repo), BMP581, STTS22H, DRV2605L, BQ25895, FT6336G |
| Builds today | **Yes** | **No** |

## Safety

1. Do not flash while the watch is worn, and disconnect the LiPo before
   connecting USB on a bench build.
2. Never flash a board with a swollen, damaged or unprotected cell attached.
3. Read [HARDWARE.md](HARDWARE.md) before applying power for the first time;
   the power-path check there is a measurement, not an assumption.

## What was executed

Toolchain: PlatformIO Core `6.1.19`, platform `espressif32@6.8.1`.

| Command | Working directory | Result |
|---|---|---|
| `pio run` | `firmware/esp32/DigitalSaverWatch` | **SUCCESS**, 28.21 s on 2026-10-21 |
| `pio run` | `firmware/esp32s3` | **FAILED**, 50.60 s: `'I2C_NUM_2' undeclared` (see blockers below) |

Prototype binary, from the successful build:

```text
RAM:   12.6%  (41,148 bytes of 327,680)
Flash: 62.0%  (1,219,637 bytes of 1,966,080)
.pio/build/esp32dev/firmware.bin
```

A build success is not a hardware test. Nothing below claims a board was
flashed or a sensor was read.

## Prototype (v4.1.0): build, flash, verify

### 1. Prepare

- PlatformIO available: `pio --version` prints a version.
- The board is an ESP32-WROOM-32 DevKit with 4 MB flash and no PSRAM.
- Work on a bench. Do not flash while wearing the watch.
- Disconnect the LiPo before USB flashing. Never flash with a swollen, damaged,
  unprotected or questionable battery attached.

### 2. Build

```powershell
cd firmware\esp32\DigitalSaverWatch
pio run
```

The first build downloads the platform and libraries; later builds are
incremental. Success ends with `========================= [SUCCESS]` and prints
the RAM and flash usage above. Anything else is a failure, including a build
that stops on a warning promoted to an error.

Record the exact image hash beside the version:

```powershell
Get-FileHash .pio\build\esp32dev\firmware.bin -Algorithm SHA256
```

### 3. Flash

```powershell
pio device list
pio run --target upload
```

`pio device list` names the serial port. If the port is ambiguous:

```powershell
pio run --target upload --upload-port COM7
```

If auto-reset fails, hold `BOOT` while the upload starts and release it once
writing begins. If upload times out at 921600, use a shorter known-good data
cable and retry at a lower speed.

### 4. First boot

```powershell
pio device monitor
```

At 115200 the firmware prints:

```text
Veyro 4.1.0 PIN <six digits> PPG=1 MPU=1 OLED=1
```

`1` means that part was detected; `0` means it was not. If required hardware or
storage is missing it prints `Veyro halted: required hardware or storage missing`
and stops instead of pretending to run. Redact the PIN in any photo or log you
share.

### 5. Pair

Open the app, connect to the watch, and enter the PIN shown on the OLED. The
prototype requires an encrypted Secure Connections link with a static PIN,
bonding, and MITM protection. Pairing is deliberately after the boot checks, not
before them.

### 6. Recovery

| Symptom | Check |
|---|---|
| No serial port | USB data cable (not charge-only), USB-UART driver, board powered |
| Upload times out | Shorter cable, lower upload speed, hold `BOOT` |
| Boot loop | Disconnect external hardware and LiPo, inspect shorts and 3V3/5V rails |
| `PPG=0` or `MPU=0` | 3.3 V supply, common ground, SDA GPIO21, SCL GPIO22, module orientation, I2C address |
| Serial garbage | Correct port, monitor at 115200, press reset |
| OLED blank | Address 0x3C, SDA/SCL, 3.3 V, contrast after a known-good flash |

### Two defects fixed on 2026-10-21

Both were found by building, not by reading.

1. `DigitalSaverWatch.ino:110` did not compile: `max(vibeUntil, millis() + …)`
   mixed `uint32_t` and `unsigned long`. The sum is now cast; before this, the
   repository's firmware could not be built at all.
2. The BLE `face` command wrapped at `% 4` while the screens number eight, so
   the app could not select screens 4–7. It now wraps at `% 8`.

## What the prototype actually implements

The watch is wellness hardware, not a medical device. It measures heart rate, an
SpO₂ estimate, HRV, steps, fall events and battery voltage; blood pressure is
always `0/0`. The feature-by-feature table, including what each number really
is, is in [FIRMWARE_FEATURES.md](FIRMWARE_FEATURES.md).

## ESP32-S3 target (v5.0.0): does not build

`firmware/esp32s3` contains the production-shaped firmware: sensor tasks, a
storage task, haptics, power management, a watchdog, buttons, an SPI display
with LVGL, NVS, SPIFFS and NimBLE initialisation. It also contains five blockers
that make it unbuildable or non-functional as written. Do not flash it.

### 1. Three I2C buses on a chip with two

`main/veyro_main.c` defines:

| Bus | Controller | Pins | Devices |
|---|---|---|---|
| A | `I2C_NUM_0` | GPIO4/5 | FT6336G touch |
| B | `I2C_NUM_1` | GPIO1/2 | health sensors |
| C | `I2C_NUM_2` | GPIO17/18 | BQ25895 PMIC |

The ESP32-S3 has two I2C controllers. `I2C_NUM_2` does not exist, so
`init_i2c_buses()` and `factory_test()` fail to compile. This is a hardware
decision, not a typo: either the PMIC shares a bus, or a mux is added, or those
pins are driven by a bit-banged bus. Each choice depends on the schematic, which
is why it was not guessed here.

### 2. No GATT service

`veyro_main.c` initialises NimBLE, starts advertising, and accepts connections,
but never registers the service or characteristics. The service, live, history,
info, command, notification and OTA UUIDs are declared and unused. They are now
annotated `__attribute__((unused))` with a comment, so the gap is visible in the
source rather than hidden by a compiler flag. A phone that connects today finds
nothing to read.

### 3. Watch faces and themes are stubs

`display_set_watchface()` and `display_set_theme()` in `main/display.c` were
empty and had the wrong parameter types (`int` against the enums in
`display.h`). The types are fixed; the bodies remain stubs, so the five faces and
six palettes exist only as ids. The display itself is initialised over SPI with
LVGL in `display_init()`.

### 4. Some declared display functions have no definition

`main/display.h:55-58` declares `display_set_brightness()`,
`display_set_complication()`, `display_toggle_aod()` and
`display_get_config()`. `main/display.c` defines none of them, so even after the
bus and GATT work the target cannot link until they are written or removed. They
are listed here rather than deleted because the UI config struct they belong to
is the shape the five-face design needs.

### 5. The committed SDK config was wrong

`sdkconfig.esp32s3_watch` had Bluetooth disabled and 2 MB of flash, which is why
the NimBLE headers were missing and the 16 MB partition table could not fit. It
has been replaced by `sdkconfig.defaults` (16 MB, NimBLE with all four roles,
custom partition table). The generated `sdkconfig.esp32s3_watch` is not tracked in
git; it is regenerated from the defaults by each build (the failed build above
produced one locally).

### Reproduce

```powershell
cd firmware\esp32s3
pio run
```

Expected today: compilation stops at `I2C_NUM_2` in `init_i2c_buses()`. After
that decision is made, the NimBLE service table is the next piece to write.

## Source of truth

- Prototype: `firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino`,
  `pins.h`, `protocol.h`, `platformio.ini`.
- Production target: `firmware/esp32s3/main/veyro_main.c`, `main/display.c`,
  `main/display.h`, `partitions.csv`, `sdkconfig.defaults`, `platformio.ini`.
- Phone side of the protocol: `app/lib/services/veyro_protocol.dart` and
  `app/lib/services/ble_service.dart`.
- Older guides in this directory describe features that the source does not
  have. When they disagree with the files above, the files win.
