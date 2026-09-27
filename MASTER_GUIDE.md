# Veyro & Digital Saver: Master Technical Guide
*Official Engineering Reference Manual — Cambric Software Ecosystem (2026)*

---

## 1. Executive System Overview

The **Digital Saver / Veyro** platform is a complete, local-first wearable ecosystem designed and built by Cambric Software. It pairs embedded smartwatch hardware with a high-performance cross-platform Flutter companion application, prioritizing complete data ownership, 60-day on-device telemetry retention, offline autonomy, and responsive UI customization.



---

## 2. Hardware Architecture & Specifications

### 2.1 Target Tiers

| Parameter | Tier 1: Production (Flagship) | Tier 2: Prototype (Bench Evaluation) |
| :--- | :--- | :--- |
| **Compute Core** | ESP32-S3-MINI-1-N8R8 (Dual-core Xtensa @ 240MHz, 8MB Flash, 8MB PSRAM) | ESP32-WROOM-32 DevKit (Dual-core @ 240MHz, 4MB Flash, 520KB SRAM) |
| **Display** | 1.28"–1.43" Circular IPS/AMOLED (360×360 or 240×240 GC9A01 / ST7789) | 0.96" Monochrome I2C OLED (128×64 SSD1306 @ 0x3C) |
| **Graphics Engine**| LVGL 8.3/9.x with Double Buffer DMA | Direct SSD1306 Wire buffer rendering |
| **Biometrics** | MAX30101 / Goodix GH3011 (HR, SpO2, HRV) | MAX30102 (HR, SpO2) |
| **Motion/IMU** | Bosch BMI270 / QST QMI8658C 6-DOF (Hardware Step & Tilt) | MPU6050 6-DOF (Software-debounced step counter) |
| **Power Management**| TI BQ25895 / BQ24074 + MAX17048 Fuel Gauge (1S LiPo, 400–500mAh) | TP4056 + Resistor Divider (GPIO34 ADC) |
| **Haptics** | TI DRV2605L + LRA Linear Actuator | Coreless DC vibration motor (GPIO25 / NPN driver) |
| **Charging** | 2-pin / 4-pin Magnetic Pogo Cable | Micro-USB / USB-C DevKit port |
| **Enclosure** | Aluminum alloy / 316L Stainless Steel + Sapphire/Gorilla Glass | 3D Printed SLA / Acrylic open bench |

### 2.2 Pin Allocation Matrix

#### ESP32-S3 Production Hardware ()
- **Display SPI**: MOSI , SCLK , CS , DC , RST , Backlight (PWM) 
- **Sensors I2C (400kHz)**: SDA , SCL  (MAX30101, BMI270, MAX17048)
- **Controls**: Rotary Crown / Main Button  (Active Low), Dedicated SOS Key  (Active Low)
- **Haptic Driver**: LRA Enable/PWM  (or I2C to DRV2605L)
- **Power & Status**: Charger Int , Power Good , Low Battery Warning 

#### ESP32-WROOM Bench Hardware ()
- **I2C Bus (400kHz)**: SDA , SCL  (Shared across SSD1306, MAX30102, MPU6050)
- **Buttons**: Mode/Cycle Button , SOS Button  (Hold 2s)
- **LEDs & Feedback**: Vibration , Red LED , Green LED 
- **Battery Measurement**: GPIO 34 (16-sample ADC averaging with 2:1 100k/100k divider)

---

## 3. BLE GATT Protocol Specification (Version 2)

All communications between the watch and companion mobile app utilize custom GATT services over Bluetooth Low Energy.

### 3.1 Service & Characteristic UUID Registry

Base UUID prefix: 

| Characteristic | UUID | Properties | Format / Payload |
| :--- | :--- | :--- | :--- |
| **Live Telemetry** |  | Read, Notify | Packed binary / JSON () |
| **Command Pipe** |  | Write | JSON control commands () |
| **History Sync** |  | Read, Notify | Batched CSV records from LittleFS buffer |
| **Device Info** |  | Read | Firmware version, hardware tier, serial, battery health |
| **Notification Pipe** |  | Write | Incoming calls, alarms, app alerts with vibration patterns |
| **Dual-OTA Service** |  | Write, Notify | Firmware block transfer, SHA-256 verification, boot switch |

### 3.2 Command Payloads
- **Pair Device**: 
- **Set Watchface**:  (0: Classic, 1: Sport, 2: Minimalist, 3: Dashboard, 4: Terminal)
- **Set Palette**:  (0: Obsidian, 1: Emerald, 2: Cyberpunk, 3: Sunset, 4: Titanium, 5: Cobalt)
- **Set Brightness**: 
- **Sync History**: 

---

## 4. UI & Graphics Subsystem (ESP32-S3 LVGL)

The production watch UI is driven by LVGL 8.3 with custom hardware acceleration:
- **Display Buffer**: Double-buffered 40-line rendering buffer allocated in internal DMA SRAM.
- **Watchface Engine**: Dynamic complication slots supporting Heart Rate, Steps, SpO2, Calories, and Battery.
- **Power Management & Wake**:
  - Inactivity sleep timeout: 15 seconds.
  - Tilt-to-wake: Monitored via IMU interrupt.
  - Ambient Always-On-Display (AOD): Low-power dimmed minimalist digital clock.
  - Crown single click cycles watchfaces; long-press toggles power/settings.
  - SOS button 3-second hold triggers high-priority BLE telemetry flag and haptic pulse.

---

## 5. Mobile Companion App ()

The companion application is built with Flutter 3.x and architected around a strict local-first model:
- **Services Architecture**:
  - : Handles auto-reconnect, background GATT synchronization, and RSSI monitoring.
  - : Enforces protocol v2 framing, checksum validation, and command serialization.
  - : In-app checking and zero-downtime updates with automated hash validation.
  - : AI wellness analysis with intelligent fallback across Gemini 2.0 Flash, 1.5 Flash, and 1.5 Flash Latest.
- **Data Persistence**:
  - Local SQLite database & application support directory.
  - 60-day historical retention mirror matching the watch's internal LittleFS storage.
  - Complete zero-cloud requirement: 100% of user vitals stay on user hardware.
- **Watch Simulator**:
  - Built-in full-fidelity simulator for UI preview, vitals injection, and protocol debugging without physical hardware.

---

## 6. Build, Flash & Deployment Guide

### 6.1 ESP32-S3 Flagship ()


### 6.2 ESP32-WROOM Evaluation Bench ()


### 6.3 Flutter Mobile Companion ()


---

## 7. Safety, Compliance & Regulatory Notice

1. **Wellness Device Only**: Veyro and Digital Saver are lifestyle wellness monitoring prototypes. They are **not** certified medical devices and must not be used for diagnosis, clinical treatment, or life-critical monitoring.
2. **LiPo Battery Safety**: Never charge or discharge lithium-polymer batteries unsupervised. Use only safety-certified battery packs with integrated protection circuits (PCM). Disconnect battery power before performing serial firmware flashing.
3. **Intellectual Property**: Digital Saver and Veyro are protected under the Cambric Source-Available Commercial-Restricted License 1.0 (2026). Commercial production, rebranding, and distribution are strictly reserved.
