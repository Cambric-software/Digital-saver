# Digital Saver - Smartwatch Health Monitoring System

A comprehensive smartwatch health monitoring system designed for detecting emergencies including irregular heartbeats, high blood pressure, and loss of consciousness. Built with both hardware and software components.

## 🎯 Features

- **Real-time Heart Rate Monitoring** - PPG-based heart rate detection
- **Blood Pressure Estimation** - PPG waveform analysis for BP estimation
- **Fall Detection** - Accelerometer-based loss of consciousness detection
- **Arrhythmia Detection** - Irregular heartbeat pattern recognition
- **Emergency Alerts** - Automatic SMS and call alerts to emergency contacts
- **Multi-language Support** - 10 languages including Arabic RTL support
- **Bluetooth LE** - Low-energy communication with mobile app

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
│   └── digital_saver/          # Flutter application
└── docs/
    ├── assembly-guide.md
    ├── user-manual.md
    └── troubleshooting.md
```

## 🛠️ Hardware Components

| Component | Model | Purpose |
|-----------|-------|---------|
| Main MCU | ESP32-WROOM-32 | Processing + BLE |
| PPG Sensor | MAX30102 | Heart rate + SpO2 |
| Accelerometer | MPU6050 | Fall detection |
| Display | 1.3" OLED I2C | User interface |
| Battery | 500mAh LiPo | Power supply |

**Total Hardware Cost: ~3,810 EGP** (within 10,000 EGP budget)

## 📱 Mobile App (Flutter)

### Supported Languages
- English, Arabic, Spanish, French, German, Chinese, Japanese, Russian, Portuguese, Hindi

### Features
- Real-time health data display
- Emergency contact management
- Historical data tracking
- Customizable alert thresholds
- Dark mode support

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

## 📖 Documentation

See `SPEC.md` for detailed:
- System architecture
- Communication protocols
- Detection algorithms
- Budget breakdown
- Implementation roadmap

## ⚠️ Medical Disclaimer

This device is a **wellness/screening tool** and is **NOT** a medical device. It should not be used for self-diagnosis or to replace professional medical care. Always consult healthcare professionals for medical advice.

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.
