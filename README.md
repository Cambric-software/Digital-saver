# Digital Saver & Veyro Smartwatch Ecosystem

> **Proprietary Smartwatch Hardware, Embedded Firmware & Flutter Companion Application**  
> Developed by **Cambric** (Lead Architect: Asser Karim)  
> *Protected under the Cambric Source-Available Commercial-Restricted License 1.0 (2026)*

---

## 🌟 Overview

**Digital Saver & Veyro** is an integrated health-monitoring smartwatch platform designed and engineered from the ground up by Cambric. It pairs high-efficiency embedded firmware with an offline-first Flutter companion application, offering biometric tracking, continuous vitals logging, customizable circular UI faces, and emergency SOS fall telemetry.

The repository supports two hardware development tiers:
1. **Production Platform (`firmware/esp32s3`)**: ESP32-S3-MINI-1U-N16R8, 360×360 round AMOLED (FT6336G capacitive touch), VC31B PPG, QMI6858C 6-axis IMU + pedometer, BMP581 barometer, STTS22H temperature sensor, DRV2605L haptics, BQ25895 PMIC, and magnetic charging. Runs FreeRTOS + NimBLE GATT Protocol v2.
2. **Evaluation Prototype (`firmware/esp32`)**: ESP32-WROOM-32 DevKit, SSD1306 OLED, MAX30102 PPG, MPU6050 IMU, LittleFS 60-day circular flash logging, and BLE Protocol v1.

---

## 🏗 Architecture & Repository Layout

```
├── app/                              # Flutter companion app (Android, iOS, Desktop)
│   ├── lib/
│   │   ├── screens/                  # Health, settings, watchfaces, analytics UI
│   │   ├── services/                 # BLE service, VeyroProtocol v2, auto-update, sync
│   │   └── models/                   # Vitals, activity, and historical records
│   └── pubspec.yaml                  # Flutter 3.x dependencies
├── firmware/
│   ├── esp32s3/                      # Production Watch Firmware (FreeRTOS / ESP-IDF 5.2 / NimBLE)
│   │   ├── main/                     # veyro_main.c, display drivers, LVGL 8.3/9.x UI
│   │   └── partitions.csv            # 16MB dual-OTA flash partition table
│   └── esp32/                        # Evaluation Prototype (Arduino / PlatformIO)
│       └── DigitalSaverWatch/        # Core WROOM-32 sketches and pinouts
├── docs/                             # Engineering guides and manufacturing gates
│   ├── 01_PROJECT_OVERVIEW.md
│   ├── 02_SYSTEM_ARCHITECTURE.md
│   ├── 04_BLE_PROTOCOL.md
│   ├── 05_HARDWARE_BOM.md
│   ├── 11_PRODUCTION_WATCH_SPEC.md   # Production S3 spec & target unit economics
│   └── manual.md                     # Step-by-step build and assembly manual
├── UPGRADE_GUIDE.md                  # Firmware and app migration & rollback protocol
├── SECURITY.md                       # Threat model, BLE security & vulnerability reporting
├── MASTER_GUIDE.md                   # Documentation index and governance
└── LICENSE                           # Cambric Source-Available Commercial-Restricted License
```

---

## ⚡ Core Features

- **Biometric Monitoring**: Live continuous heart rate, blood oxygen (SpO2), HRV, steps, skin temperature, and barometric elevation.
- **60-Day Onboard Flash Retention**: Local LittleFS/SPIFFS circular storage retains up to 2 months of compressed telemetry without phone connection.
- **Veyro BLE Protocol v2**: Ultra-fast live vitals stream (250ms), background history synchronization, custom UI theme sync, notification bridge, and authenticated OTA endpoints.
- **Circular AMOLED Custom UI**: 5 switchable watchfaces, 6 dynamic color palettes, complication slots, and gesture-driven navigation.
- **Emergency SOS & Fall Telemetry**: Multi-axis acceleration impact analysis with automatic emergency contact alerting.
- **Privacy & Security**: Zero mandatory cloud dependency; health records remain on-device with optional local encrypted export.

---

## 🚀 Getting Started

### 1. Companion App Setup (Flutter)
```bash
cd app
flutter pub get
flutter run
```

### 2. Production Firmware (ESP32-S3)
```bash
cd firmware/esp32s3
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

### 3. Evaluation Prototype (ESP32-WROOM)
```bash
cd firmware/esp32/DigitalSaverWatch
pio run --target upload
```

---

## 📜 Intellectual Property & Licensing

Copyright (c) 2026 **Cambric Software & Hardware Systems**. All rights reserved.  
Author & Proprietor: **Asser Karim**.

This repository is licensed under the **Cambric Source-Available Commercial-Restricted License 1.0**.
- **Personal & Educational Use**: Free to view, study, test, and evaluate.
- **Commercial Use & Manufacturing**: Strictly prohibited without an executed commercial licensing agreement from Cambric. Commercial replication, sale, rebranding, or resale is strictly reserved.
- **Medical Disclaimer**: Digital Saver is a consumer wellness platform and is **not** a certified medical diagnostic device.

For commercial licensing, partnerships, or hardware inquiries, contact Cambric: `asser.k.dev@gmail.com`.
