# Digital Saver - Project Guide

> **Version:** 3.0.0 | **Updated:** July 2026 | **Company:** Cambric

This guide tells you **where to go** for everything in this project.

---

## Quick Navigation

| What You Need | Go Here |
|---------------|---------|
| I want to understand the project | [README.md](./README.md) |
| I want to code the app | [docs/CODING_GUIDE.md](./docs/CODING_GUIDE.md) |
| I want to flash the watch | [docs/CODING_GUIDE.md#5-how-to-flash-onyx-watch](./docs/CODING_GUIDE.md#5-how-to-flash-onyx-watch) |
| I want to understand app architecture | [docs/APP_ARCHITECTURE.md](./docs/APP_ARCHITECTURE.md) |
| I want to understand the database | [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) |
| I want to build the watch hardware | [docs/WATCH_FIRMWARE.md](./docs/WATCH_FIRMWARE.md) |
| I want to set up dev environment | [docs/DEVELOPMENT_GUIDE.md](./docs/DEVELOPMENT_GUIDE.md) |
| I want to see release info | [GitHub Releases](https://github.com/Cambric-software/Digital-saver/releases) |

---

## Project Overview

```
Digital Saver is a smartwatch health monitoring system.

┌──────────────┐         BLE          ┌──────────────┐
│  ONYX WATCH   │◄──────────────────►│  MOBILE APP  │
│  (ESP32)      │                    │  (Flutter)   │
│               │                    │              │
│  Sensors:     │                    │  Screens:    │
│  - MAX30102   │                    │  - Dashboard │
│  - MPU6050    │                    │  - Heart     │
│  - OLED       │                    │  - BP        │
│               │                    │  - Sleep     │
└──────────────┘                    └──────────────┘
       │                                    │
       │                                    ▼
       │                            ┌──────────────┐
       │                            │  SUPABASE    │
       │                            │  Database    │
       │                            └──────────────┘
```

---

## Project Structure

```
Digital-saver/
│
├── app/                          # FLUTTER MOBILE APP
│   └── lib/
│       ├── main.dart             # App entry point
│       ├── app.dart              # MaterialApp config
│       │
│       ├── screens/              # USER INTERFACES
│       │   ├── auth_screen.dart      # Login/Register
│       │   ├── dashboard_screen.dart # Main health view
│       │   ├── heart_screen.dart     # Heart rate details
│       │   ├── bp_screen.dart        # Blood pressure
│       │   ├── activity_screen.dart   # Steps, calories
│       │   ├── sleep_screen.dart      # Sleep tracking
│       │   └── settings_screen.dart   # App settings
│       │
│       ├── services/              # BUSINESS LOGIC
│       │   ├── ble_service.dart              # BLE watch connection
│       │   ├── cambric_auth_service.dart     # User authentication
│       │   ├── health_analysis_service.dart   # HRV, BP calculations
│       │   ├── storage_service.dart           # Local storage
│       │   └── emergency_service.dart         # SOS alerts
│       │
│       ├── models/                # DATA MODELS
│       │   └── health_models.dart  # Health data structures
│       │
│       ├── providers/             # STATE MANAGEMENT
│       │   └── *.dart             # Provider classes
│       │
│       └── theme/                 # STYLING
│           └── app_theme.dart     # Light/Dark themes
│
├── firmware/                      # WATCH FIRMWARE
│   └── esp32/
│       └── DigitalSaverWatch/
│           ├── DigitalSaverWatch.ino  # Main firmware (C++)
│           └── platformio.ini         # Build config
│
├── docs/                          # DOCUMENTATION
│   ├── GUIDE.md                   # THIS FILE - Navigation
│   ├── README.md                  # Entry point
│   ├── SECURITY.md                # Security info
│   │
│   ├── APP_ARCHITECTURE.md        # App structure details
│   ├── CODING_GUIDE.md            # How to code & flash
│   ├── DATABASE_SCHEMA.md         # Database design
│   ├── DEVELOPMENT_GUIDE.md        # Dev environment setup
│   └── WATCH_FIRMWARE.md          # Watch hardware & firmware
│
├── .github/
│   └── workflows/                 # CI/CD AUTOMATION
│       ├── release_build.yml      # Android APK build
│       ├── build_web.yml          # Web build
│       └── deploy.yml             # GitHub Pages
│
└── README.md                      # Main entry point
```

---

## What Each Part Does

### Mobile App (Flutter)

| Screen | File | What It Does |
|--------|------|--------------|
| **Auth** | `auth_screen.dart` | Login, register, password reset |
| **Dashboard** | `dashboard_screen.dart` | Health overview, watch status |
| **Heart** | `heart_screen.dart` | Heart rate, HRV, stress level |
| **Blood Pressure** | `bp_screen.dart` | BP estimation, MAP, AHA classification |
| **Activity** | `activity_screen.dart` | Steps, calories, distance |
| **Sleep** | `sleep_screen.dart` | Sleep stages, duration |
| **Settings** | `settings_screen.dart` | Profile, emergency contacts, downloads |

### Services

| Service | File | What It Does |
|---------|------|--------------|
| **BLE** | `ble_service.dart` | Connect to watch via Bluetooth |
| **Auth** | `cambric_auth_service.dart` | Handle user login with Supabase |
| **Health** | `health_analysis_service.dart` | Calculate HRV, BP, sleep stages |
| **Emergency** | `emergency_service.dart` | Send SOS alerts |
| **Storage** | `storage_service.dart` | Save data locally |

### Watch Firmware (ESP32)

| File | What It Does |
|------|--------------|
| `DigitalSaverWatch.ino` | All watch logic in one file |
| `platformio.ini` | Build settings, libraries |

### Firmware Sections (in DigitalSaverWatch.ino)

| Section | Lines | Description |
|---------|-------|-------------|
| Configuration | 50-90 | Pins, BLE UUIDs, thresholds |
| HealthData | 140-200 | All health metrics struct |
| Setup | 200-300 | Initialize sensors, BLE, display |
| Loop | 300-400 | Main update cycle |
| BLE | 400-500 | Phone communication |
| Sensors | 500-600 | Read MAX30102, MPU6050 |
| Health Algorithms | 600-700 | HRV, BP, fall detection |
| Display | 700-900 | OLED screen rendering |

---

## Where to Find Things

### Watch Connection

| Info | Location |
|------|----------|
| Watch BLE Name | `DigitalSaverWatch.ino` line 376 |
| Service UUID | `DigitalSaverWatch.ino` line 60 |
| Characteristic UUID | `DigitalSaverWatch.ino` line 61 |
| Scan Keywords | `ble_service.dart` lines 21-28 |

### Health Data

| Metric | Calculated In | Display In |
|--------|---------------|------------|
| Heart Rate | Watch firmware | `heart_screen.dart` |
| SpO2 | Watch firmware | `heart_screen.dart` |
| HRV (RMSSD) | `health_analysis_service.dart` | `heart_screen.dart` |
| Blood Pressure | `health_analysis_service.dart` | `bp_screen.dart` |
| Steps | Watch firmware | `activity_screen.dart` |
| Sleep Stages | Watch + app | `sleep_screen.dart` |

### Database

| Table | Purpose |
|-------|---------|
| `user_profiles` | User info, settings |
| `health_logs` | Health measurements |
| `devices` | Paired watches |
| `emergency_contacts` | SOS contacts |
| `health_goals` | Daily targets |

See: [docs/DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md)

### Authentication

| Info | Location |
|------|----------|
| Supabase Config | `app/.env` or `app/lib/core/constants/` |
| Auth Logic | `cambric_auth_service.dart` |
| Auth UI | `auth_screen.dart` |
| Auth State | Provider pattern in `providers/` |

---

## Build & Release

### Android APK
- **Location:** GitHub Releases
- **Workflow:** `.github/workflows/release_build.yml`
- **Build Command:** `flutter build apk --release`

### Web App
- **Location:** GitHub Pages
- **Workflow:** `.github/workflows/build_web.yml`

### Watch Firmware
- **Tool:** PlatformIO or Arduino IDE
- **Command:** `pio run -t upload`

---

## Common Tasks

| Task | How To |
|------|--------|
| Add new screen | See [CODING_GUIDE.md](./docs/CODING_GUIDE.md#6-adding-a-new-screen) |
| Add new metric | See [CODING_GUIDE.md](./docs/CODING_GUIDE.md#6-adding-a-new-screen) |
| Flash watch | See [CODING_GUIDE.md](./docs/CODING_GUIDE.md#5-how-to-flash-onyx-watch) |
| Change BLE UUID | Edit `DigitalSaverWatch.ino` + `ble_service.dart` |
| Add database table | See [DATABASE_SCHEMA.md](./docs/DATABASE_SCHEMA.md) |
| Change auth flow | Edit `cambric_auth_service.dart` |

---

## File Permissions

| File | Read | Write |
|------|------|-------|
| `app/lib/screens/*` | Anyone | Dev team |
| `app/lib/services/*` | Anyone | Dev team |
| `firmware/*` | Anyone | Dev team |
| `docs/*` | Anyone | Dev team |
| `.github/workflows/*` | Anyone | Dev team |
| `.env` | **PRIVATE** | **NEVER COMMIT** |

---

## Contact & Support

- **Company:** Cambric
- **Email:** support@cambric.example.com
- **Documentation:** `/docs`
- **GitHub Issues:** [Link](https://github.com/Cambric-software/Digital-saver/issues)

---

**Version:** 3.0.0 | **Last Updated:** July 2026
