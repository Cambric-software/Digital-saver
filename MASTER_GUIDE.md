# Veyro Master Guide

## Purpose
An index and reading order for the canonical ten-guide documentation set, with a clear rule that numbered docs own requirements.
This document is an operational companion to the ten canonical guides in docs/.
It is written for a prototype and records evidence limits instead of guessing.

Start with [docs/manual.md](docs/manual.md) for the direct build order, exact repository file locations, hardware placement, and current reference sourcing. The numbered guides remain the detailed safety and evidence authority.

## Evidence labels
UNKNOWN means the repository does not establish the fact.
MUST MEASURE means a bench, fit, runtime, or comparison measurement is required.
MUST CONFIRM means the datasheet, platform behavior, or release record is required.
IMPLEMENTED means visible in the current source, not merely described in a plan.
PLANNED means a proposal or follow-up, not a current capability.

## Verified repository facts
- The firmware identifies itself as Veyro firmware 4.1.0 and uses an ESP32-WROOM-32 DevKit target.
- The firmware includes MAX30102, MPU6050, and SSD1306 support on I2C.
- I2C is configured on GPIO21 SDA and GPIO22 SCL at 400 kHz.
- GPIO25 drives vibration; GPIO4 and GPIO16 drive red and green LEDs.
- GPIO17 is the mode button; GPIO32 is the SOS button with a two-second hold.
- GPIO34 reads a two-resistor battery divider; an unwired divider reports zero.
- The display constants are 128 by 64 with OLED address 0x3C.
- The protocol advertises service UUID 4fafc201-1fb5-459e-8fcc-c5c9c331914b.
- The protocol has live, command, history, and info characteristics and protocol version 1.
- The watch writes one CSV sample per minute when heart rate is above 30 or steps are nonzero.
- LittleFS logs are pruned using a 60-day retention constant.
- The phone sends time, pair, sync, next, and prune commands through the command characteristic.
- The app parses CSV fields unix, hr, spo2, bps, bpd, hrv, steps, fall, and battery.
- The app stores imported day files below its application support directory and profile data in shared preferences.
- The app requests Bluetooth scan, Bluetooth connect, and location-when-in-use permissions on native platforms.
- The app has a demo mode that generates synthetic values and must not be mistaken for watch data.
- The app and firmware are local-only. Supabase is not a runtime dependency and the retired SQL setup has been removed.
- Firmware 4.1.0 sends the clock after pairing, preserves fall/SOS events when a minute has no other sample, and reports actual stored row counts on the OLED.

## Safety boundary
This prototype is wellness hardware and is not a medical device.
Do not diagnose, triage, or replace professional care with its readings.
Stop for smoke, swelling, odor, heat, exposed conductors, shorts, or unstable current.
Battery chemistry, protection, water resistance, enclosure fit, and skin safety are UNKNOWN until evidenced.

## How to connect and flash the watch

This procedure is for the ESP32-WROOM-32 DevKit in `firmware/esp32/DigitalSaverWatch`. It uses the PlatformIO environment `esp32dev`, upload speed `921600`, and monitor speed `115200`, as defined in `platformio.ini`.

### Before connecting power

1. Do not flash while wearing the watch. Remove it from the wrist and work on a non-conductive, supervised bench.
2. Disconnect the LiPo before USB flashing. Never flash with an unsafe, swollen, damaged, unprotected, or otherwise questionable LiPo attached.
3. Inspect the board, solder joints, headers, cable, and wiring for shorts, bridges, exposed conductors, crushed insulation, or heat damage. Check for shorts between BAT+, 3V3, 5V, and ground. PlatformIO upload success is not proof of hardware safety.
4. Connect only a known-good USB data cable to the DevKit. A charge-only cable cannot provide a serial port.
5. Install the correct USB-UART driver for the USB interface on the particular DevKit if no port appears. Do not guess the driver from the project name.

### Build, upload, and monitor

Open a terminal in `firmware/esp32/DigitalSaverWatch` and run:

```text
pio device list
pio run
pio run --target upload
pio device monitor
```

The first command lists available serial ports. If more than one port exists, select the DevKit port with `--upload-port COM7`, replacing `COM7` with the result from `pio device list`. You can also set `upload_port = COM7` under `[env:esp32dev]` in a local PlatformIO configuration when repeated uploads need a fixed port. Keep the configured upload speed at `921600`; if a reliable board or cable times out, retry with a shorter cable or lower upload speed, for example `pio run --target upload --upload-port COM7 --upload-speed 115200`.

If auto-reset fails, hold the board's `BOOT` button while upload begins. Release `BOOT` after the tool starts writing. Wait for the upload verification to finish and for the board to reset. Do not unplug it during verification or reset.

Start the serial monitor at `115200` with `pio device monitor`. After reset, capture the boot line, but redact the PIN before sharing any log:

```text
Veyro 4.1.0 PIN ... PPG=... MPU=... OLED=...
```

Never publish the PIN, even in a bug report or screenshot. Confirm the OLED shows the boot/device information and confirm the `PPG`, `MPU`, and `OLED` flags are present as expected. If a sensor is missing, stop and inspect wiring, power, I2C pins, address conflicts, and the sensor module before pairing. Pair with the app only after flashing, reset, serial capture, and the OLED/sensor checks pass.

### Recovery and binary identity

- Upload timeout: verify the port with `pio device list`, use a data cable, disconnect the LiPo, hold `BOOT` as upload begins, and lower the upload speed if needed.
- Boot loop: disconnect external hardware and LiPo, inspect for shorts and wrong power rails, then retry a clean build and upload. Do not wear or charge the device during this investigation.
- Missing sensor: check the module orientation, 3.3 V compatibility, common ground, SDA GPIO21, SCL GPIO22, and the actual I2C address. A boot line with `PPG=0` or `MPU=0` is a failed hardware check, not permission to pair.
- Serial garbage: stop the monitor, select the correct port, reopen it at `115200`, and press reset. Do not interpret output captured at another baud rate.

After `pio run`, verify the exact binary you intend to flash. From the firmware directory on Windows, run `Get-FileHash .pio\build\esp32dev\firmware.bin -Algorithm SHA256` and record the full SHA256 value with the firmware version, date, and board identity. A later build can change the hash. Verify the same hash from the same artifact before treating it as a known-good image.

### Persisted watch screens

Firmware 4.1.0 includes eight persisted OLED screens: clock, vitals estimate, activity, motion, battery, storage, connection, and device. The mode button cycles them, and the selected screen is stored in Preferences across reset. After pairing, the app can select a screen remotely with the BLE command `{"op":"face","face":0}` through `{"op":"face","face":7}`. Pairing is required for this command; do not use it as a substitute for the post-flash hardware checks.

## 1. Guide map
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Guide map.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 2. Product vision index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Product vision index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 3. Architecture index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Architecture index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 4. Offline data index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Offline data index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 5. BLE index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for BLE index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 6. BOM index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for BOM index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 7. Assembly index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Assembly index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 8. Firmware index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Firmware index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 9. App index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for App index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 10. Testing index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Testing index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 11. Manufacturing index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Manufacturing index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 12. Conflict resolution
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Conflict resolution.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 13. Evidence register
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Evidence register.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 14. Release gate index
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Release gate index.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## 15. Reader paths
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Reader paths.
- [ ] Identify the source file, component, or test fixture that controls the answer.
- [ ] Separate IMPLEMENTED behavior from PLANNED behavior.
- [ ] Mark physical values as MUST MEASURE rather than estimating them.
- [ ] Mark ratings and component behavior as MUST CONFIRM from a datasheet.
- [ ] Record firmware version, app version, board identity, and test date.
- [ ] Test the normal path with a known-good fixture.
- [ ] Test interruption, missing hardware, and malformed input.
- [ ] Capture logs, screenshots, readings, or hashes as evidence.
- [ ] Assign every failure an owner and a retest condition.
- [ ] Do not call the work complete while a safety-critical item is UNKNOWN.
- [ ] Write PASS, FAIL, or BLOCKED and explain the disposition.
- [ ] Link the result to the canonical guide that owns the requirement.
- [ ] Review privacy, user consent, and data deletion implications.
- [ ] Repeat the check after changing firmware, app, wiring, or storage format.
- [ ] Have a second reviewer challenge the evidence.
- [ ] Preserve the smallest reproducible command or procedure.
- [ ] Record what this section does not prove.
- [ ] Stop and escalate if the result could cause unsafe use.
- [ ] Close the section only after the evidence location is non-UNKNOWN.
- [ ] Write the expected input and expected output in plain ASCII.
- [ ] Include the firmware and app protocol versions in the test note.
- [ ] Check behavior when the watch is disconnected before the operation.
- [ ] Check behavior when Bluetooth is disabled or permission is denied.
- [ ] Check behavior when a sensor is absent at boot.
- [ ] Check behavior when storage is full or a file cannot be opened.
- [ ] Check that a failed operation does not silently create a false success.
- [ ] Record timestamps in UTC when comparing watch and phone records.
- [ ] Verify that a demo value is visibly separated from a real sample.
- [ ] Verify that zero means unavailable where the source uses zero.
- [ ] Do not convert a rough estimate into a diagnosis or alarm.
- [ ] Check the user-facing label against the actual source field.
- [ ] Check malformed JSON and truncated BLE notifications.
- [ ] Check duplicate history rows and interrupted history transfers.
- [ ] Check retention behavior without deleting evidence needed for the test.
- [ ] Keep test data synthetic unless consent and handling are documented.
- [ ] Remove copied secrets, phone numbers, and identifiers from shared logs.
- [ ] Record the exact command used to build or flash when applicable.
- [ ] Check that the change has no unreviewed generated-file impact.
- [ ] Review the relevant source diff before signing the result.
- [ ] Note the device model and operating system for app checks.
- [ ] Note the board and sensor revisions for hardware checks.
- [ ] Reproduce the result twice, including one cold start.
- [ ] Record the known limitation beside the result, not in a hidden note.
- [ ] Set a follow-up date for every UNKNOWN or MUST MEASURE item.
## Final release record
A release is blocked by missing measurements, missing review, unsafe battery behavior, or unsupported medical claims.
Firmware artifact hash: UNKNOWN. App artifact hash: UNKNOWN. Production signing: UNKNOWN.
Battery life: MUST MEASURE. Water resistance: MUST CONFIRM by a documented test; do not infer it.
Firmware requests encrypted BLE Secure Connections using the existing six-digit static passkey. Android pairing, bonding persistence, disconnect/reconnect, wrong-PIN rejection, and on-device behavior still require hardware-in-the-loop validation. No production security certification is claimed.
Clinical accuracy, diagnostic accuracy, and emergency response reliability: UNKNOWN.

## Canonical references
- Canonical guide 1: docs/01_*.md
- Canonical guide 2: docs/02_*.md
- Canonical guide 3: docs/03_*.md
- Canonical guide 4: docs/04_*.md
- Canonical guide 5: docs/05_*.md
- Canonical guide 6: docs/06_*.md
- Canonical guide 7: docs/07_*.md
- Canonical guide 8: docs/08_*.md
- Canonical guide 9: docs/09_*.md
- Canonical guide 10: docs/10_*.md
- [firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino](firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino)
- [app/lib/services/ble_service.dart](app/lib/services/ble_service.dart)

## Canonical ten-guide index
The numbered documents in docs/ are the controlling project guides.
- [01 product vision](docs/01_PRODUCT_VISION.md) defines scope, evidence rules, and product boundaries.
- [02 system architecture](docs/02_SYSTEM_ARCHITECTURE.md) defines the watch, BLE, storage, and app paths.
- [03 offline data](docs/03_OFFLINE_DATA.md) defines local records, retention, and interruption handling.
- [04 BLE protocol](docs/04_BLE_PROTOCOL.md) defines UUIDs, commands, notifications, and pairing checks.
- [05 hardware BOM](docs/05_HARDWARE_BOM.md) defines parts, identity checks, and measurement records.
- [06 assembly safety](docs/06_ASSEMBLY_SAFETY.md) defines wiring, battery, enclosure, and operator stops.
- [07 firmware guide](docs/07_FIRMWARE_GUIDE.md) defines build, flash, bring-up, and firmware release checks.
- [08 app development](docs/08_APP_DEVELOPMENT.md) defines Flutter setup, permissions, and app validation.
- [09 testing validation](docs/09_TESTING_VALIDATION.md) defines test evidence and comparison limits.
- [10 release manufacturing](docs/10_RELEASE_MANUFACTURING.md) defines traceability and release gates.
The root README is a quickstart. This file is an index, not a replacement for those guides.
