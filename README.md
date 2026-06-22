# Digital Saver - Smartwatch Health Monitoring System

A comprehensive smartwatch health monitoring system designed for detecting emergencies including irregular heartbeats, high blood pressure, and loss of consciousness. Built with both hardware and software components.

---

## 📋 Index

1. [Features](#-features)
2. [Project Structure](#-project-structure)
3. [Quick Start](#-quick-start)
4. [Hardware Components](#-hardware-components)
5. [Mobile App](#-mobile-app)
6. [Firmware](#-firmware)
7. [Documentation](#-documentation)
8. [Budget](#-budget)
9. [Medical Disclaimer](#️-medical-disclaimer)
10. [License](#-license)
11. [Contributing](#-contributing)

---

## 🎯 Features

- **Real-time Heart Rate Monitoring** - PPG-based heart rate detection
- **Blood Pressure Estimation** - PPG waveform analysis for BP estimation
- **Fall Detection** - Accelerometer-based loss of consciousness detection
- **Arrhythmia Detection** - Irregular heartbeat pattern recognition
- **Emergency Alerts** - Automatic SMS and call alerts to emergency contacts
- **Multi-language Support** - 10 languages including Arabic RTL support
- **Bluetooth LE** - Low-energy communication with mobile app

---

## 📁 Project Structure

```
Digital-saver/
├── SPEC.md                    # Detailed project specification
├── README.md                  # This file
├── hardware/
│   ├── schematic/             # Circuit schematics
│   ├── pcb/                   # PCB design files
│   ├── enclosure/             # 3D print files (.stl)
│   └── firmware/
│       └── esp32/             # Arduino/PlatformIO firmware
├── mobile_app/
│   └── digital_saver/         # Flutter application
└── docs/
    ├── assembly-guide.md
    ├── user-manual.md
    └── troubleshooting.md
```

---

## 🚀 Quick Start

### Hardware Setup
1. Order components (see Hardware Components section)
2. Assemble the smartwatch (see [Assembly Guide](docs/assembly-guide.md))
3. Flash firmware using PlatformIO or Arduino IDE

### Mobile App Setup
1. Install Flutter SDK
2. Navigate to `mobile_app/digital_saver/`
3. Run `flutter pub get`
4. Run `flutter run`

---

## 🛠️ Hardware Components

| Component | Model | Purpose | Price (EGP) |
|-----------|-------|---------|-------------|
| Main MCU | ESP32-WROOM-32 | Processing + BLE | 180 |
| PPG Sensor | MAX30102 | Heart rate + SpO2 | 220 |
| Accelerometer | MPU6050 | Fall detection | 45 |
| Display | 1.3" OLED I2C | User interface | 85 |
| Battery | 500mAh LiPo | Power supply | 75 |

**Total Hardware Cost: ~3,810 EGP** (within 10,000 EGP budget)

---

## 📱 Mobile App

### Supported Languages
- English, Arabic, Spanish, French, German, Chinese, Japanese, Russian, Portuguese, Hindi

### Features
- Real-time health data display
- Emergency contact management
- Historical data tracking
- Customizable alert thresholds
- Dark mode support

---

## 🔧 Firmware (ESP32)

### Requirements
- Arduino IDE or PlatformIO
- ESP32 board package
- Required libraries (see platformio.ini)

### Upload Instructions
```bash
cd hardware/firmware/esp32
pio run --target upload
```

---

## 📖 Documentation

See `SPEC.md` for detailed:
- System architecture
- Communication protocols
- Detection algorithms
- Budget breakdown
- Implementation roadmap

---

## 💰 Budget

| Category | Cost (EGP) |
|----------|------------|
| Electronics (MCU, Sensors, Display) | 1,000 |
| Battery & Charger | 400 |
| Tools & Supplies | 900 |
| Contingency | 510 |
| **Total** | **2,810** |

✅ **Remaining from 10,000 EGP: ~7,190 EGP** for upgrades or production

---

## ⚠️ Medical Disclaimer

This device is a **wellness/screening tool** and is **NOT** a medical device. It should not be used for self-diagnosis or to replace professional medical care. Always consult healthcare professionals for medical advice.

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.
