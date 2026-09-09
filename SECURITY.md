# Veyro Security and Privacy

## Purpose
A threat model, privacy contract, and release-gate reference for the watch, BLE link, Flutter app, and local files.
This document is an operational companion to the ten canonical guides in docs/.
It is written for a prototype and records evidence limits instead of guessing.

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

## Safety boundary
This prototype is wellness hardware and is not a medical device.
Do not diagnose, triage, or replace professional care with its readings.
Stop for smoke, swelling, odor, heat, exposed conductors, shorts, or unstable current.
Battery chemistry, protection, water resistance, enclosure fit, and skin safety are UNKNOWN until evidenced.

## 1. Threat model scope
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Threat model scope.
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
## 2. Assets
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Assets.
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
## 3. Actors
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Actors.
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
## 4. BLE discovery
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for BLE discovery.
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
## 5. PIN pairing
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for PIN pairing.
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
## 6. BLE transport
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for BLE transport.
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
## 7. Phone compromise
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Phone compromise.
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
## 8. Local files
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Local files.
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
## 9. Shared preferences
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Shared preferences.
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
## 10. Logs and diagnostics
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Logs and diagnostics.
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
## 11. Emergency actions
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Emergency actions.
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
## 12. Cloud boundaries

The current product has no cloud client. Health history, profiles, contacts, and watch logs remain on the device or in the local app store. The former Supabase setup files were retired on 2026-09-09. Any future cloud feature requires a new threat model, consent flow, deletion policy, migration plan, and security review before code is added.
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Cloud boundaries.
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
## 13. Dependency risk
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Dependency risk.
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
## 14. Firmware update risk
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for Firmware update risk.
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
## 15. App release gates
Use this section as a small work package; record the result before moving on.
Owner: UNKNOWN. Date: UNKNOWN. Evidence path: UNKNOWN.
- [ ] State the exact question for App release gates.
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

## Threat model and privacy contract
Assets include live readings, history CSV rows, profile data, emergency contacts, the watch PIN, and device identifiers.
Relevant actors include a nearby BLE observer, a person with physical watch access, a compromised phone, a malicious app, and a lost phone.
The watch advertises a known service and accepts command writes after the stored six-digit PIN succeeds.
The source does not establish BLE link encryption, authenticated firmware updates, certificate pinning, or secure boot.
Treat live notifications and history rows as sensitive over an untrusted radio until transport security is verified.
The app describes storage as local-first: day files use application support storage and profiles and contacts use shared preferences.
Local-first does not mean encrypted-at-rest; encryption status is UNKNOWN and MUST CONFIRM from implementation and platform tests.
The app requests Bluetooth and location permissions on native platforms; explain why access is needed and handle denial.
URL actions for calls or messages are not proof that an emergency was delivered.
Do not put real names, contacts, PINs, or health rows in issue reports or captured logs.
Report security issues privately with reproduction steps, affected version, impact, and redacted evidence.
Release gates require a transport decision, update authenticity decision, storage exposure review, dependency review, and recovery plan.
Never advertise secure BLE, cloud privacy, medical compliance, or emergency reliability without a test record.
