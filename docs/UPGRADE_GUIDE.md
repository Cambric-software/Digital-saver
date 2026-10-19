# Veyro & Digital Saver Upgrade & Migration Guide

## 1. Scope & Purpose
This guide defines safe, controlled procedures for upgrading and migrating hardware, firmware, BLE protocols, and companion app data across the Cambric Digital Saver ecosystem.

---

## 2. Firmware Upgrade Architecture

### ESP32-S3 Production Target (`firmware/esp32s3`)
- **Version**: Firmware 5.0.0 (Protocol v2)
- **Flash Partitioning**: 16MB flash layout with dual OTA slots:
  - `ota_0` (3.2MB) and `ota_1` (3.2MB)
  - `storage` partition for telemetry LittleFS / NVS
- **Safe Rollback**: In case an OTA update fails boot validation, the ESP-IDF bootloader automatically falls back to the previous stable OTA partition.

### Evaluation Prototype Target (`firmware/esp32`)
- **Version**: Firmware 4.1.0 (Protocol v1)
- **Flash Storage**: Single-application image with SPIFFS/LittleFS circular buffer. Flash erase must preserve calibration offsets stored in NVS.

---

## 3. BLE Protocol Compatibility (v1 to v2)
- **Version Identifier**: `VeyroProtocol.version` (v1: WROOM prototype, v2: S3 production).
- **GATT Compatibility Matrix**:
  - `Service UUID`: `4fafc201-1fb5-459e-8fcc-c5c9c331914b` (Retained across both versions).
  - `Live Vitals`: `beb5483e-36e1-4688-b7f5-ea07361b26a8` (250ms cadence in v2; 1s in v1).
  - `Command`: `beb5483e-36e1-4688-b7f5-ea07361b26f0`.
  - `History Sync`: `beb5483e-36e1-4688-b7f5-ea07361b26a1`.
  - `Notification Bridge (v2 only)`: `beb5483e-36e1-4688-b7f5-ea07361b26b0`.
  - `OTA Transfer (v2 only)`: `beb5483e-36e1-4688-b7f5-ea07361b26c0`.
- The companion Flutter app automatically negotiates Protocol v2 when connected to S3 hardware while retaining backward compatibility for v1 devices.

---

## 4. Companion App Data Migrations
- **Local Database**: Day files stored under application sandbox are preserved during app upgrades.
- **Rollback Safety**: If the app fails to initialize storage after an update, unparsed records are quarantined to a backup `.corrupted` folder rather than overwritten.
- **Profile & PIN Storage**: Encrypted preferences maintain user calibration and pairing PIN across app version increments.
