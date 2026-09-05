# Veyro Firmware Feature Status

## Purpose
A source-of-truth status note that separates firmware features visible in DigitalSaverWatch.ino from proposals that are not implemented.
This document is an operational companion to the ten canonical guides in docs/.
It is written for a prototype and records evidence limits instead of guessing.

## Evidence labels
UNKNOWN means the repository does not establish the fact.
MUST MEASURE means a bench, fit, runtime, or comparison measurement is required.
MUST CONFIRM means the datasheet, platform behavior, or release record is required.
IMPLEMENTED means visible in the current source, not merely described in a plan.
PLANNED means a proposal or follow-up, not a current capability.

## Verified repository facts
- The firmware identifies itself as Veyro firmware 4.0.0 and uses an ESP32-WROOM-32 DevKit target.
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

## Safety boundary
This prototype is wellness hardware and is not a medical device.
Do not diagnose, triage, or replace professional care with its readings.
Stop for smoke, swelling, odor, heat, exposed conductors, shorts, or unstable current.
Battery chemistry, protection, water resistance, enclosure fit, and skin safety are UNKNOWN until evidenced.

## 1. Implemented boot
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented boot.
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
## 2. Implemented sensors
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented sensors.
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
## 3. Implemented display
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented display.
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
## 4. Implemented controls
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented controls.
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
## 5. Implemented BLE
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented BLE.
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
## 6. Implemented pairing
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented pairing.
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
## 7. Implemented live data
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented live data.
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
## 8. Implemented history
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented history.
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
## 9. Implemented retention
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented retention.
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
## 10. Implemented battery estimate
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented battery estimate.
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
## 11. Implemented fall flag
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented fall flag.
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
## 12. Implemented step counter
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Implemented step counter.
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
## 13. Rough SpO2 boundary
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Rough SpO2 boundary.
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
## 14. Zero blood pressure boundary
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Zero blood pressure boundary.
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
## 15. Planned enhancements
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Planned enhancements.
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
## 16. Rejected claims
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Rejected claims.
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

## Implemented versus proposed
IMPLEMENTED: boot initializes I2C, OLED, MPU6050, MAX30105-compatible PPG, LittleFS, Preferences, and BLE when hardware responds.
IMPLEMENTED: the mode button cycles clock, heart-rate, and step display faces.
IMPLEMENTED: holding the SOS button for more than two seconds sets the fall flag and vibrates; it does not send an SMS.
IMPLEMENTED: live BLE JSON and minute history rows expose the fields documented in protocol.h and the app parser.
IMPLEMENTED: a rough PPG-derived SpO2 estimate is clamped between 85 and 100; the source explicitly rejects clinical accuracy.
IMPLEMENTED: systolic and diastolic values are assigned zero after PPG processing.
IMPLEMENTED: fall detection uses simple acceleration thresholds and the source warns of false positives.
IMPLEMENTED: step counting uses a simple magnitude crossing and is not validated activity measurement.
PLANNED or UNVERIFIED: enhanced medical profile fields, insurance data, SOS Morse sequences, diagnosis-specific emergency types, and critical health packages.
PLANNED or UNVERIFIED: clinical algorithms, validated AFib detection, validated blood pressure, secure BLE encryption, cloud sync, and production OTA updates.
Do not copy the old proposal snippets into the firmware without code review, bounds checks, privacy review, and tests.
