# Digital Saver Onyx Watch - Complete Firmware Documentation

> **Document Version:** 3.0.3  
> **Last Updated:** July 2026  
> **Watch Model:** Onyx (Digital Saver Smartwatch)  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## 📋 Table of Contents

1. [Overview](#1-overview)
2. [Hardware](#2-hardware)
3. [Pin Configuration](#3-pin-configuration)
4. [Sensors](#4-sensors)
5. [BLE Communication](#5-ble-communication)
6. [Display & Themes](#6-display--themes)
7. [Watch Modes](#7-watch-modes)
8. [Commands Reference](#8-commands-reference)
9. [Build & Flash](#9-build--flash)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Overview

The Digital Saver Onyx is a health monitoring smartwatch built with ESP32. It features real-time heart rate monitoring, SpO2 tracking, blood pressure estimation, and fall detection.

### Key Features

| Feature | Description |
|---------|-------------|
| **Heart Rate** | Real-time PPG-based heart rate monitoring |
| **SpO2** | Blood oxygen saturation measurement |
| **Blood Pressure** | Estimated BP from PPG waveform analysis |
| **Fall Detection** | Accelerometer-based fall detection |
| **Sleep Tracking** | Automatic sleep monitoring |
| **Activity** | Step counting and calorie tracking |
| **5 Display Themes** | Customizable watch display (v3.0.3+) |
| **BLE Sync** | Connects to Digital Saver app |

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 3.0.3 | July 2026 | Added 5 display themes, BLE command support |
| 3.0.0 | July 2026 | Major rewrite with new architecture |
| 1.x | 2025 | Initial release |

---

## 2. Hardware

### System Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ONYX SMARTWATCH                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                      ESP32-WROOM-32                          │    │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐ │    │
│  │  │ CPU     │  │ WiFi    │  │ BLE     │  │ 4MB Flash      │ │    │
│  │  │ 240MHz  │  │ 802.11  │  │ 4.2     │  │ 520KB SRAM     │ │    │
│  │  │ Dual    │  │ b/g/n   │  │          │  │                │ │    │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘ │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                              │                                       │
│           ┌──────────────────┼──────────────────┐                    │
│           │                  │                  │                    │
│  ┌────────▼────────┐  ┌──────▼──────┐  ┌───────▼───────┐          │
│  │   MAX30102      │  │  MPU6050    │  │  OLED 0.96"   │          │
│  │   PPG Sensor   │  │ Accelerom.  │  │  SSD1306 I2C   │          │
│  │   HR + SpO2    │  │ 6-axis      │  │  128x64        │          │
│  └────────┬────────┘  └──────┬──────┘  └───────────────┘          │
│           │                  │                                      │
│           │  I2C Bus         │                                      │
│           │  GPIO18 (SDA)   │                                      │
│           │  GPIO19 (SCL)   │                                      │
│           │                  │                                      │
│  ┌────────▼────────┐  ┌──────▼──────┐  ┌───────────────────┐       │
│  │   Power System  │  │   LEDs      │  │   Vibration       │       │
│  │                │  │             │  │   Motor           │       │
│  │ LiPo 500mAh    │  │ Red + Green│  │                   │       │
│  │ TP4056 Charger │  │ 3mm LEDs   │  │ Emergency Alert   │       │
│  └────────────────┘  └────────────┘  └───────────────────┘       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Bill of Materials

| Component | Model | Quantity | Purpose |
|-----------|-------|----------|---------|
| MCU | ESP32-WROOM-32 | 1 | Main processor |
| PPG Sensor | MAX30102 | 1 | Heart rate & SpO2 |
| Accelerometer | MPU6050 | 1 | Steps & fall detection |
| Display | SSD1306 OLED 0.96" | 1 | User interface |
| Battery | LiPo 502035 500mAh | 1 | Power supply |
| Charger | TP4056 USB-C | 1 | Battery charging |
| Vibration | 3V ERM Motor | 1 | Haptic alerts |

---

## 3. Pin Configuration

### ESP32-WROOM-32 Pinout

```
                    ESP32-WROOM-32
                   ┌────────────────┐
    3V3       ────│ 1          38  │──── GPIO37
    GND       ────│ 2          37  │──── GPIO38
    GPIO36    ────│ 3          35  │──── GPIO34 (BUTTON_BACK)
    GPIO39    ────│ 4          32  │──── GPIO33
    GPIO34    ────│ 5          25  │──── GPIO25 (VIB_MOTOR)
    GPIO35    ────│ 6          26  │──── GPIO26 (HR_INT)
    GPIO4     ────│ 7          27  │──── GPIO27 (MOTION_INT)
    GPIO0     ────│ 8          14  │──── GPIO14
    GPIO2     ────│ 9          12  │──── GPIO12
    GPIO15    ────│ 10         13  │──── GPIO13
    GND       ────│ 11         15  │──── GPIO15
    GPIO16    ────│ 12         16  │──── GPIO16
    GPIO17    ────│ 13         17  │──── GPIO17 (EMERGENCY)
    GPIO5     ────│ 14         18  │──── GPIO18 (SCL)
    GPIO19    ────│ 15         19  │──── GPIO19 (SDA)
                   └────────────────┘
```

### Pin Assignments

| Pin | Name | Type | Description |
|-----|------|------|-------------|
| GPIO18 | I2C_SCL | Output | I2C clock line |
| GPIO19 | I2C_SDA | Output | I2C data line |
| GPIO26 | HR_INT | Input | MAX30102 interrupt |
| GPIO27 | MOTION_INT | Input | MPU6050 interrupt |
| GPIO25 | VIB_MOTOR | Output | Vibration motor |
| GPIO4 | LED_RED | Output | Red status LED |
| GPIO16 | LED_GREEN | Output | Green status LED |
| GPIO17 | BUTTON_MODE | Input | Mode button |

### I2C Device Addresses

| Device | Address | Notes |
|--------|---------|-------|
| MAX30102 | 0x57 | PPG sensor |
| MPU6050 | 0x68 | Accelerometer |
| SSD1306 | 0x3C | OLED display |

---

## 4. Sensors

### MAX30102 PPG Sensor

| Parameter | Value |
|-----------|-------|
| Supply Voltage | 1.8V - 3.3V |
| LED Current | 0mA - 50mA |
| Sample Rate | 100Hz - 3200Hz |
| ADC Resolution | 18 bits |
| I2C Address | 0x57 |

**Key Registers:**
- `FIFO_DATA` (0x05) - Read sensor data
- `MODE_CONFIG` (0x0A) - Control operating mode
- `LED_CONFIG` (0x09) - LED pulse amplitude
- `SPO2_CONFIG` (0x06) - SpO2 settings

### MPU6050 Accelerometer

| Parameter | Value |
|-----------|-------|
| Supply Voltage | 3.3V |
| Accelerometer | ±2g to ±16g |
| Gyroscope | ±250°/s to ±2000°/s |
| I2C Address | 0x68 |

**Key Registers:**
- `PWR_MGMT_1` (0x6B) - Power management
- `ACCEL_XOUT_H` (0x3B) - Accelerometer data
- `INT_STATUS` (0x3A) - Interrupt status

### SSD1306 OLED Display

| Parameter | Value |
|-----------|-------|
| Resolution | 128 x 64 pixels |
| Supply Voltage | 3.3V |
| I2C Address | 0x3C |
| Max Current | 25mA |

---

## 5. BLE Communication

### Service & Characteristics

| Type | UUID | Properties |
|------|------|------------|
| **Service** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Primary |
| **Data Characteristic** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | Read/Notify |
| **Command Characteristic** | `beb5483e-36e1-4688-b7f5-ea07361b26f0` | Write |

### Data Format (Notify)

Health data sent from watch to app:

```json
{
  "hr": 72,           // Heart rate (BPM)
  "spo2": 98,        // SpO2 (%)
  "bps": 120,        // Systolic BP
  "bpd": 80,         // Diastolic BP
  "hrv": 45.2,       // HRV (ms)
  "steps": 5420,     // Step count
  "cal": 285.5,      // Calories burned
  "temp": 36.6,      // Temperature
  "irreg": 0,        // Irregular heartbeat flag
  "fall": 0,         // Fall detected flag
  "ax": 0.01,        // Accelerometer X
  "ay": 0.02,        // Accelerometer Y
  "az": 1.02         // Accelerometer Z
}
```

### Connection Parameters

| Parameter | Value |
|-----------|-------|
| Connection Interval | 100ms |
| Slave Latency | 0 |
| Supervision Timeout | 4000ms |
| MTU Size | 512 bytes |
| Device Name | "Digital Saver" |

---

## 6. Display & Themes

### Watch Themes (v3.0.3+)

The watch supports 5 display themes that can be changed via BLE commands:

| Theme ID | Name | Description |
|----------|------|-------------|
| 0 | **Default** | White text on black background |
| 1 | **Inverted** | Black text on white background |
| 2 | **High Contrast** | Bold white text |
| 3 | **Night Mode** | Red text on black (easy on eyes in dark) |
| 4 | **Minimal** | Binary time display (dots only) |

### Theme Mapping from App

When you select a theme in the Digital Saver app, it syncs to the watch:

| App Theme | Watch Theme |
|-----------|-------------|
| Gradient Blue | Default (0) |
| Ocean Blue | Inverted (1) |
| Royal Purple | High Contrast (2) |
| Nature Green | Default (0) |
| Clean White | Inverted (1) |
| Night Dark | Night Mode (3) |

### Display Screens

#### Clock Mode
```
┌────────────────────────┐
│    ●              ▮    │  <- BLE, Battery
│                        │
│        12:45           │  <- Large time
│                        │
│     Mon, Jan 15        │  <- Date
│                        │
└────────────────────────┘
```

#### Heart Rate Mode
```
┌────────────────────────┐
│  HR                BPM │
│      ┌────────┐        │
│      │   72   │        │  <- Heart rate
│      └────────┘        │
│                        │
│  SpO2: 98%             │
│  HRV:  45ms            │
└────────────────────────┘
```

#### Minimal Mode (Binary Time)
```
┌────────────────────────┐
│         ●●●●           │  <- Battery (5 dots)
│                        │
│  ●●  ●●  ●●  ●●       │  <- Binary digits
│  H1  H2  M1  M2       │     (4 bits each)
│                        │
└────────────────────────┘
```

---

## 7. Watch Modes

| Mode | Display | Key Function |
|------|---------|--------------|
| `MODE_CLOCK` | Time, date, status | Default display |
| `MODE_HEART_RATE` | HR, SpO2, HRV | Heart monitoring |
| `MODE_BLOOD_PRESSURE` | Systolic, diastolic | BP tracking |
| `MODE_ACTIVITY` | Steps, calories | Activity tracking |
| `MODE_SLEEP` | Sleep score | Sleep monitoring |
| `MODE_SETTINGS` | Config options | Settings display |

### Mode Navigation

- **Mode Button**: Cycle through modes
- **Back Button**: Return to previous mode
- **BLE Command**: Can switch modes remotely

---

## 8. Commands Reference

### BLE Commands (Write to Command Characteristic)

Send commands from app to watch via `COMMAND_CHAR_UUID`:

#### Set Theme
```
Command: THEME:<0-4>
Example: THEME:3
Response: Vibration confirmation
```
Changes the watch display theme.

#### Set Mode
```
Command: MODE:<0-5>
Example: MODE:1
Response: Mode switch
```
Switches watch display mode.

#### Ping
```
Command: PING
Response: PONG
```
Tests connectivity.

#### Get Status
```
Command: STATUS
Response: THEME:<id>,MODE:<id>,BATT:<percent>
Example Response: THEME:0,MODE:0,BATT:85
```

### Command Flow

```
App ──────> Watch: THEME:3
Watch ────> Watch: Parse command
Watch ────> Watch: Set currentTheme = THEME_NIGHT
Watch ────> Watch: vibrate(50)
```

---

## 9. Build & Flash

### Prerequisites

```bash
# Install PlatformIO
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py | python3

# Or via pip
pip install platformio
```

### Project Structure

```
firmware/esp32/DigitalSaverWatch/
├── DigitalSaverWatch.ino    # Main firmware
├── platformio.ini           # Build configuration
└── src/                     # Additional sources (if any)
```

### Build Commands

```bash
cd firmware/esp32/DigitalSaverWatch

# Build firmware
pio run

# Build and flash via USB
pio run --target upload

# Build and flash with flash erase
pio run --target upload --target erase

# Monitor serial output
pio device monitor --baud 115200
```

### PlatformIO Configuration

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
lib_deps = 
    adafruit/Adafruit GFX Library@^1.11.9
    adafruit/Adafruit SSD1306@^2.5.9
    sparkfun/SparkFun MAX3010x Pulse and Proximity Sensor Library@^1.1.3
monitor_speed = 115200
```

---

## 10. Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Display blank | I2C not initialized | Check SDA/SCL wiring |
| No BLE connection | Bluetooth off | Enable Bluetooth on phone |
| HR shows "--" | Sensor not on wrist | Ensure sensor contact |
| Steps not counting | MPU6050 error | Check I2C connection |
| Watch unresponsive | Low battery | Charge device |
| Theme not changing | BLE disconnect | Reconnect and retry |

### Debug Serial Output

Enable debug mode for troubleshooting:

```bash
pio device monitor --baud 115200
```

**Expected Output:**
```
[OK] Initializing sensors...
[OK] MAX30102 found
[OK] MPU6050 found
[OK] OLED initialized
[OK] BLE initialized - waiting for connection...
[BLE] Device connected
[CMD] Received: THEME:3
[THEME] Set to theme 3
```

### Factory Reset

1. Hold all buttons for 10 seconds
2. Device will reset to factory defaults
3. Reflash firmware if needed

### Recovery Flash

```bash
# Erase flash completely
esptool.py --chip esp32 erase_flash

# Flash new firmware
pio run --target upload
```

---

## Appendix: I2C Troubleshooting

### I2C Scanner Code

To find device addresses:

```cpp
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    Wire.begin();
    
    Serial.println("I2C Scanner...");
    for (byte address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        if (Wire.endTransmission() == 0) {
            Serial.print("Found: 0x");
            Serial.println(address, HEX);
        }
    }
}
```

### Expected Device Addresses

| Device | Expected Address |
|--------|-----------------|
| MAX30102 | 0x57 |
| MPU6050 | 0x68 |
| SSD1306 | 0x3C |

---

## License

© 2026 Cambric. All Rights Reserved.

This firmware is proprietary software. Redistribution and use in source and binary forms, with or without modification, is not permitted without explicit written permission from Cambric.
