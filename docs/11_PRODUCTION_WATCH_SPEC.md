# Veyro Production Watch Specification

## Purpose

This document defines the hardware revision required for a store-grade Veyro watch with a touch display. It is a target specification, not a claim that the current ESP32 DevKit and SSD1306 prototype already meets it.

## Non-negotiable product decision

The current prototype cannot become a touch watch by changing firmware alone. Its SSD1306 128x64 OLED has no touch layer, and its ESP32 DevKit, breakout boards, exposed wiring, charger assumptions, and two-button navigation are not production-watch construction.

A store-grade result requires a new production hardware revision. The existing prototype remains useful as the sensor, BLE, local-storage, and protocol development fixture.

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
