# Digital Saver Onyx Smartwatch Firmware

**Version:** 1.0.0  
**Status:** Development  
**Target:** ESP32-WROOM-32  

---

## Overview

Complete firmware for the Digital Saver Onyx smartwatch. This firmware provides:

- Real-time heart rate and SpO2 monitoring
- Blood pressure estimation
- Fall detection and emergency alerts
- Activity tracking (steps, calories, distance)
- Sleep quality analysis
- **8x Enhanced Smart AI** for on-device health analysis
- BLE communication with mobile app
- OLED display with multiple watch faces

---

## Hardware Requirements

| Component | Model | Purpose |
|-----------|-------|---------|
| MCU | ESP32-WROOM-32 | Main processor |
| Heart Rate | MAX30102 | HR + SpO2 sensor |
| Accelerometer | MPU6050 | Fall detection, steps |
| Display | SSD1306 128x64 | OLED screen |
| Battery | 350mAh LiPo | Power |
| Charger | TP4056 | Battery charging |

---

## Directory Structure

```
firmware/esp32/DigitalSaverOnyx/
├── platformio.ini           # PlatformIO configuration
├── src/
│   ├── main.cpp              # Main firmware
│   ├── sensors/
│   │   ├── MAX30102_sensor.h/cpp    # Heart rate & SpO2
│   │   ├── MPU6050_sensor.h/cpp     # Accelerometer
│   │   └── Battery_sensor.h          # Battery monitoring
│   ├── ble/
│   │   └── BLECommunication.h/cpp    # BLE communication
│   ├── display/
│   │   ├── SSD1306_display.h/cpp    # Display driver
│   │   ├── WatchFaces.h/cpp         # Watch face styles
│   │   └── HealthScreens.h/cpp      # Health data screens
│   ├── emergency/
│   │   └── EmergencySystem.h/cpp     # Fall detection, SOS
│   ├── ai/
│   │   ├── OnyxSmartAI.h/cpp        # 8x Enhanced AI
│   │   ├── HealthPredictor.h/cpp      # Health predictions
│   │   └── PatternAnalyzer.h/cpp     # Pattern detection
│   └── utils/
│       ├── HealthCalculations.h/cpp   # BMR, calories, etc.
│       ├── ActivityTracker.h/cpp      # Step counting
│       ├── SleepTracker.h            # Sleep analysis
│       └── ConfigManager.h           # Flash storage
└── README.md
```

---

## Features

### Health Monitoring

- **Heart Rate**: Real-time BPM with HRV analysis
- **SpO2**: Blood oxygen percentage
- **Blood Pressure**: Estimated from HRV and PTT
- **Activity**: Step counting, calories, distance
- **Sleep**: Quality, deep sleep, REM tracking

### Smart AI (8x Enhanced)

The on-device AI provides:
- Real-time health risk scoring (0-100)
- Pattern detection (tachycardia, hypoxia, stress)
- Age and condition-adjusted thresholds
- Trend analysis
- Emergency alert triggers

### Emergency System

- **Fall Detection**: Accelerometer-based with LOC detection
- **SOS Button**: User-triggered emergency
- **Auto Alerts**: High/low HR, low SpO2, AI risk
- **BLE Alerts**: Notifications to phone

### Display Screens

1. Watch Face (Digital/Analog/Minimal)
2. Heart Rate
3. SpO2
4. Blood Pressure
5. Activity
6. Sleep
7. AI Dashboard
8. Settings

---

## Building

### PlatformIO

```bash
cd firmware/esp32/DigitalSaverOnyx
pio run
pio run --target upload
```

### Arduino IDE

1. Install ESP32 board support
2. Select "ESP32 Dev Module"
3. Set partition scheme: "Huge APP"
4. Upload all `.cpp` and `.h` files from `src/`

---

## Configuration

User profile is stored in flash and includes:
- Name, age, gender
- Height, weight
- Blood type
- Medical conditions
- Emergency contact

Update via BLE or through the mobile app.

---

## BLE Protocol

Service UUID: `6e400001-b5a3-f393-e0a9-e50e24dcca9e`

Packet types:
- `0x01`: Health data
- `0x02`: Activity data
- `0x03`: Sleep data
- `0x04`: Emergency alert
- `0x05`: Command
- `0x06`: Profile

---

## License

© 2026 Cambric. All Rights Reserved.  
Egyptian Government Funded Project - Digital Egypt Initiative
