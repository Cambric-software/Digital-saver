# Veyro firmware plan

## Target architecture (production)
- Application processor: Rockchip RV1106G3 (LuckFox Pico Zero class), Linux via Buildroot.
- Companion: ESP32-C6 for Bluetooth/Wi-Fi 6 and low-power radio.
- Display: 1.43" 466x466 round AMOLED (MIPI/QSPI), touch.
- UI: LVGL 9, 18 first-party apps, Arabic/English with RTL.
- Storage: 8GB eMMC, OTA updates.

## Why not ESP32-S3 only
The ESP32-S3 firmware in `firmware/esp32s3` is a useful demo and fallback, but
RV1106 gives a real Linux userspace, a GPU/NPU for smooth UI, and room for 18
apps. For a sellable 7,500 EGP product, RV1106 is the right base.

## Milestones
1. Boot Linux on RV1106 with display driver (QSPI/MIPI) and touch.
2. Port LVGL 9, render a clock face and one app.
3. Add ESP32-C6 companion (BLE/Wi-Fi) with a simple protocol.
4. Build the 18 first-party apps (clock, health, notifications, settings, ...).
5. Add OTA update and pairing with Digital Saver app.
6. Arabic/English localization and RTL.

## Current assets
- ESP32-S3 demo firmware exists in `firmware/esp32s3` and can be used for
  early demos while RV1106 hardware is sourced.
- Digital Saver app (Flutter) is the phone companion.

## Next steps
- Source RV1106G3 board and AMOLED module (see VEYRO_DEMO_BOM.md).
- Set up Buildroot toolchain and display driver.
- Port LVGL and first app.

No hardware on hand yet; firmware work is code-only until the demo unit arrives.