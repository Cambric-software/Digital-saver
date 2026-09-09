# Veyro Production Watch Specification

## Purpose

This document defines the hardware revision required for a store-grade Veyro watch with a touch display. It is a target specification, not a claim that the current ESP32 DevKit and SSD1306 prototype already meets it.

## Non-negotiable product decision

The current prototype cannot become a touch watch by changing firmware alone. Its SSD1306 128x64 OLED has no touch layer, and its ESP32 DevKit, breakout boards, exposed wiring, charger assumptions, and two-button navigation are not production-watch construction.

A store-grade result requires a new production hardware revision. The existing prototype remains useful as the sensor, BLE, local-storage, and protocol development fixture.

## Chosen economical candidate

Use this candidate stack for the next engineering build so the decisions are concrete:

| Function | Selected candidate | Why this choice | Status |
|---|---|---|---|
| Bring-up board | Waveshare ESP32-S3-Touch-LCD-1.28 reference board | Combines an ESP32-S3, round color display, capacitive touch, and a known reference layout in one inexpensive board | Buy and verify exact revision |
| Production MCU | Espressif ESP32-S3-MINI-1-N8R8 on a custom carrier | BLE, secure boot/flash encryption support, 8 MB flash, 8 MB PSRAM, and enough RAM for a real UI | Datasheet and PCB review required |
| Production display | 1.28 inch round 240x240 color display using the same controller/interface as the bring-up board | Keeps the first touch UI close to the reference board while fitting a compact round enclosure | Confirm controller, refresh, brightness, and sleep current |
| Touch | The reference board's capacitive touch controller, then the identical controller on the carrier | Avoids inventing a touch protocol and gives a known interrupt/reset contract | Confirm exact controller and address from schematic |
| IMU | Bosch BMI270 | Lower-power modern IMU than the prototype MPU6050, with motion interrupts for wake and activity | Confirm library and interrupt wiring |
| Optical sensor | MAX30102 module for first validation; MAXM86161 for the production optical revision if its supply and optical stack are qualified | Preserves the existing app contract during bring-up while leaving a lower-power production path | Exact sensor and algorithm require validation |
| Fuel gauge | MAX17048 | Measures cell state without burning continuous divider current and gives low-battery alerts | Confirm cell model and I2C address |
| Charger/power path | BQ24074-class 1S charger/power-path design | Allows a documented charge path and system load separation instead of a random TP4056 board | Datasheet, thermal, and protection review required |
| Battery | Protected 1S LiPo, approximately 500-700 mAh after measured enclosure/runtime fit | Balances compactness and practical display/BLE runtime without guessing from a package label | Capacity, protection, connector, and dimensions must be measured |
| Haptics | 10 mm coin motor driven by DRV2605L or a rated MOSFET stage | Better control and less GPIO stress than direct motor drive | Motor current and enclosure coupling test required |
| Charging connector | USB-C receptacle on the carrier with ESD protection, or qualified magnetic charging contacts for the sealed revision | USB-C is cheaper for engineering; contacts are cleaner for a sealed product | Choose after enclosure and ingress decision |

The Waveshare board is a bring-up reference, not the final retail watch. The custom carrier is required for compactness, battery safety, test pads, and enclosure fit. Do not solder the reference board into the final case and call that a production design.

### Candidate reference links

- Waveshare ESP32-S3-Touch-LCD-1.28: https://www.waveshare.com/esp32-s3-touch-lcd-1.28.htm
- ESP32-S3-MINI-1 documentation: https://www.espressif.com/en/products/modules/esp32-s3-mini-1
- BMI270 product information: https://www.bosch-sensortec.com/products/motion-sensors/imus/bmi270/
- MAX17048 product information: https://www.analog.com/en/products/max17048.html
- BQ24074 product information: https://www.ti.com/product/BQ24074
- DRV2605L product information: https://www.ti.com/product/DRV2605L

Prices must be checked on the linked manufacturer or authorized distributor page on the day of ordering. The reference board and modules are engineering parts; they are not evidence of final enclosure, runtime, safety, or retail quality.

## Production hardware target

### Main board

- ESP32-S3-MINI-1 or an equivalent qualified ESP32-S3 module with secure boot, flash encryption, BLE, and measured power states.
- Custom four-layer PCB. Do not place a DevKit or breadboard inside the final enclosure.
- Test pads for USB/UART programming, battery rail, regulated rail, ground, I2C, touch interrupt, display reset, and motor control.
- ESD protection on external charging, programming, and accessible signal paths.
- A production identity area for serial number, hardware revision, and regulatory markings.

### Display and touch

- A 1.3 to 1.5 inch round or square color AMOLED/TFT selected for the enclosure, with a bonded capacitive touch controller.
- Minimum target: 360x360 or 390x390 pixels, 16-bit color, readable indoor and outdoor brightness, and a documented sleep current.
- Touch controller must expose a documented I2C or SPI interface, interrupt line, reset line, and gesture capabilities.
- Cover lens must be chemically strengthened glass or a qualified optical polymer with an anti-fingerprint coating.
- The display stack must be mechanically retained and optically sealed; do not use a loose breakout-board window.
- Backlight/AMOLED power must be switched by hardware or a load switch so the display can enter a measured low-power state.

### Sensors

- MAX30102 or another exact optical module selected from one supplier and validated with the chosen optical window. Do not describe a MAX30105 board as MAX30102 without confirming the actual component.
- 6-axis IMU selected for the final PCB and validated for step/fall algorithms.
- Optional temperature sensor only if the product will display temperature. Otherwise remove temperature claims from the product UI.
- Blood pressure is not part of this production target unless a validated pressure sensor and clinical validation program are added.

### Power

- Protected 1S LiPo selected by measured capacity, maximum discharge current, dimensions, connector, and safety documentation.
- Charger and power-path IC with documented battery protection, thermal regulation, load sharing, and charge termination.
- Fuel-gauge IC with a measured battery model; a raw ADC divider is not the production battery gauge.
- Separate regulated rails or load switches for the ESP32, display, sensors, and haptic motor where measurements require them.
- Haptic motor driven by a rated transistor or driver with a flyback path. Never drive it from an ESP32 GPIO.
- Hardware low-battery behavior: stop charging outside the allowed temperature range, reduce display duty cycle, preserve logs, and shut down before unsafe cell discharge.

### Mechanical product

- Custom enclosure designed around the PCB, display stack, optical window, battery, haptic motor, charging method, buttons, and strap.
- No sharp edges, exposed solder, compressed battery, loose sensor, or replaceable part that can contact skin unexpectedly.
- Qualified strap and skin-contact materials.
- Documented ingress target. Do not print an IP rating until the enclosure passes the corresponding test.
- Drop, vibration, sweat, charging heat, button life, display adhesion, and strap retention tests.

## Touch operating system requirements

The production firmware must add a display abstraction separate from sensor and BLE code. It must provide:

- A 60 FPS-capable render loop where the selected display can support it.
- Sleep, wake, ambient interaction, screen timeout, and low-battery display modes.
- Touch down, move, up, long press, swipe, edge swipe, and multi-touch rejection behavior.
- A lock screen and accidental-touch protection while the watch is on the wrist.
- A small scene/state system for clock, vitals, activity, sleep, notifications, settings, pairing, and SOS confirmation.
- Theme, color, font, complication, watch-face, and vibration customization stored in Preferences or a versioned local settings store.
- No blocking delays in sensor, BLE, rendering, or haptic paths.
- A watchdog and controlled recovery policy for display, touch, I2C, BLE, and filesystem faults.
- Signed firmware, secure boot, flash encryption, anti-rollback policy, and a documented recovery path before production distribution.

## Touch firmware pin contract

Do not copy the current `pins.h` map into the production board. The production PCB must receive a new revisioned pin map after the selected display and touch controller are chosen. At minimum it will need:

- Display bus pins and chip select or I2C address.
- Display reset and power-enable pins.
- Touch bus pins, interrupt, reset, and address or chip select.
- Fuel-gauge interrupt or I2C address.
- Haptic driver enable/PWM.
- Programming and test pads.

The production protocol must include the display hardware revision and touch capability in device info so the app cannot assume the prototype OLED contract.

## Production software architecture

1. `hal/`: display, touch, IMU, optical sensor, fuel gauge, haptic, storage, and power drivers.
2. `os/`: scheduler, event queue, watchdog, power states, input routing, and fault state.
3. `ui/`: renderer, screens, theme engine, touch gestures, accessibility sizes, and watch-face registry.
4. `services/`: BLE pairing, local history, time sync, settings, and update verification.
5. `app/`: Flutter companion app with capability negotiation and truthful sensor labels.

The current `DigitalSaverWatch.ino` should remain the prototype fixture. It should not be expanded indefinitely into the production operating system without first extracting these boundaries.

## First production software milestone

The first production branch should target the chosen reference board before the custom carrier:

1. Add a `production_touch` PlatformIO environment instead of changing the prototype `esp32dev` environment.
2. Add a display HAL for the reference controller and a touch HAL for its controller.
3. Render only four useful screens first: clock, vitals, activity, and settings/pairing.
4. Add touch gestures, wake/sleep, a 30-second timeout, and a hardware-safe low-battery mode.
5. Keep the BLE health payload and local history contract compatible until capability negotiation is added.
6. Add `display_hw`, `touch_hw`, `imu_hw`, and `fuel_gauge` fields to device info before the app enables production-only screens.
7. Port the tested HALs to the custom carrier only after display, touch, power, and sensor measurements pass on the reference board.

This is the shortest credible path to a compact touch watch. It is not credible to add a touch library to the current SSD1306 sketch and call the result production-ready.

## Acceptance gates before calling it store-grade

- Touch works across the complete display surface after cold boot, wake, and reconnect.
- A 24-hour run has no uncontrolled reset, data loss, stuck motor, or touch lockup.
- Battery runtime is measured with display off, display active, BLE connected, sensors active, and haptic events.
- Charging temperature and battery protection behavior are measured.
- Optical readings are repeatable against a defined reference protocol and remain labelled wellness-only unless clinically validated.
- Bluetooth pairing, bonding, reconnect, wrong-PIN attempts, reset, and lost-phone recovery are tested on supported phone versions.
- Firmware and app artifacts are signed and their hashes are recorded.
- Enclosure drop, sweat, skin-contact, display adhesion, button/touch life, and ingress tests pass.
- A production tester can verify every unit before shipment.
- The manual, BOM, schematic, PCB revision, firmware version, app version, and test results identify the same hardware revision.

Until these gates pass, the correct product description is "Veyro development prototype" rather than "Apple Watch comparable" or "store-grade smartwatch."
