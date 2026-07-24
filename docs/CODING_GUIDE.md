# Digital Saver - Complete Coding Guide

> **Document Version:** 2.0.0
> **Last Updated:** July 2026
> **Project:** Digital Saver Health Monitoring System
> **Company:** Cambric
> **Watch Name:** "Digital Saver" (BLE)
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Watch Name & BLE Setup](#2-watch-name--ble-setup)
3. [App Code Structure](#3-app-code-structure)
4. [Firmware Code Structure](#4-firmware-code-structure)
5. [How to Flash Onyx Watch](#5-how-to-flash-onyx-watch)
6. [Adding New Features](#6-adding-new-features)
7. [Debugging](#7-debugging)
8. [Testing](#8-testing)
9. [Code Style](#9-code-style)
10. [Common Patterns](#10-common-patterns)
11. [BLE Protocol Reference](#11-ble-protocol-reference)

---

## 1. Overview

This guide covers how to code both the **Flutter Mobile App** and **ESP32 Watch Firmware**.

### Technology Stack

| Component | Technology | Language |
|-----------|------------|----------|
| Mobile App | Flutter 3.27 | Dart |
| Watch Firmware | ESP32 + Arduino | C++ |
| State Management | Provider | Dart |
| Backend | Supabase | PostgreSQL |
| Communication | BLE | JSON |

### Project Structure

```
Digital-saver/
├── app/                    # Flutter mobile app
│   └── lib/
│       ├── main.dart      # Entry point
│       ├── screens/       # UI screens
│       ├── services/      # BLE, auth, health analysis
│       ├── models/        # Data models
│       └── providers/    # State management
├── firmware/              # Watch firmware
│   └── esp32/
│       └── DigitalSaverWatch/
│           ├── DigitalSaverWatch.ino  # Main firmware
│           └── platformio.ini         # Build config
├── docs/                  # Documentation
│   ├── APP_ARCHITECTURE.md
│   ├── CODING_GUIDE.md   # This file
│   ├── DATABASE_SCHEMA.md
│   ├── DEVELOPMENT_GUIDE.md
│   └── WATCH_FIRMWARE.md
├── .github/
│   └── workflows/        # CI/CD builds
└── README.md             # Entry point
```

---

## 2. Watch Name & BLE Setup

### Watch BLE Name
```
Digital Saver
```

### BLE Configuration

**Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
**Characteristic UUID:** `beb5483e-36e1-4688-b7f5-ea07361b26a8`

### Where to Find in Code

**In Firmware** (`firmware/esp32/DigitalSaverWatch/DigitalSaverWatch.ino`):
```cpp
// Line 376 - BLE Device Name
BLEDevice::init("Digital Saver");

// Line 60-61 - BLE UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
```

**In App** (`app/lib/services/ble_service.dart`):
```dart
// Lines 21-28 - Watch Detection Keywords
const List<String> kSmartwatchKeywords = [
  'watch', 'band', 'fitness', 'tracker', 'wearable', 'smart',
  'onyx', 'digital', 'saver', 'cambric',  // These keywords detect our watch
  'apple', 'watch', 'stratos', 'tread', 'pace', 'ignite', 'charge', 'versa',
  'fitbit', 'garmin', 'huawei', 'xiaomi', 'samsung'
];
```

---

## 3. App Code Structure

### Directory Layout

```
app/lib/
├── main.dart                 # Entry point
├── app.dart                  # App configuration
├── core/
│   ├── constants/           # App-wide constants
│   ├── theme/               # Themes (light/dark)
│   └── utils/                # Utility functions
├── models/                   # Data models
├── providers/                # State management
├── services/                 # Business logic & BLE
├── screens/                  # UI screens
└── widgets/                  # Reusable widgets
```

### Key Files

| File | Path | Purpose |
|------|------|---------|
| `main.dart` | `app/lib/main.dart` | App entry, Supabase init |
| `ble_service.dart` | `app/lib/services/ble_service.dart` | Watch BLE communication |
| `health_analysis_service.dart` | `app/lib/services/health_analysis_service.dart` | HRV, BP calculations |
| `cambric_auth_service.dart` | `app/lib/services/cambric_auth_service.dart` | User authentication |
| `auth_screen.dart` | `app/lib/screens/auth_screen.dart` | Login/register UI |
| `dashboard_screen.dart` | `app/lib/screens/dashboard_screen.dart` | Main health overview |

---

## 4. Firmware Code Structure

### Files
```
firmware/esp32/DigitalSaverWatch/
├── DigitalSaverWatch.ino     # Complete firmware (1143 lines)
└── platformio.ini            # Build configuration
```

### Firmware Sections (DigitalSaverWatch.ino)

| Section | Lines | Description |
|---------|-------|-------------|
| Header & Includes | 1-30 | Version info, libraries |
| Configuration | 50-90 | Pins, UUIDs, thresholds |
| Global Objects | 100-140 | Display, sensors, BLE |
| HealthData Struct | 140-200 | All health metrics |
| Setup | 200-300 | Hardware initialization |
| Loop | 300-400 | Main logic |
| BLE Functions | 400-500 | BLE callbacks |
| Sensor Functions | 500-600 | Read MAX30102, MPU6050 |
| Health Algorithms | 600-700 | HRV, BP, fall detection |
| Display Functions | 700-900 | OLED rendering |
| Utility Functions | 900-1143 | Time, vibration, emergency |

---

## 5. How to Flash Onyx Watch

### Method 1: PlatformIO (Recommended)

#### Step 1: Install PlatformIO
```bash
# Install VS Code extension
# Or install via command line:
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py | python3
```

#### Step 2: Open Project
```bash
cd firmware/esp32/DigitalSaverWatch
code .
# Open in VS Code with PlatformIO extension
```

#### Step 3: Connect ESP32
1. Connect ESP32 via USB-C cable
2. Hold **BOOT** button
3. Press and release **RESET** button
4. Release **BOOT** button (enters bootloader mode)

#### Step 4: Upload Firmware
```bash
# In PlatformIO terminal:
pio run -t upload

# Or with monitor:
pio run -t upload -monitor
```

#### Step 5: Monitor Output
```bash
pio device monitor
# Should see: "Digital Saver v3.0.0 started"
```

---

### Method 2: Arduino IDE

#### Step 1: Install Arduino ESP32 Board
1. Arduino IDE -> File -> Preferences
2. Add URL: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Tools -> Board -> Board Manager -> ESP32 -> Install

#### Step 2: Install Libraries
```
Sketch -> Include Library -> Manage Libraries:
- Adafruit GFX Library
- Adafruit SSD1306
- SparkFun MAX3010x
- Adafruit MPU6050
```

#### Step 3: Open Firmware
1. Copy `DigitalSaverWatch.ino` content
2. Create new sketch in Arduino IDE
3. Paste content

#### Step 4: Configure & Upload
1. Tools -> Board -> ESP32 Dev Module
2. Tools -> Port -> COMX (your port)
3. Hold BOOT + press RESET on ESP32
4. Click Upload

---

### Method 3: OTA (Over-The-Air) - After Initial Flash

```cpp
// Add to firmware for OTA updates
#include <ArduinoOTA.h>

void setup() {
  // ... existing setup ...
  
  // Setup OTA
  ArduinoOTA.begin();
}

void loop() {
  ArduinoOTA.handle();  // Allows upload via network
}
```

Upload via Arduino IDE (Tools -> Port -> Network Ports)

---

## 6. Adding a New Screen

### Step 1: Create the Screen File

Create `app/lib/screens/new_feature_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/health_analysis_service.dart';

class NewFeatureScreen extends StatefulWidget {
  const NewFeatureScreen({super.key});

  @override
  State<NewFeatureScreen> createState() => _NewFeatureScreenState();
}

class _NewFeatureScreenState extends State<NewFeatureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Feature'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<BleService>(
        builder: (context, ble, child) {
          if (!ble.isConnected) {
            return const Center(
              child: Text('Connect to watch first'),
            );
          }
          
          // Your UI here
          return Center(
            child: Text('Data: ${ble.healthData.someMetric}'),
          );
        },
      ),
    );
  }
}
```

### Step 2: Add Navigation

In `dashboard_screen.dart`, add to bottom navigation:

```dart
bottomNavigationBar: NavigationBar(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) {
    setState(() => _selectedIndex = index);
    // Add: case 6: Navigator.push(context, MaterialPageRoute(builder: (_) => NewFeatureScreen()));
  },
  destinations: const [
    NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.favorite), label: 'Heart'),
    NavigationDestination(icon: Icon(Icons.speed), label: 'BP'),
    NavigationDestination(icon: Icon(Icons.directions_walk), label: 'Activity'),
    NavigationDestination(icon: Icon(Icons.bedtime), label: 'Sleep'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
    // Add: NavigationDestination(icon: Icon(Icons.new_icon), label: 'New'),
  ],
)
```

---

## 4. Adding a New Health Metric

### Step 1: Update HealthData Model

In `models/health_models.dart`:

```dart
class HealthData {
  // Existing fields...
  double heartRate;
  double spO2;
  
  // Add new metric
  double stressLevel;
  DateTime timestamp;
  
  HealthData({
    this.heartRate = 0,
    this.spO2 = 0,
    this.stressLevel = 0,  // NEW
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      heartRate: (json['hr'] ?? 0).toDouble(),
      spO2: (json['spo2'] ?? 0).toDouble(),
      stressLevel: (json['stress'] ?? 0).toDouble(),  // NEW
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'hr': heartRate,
    'spo2': spO2,
    'stress': stressLevel,  // NEW
    'timestamp': timestamp.toIso8601String(),
  };
}
```

### Step 2: Add to BLE Service

In `services/ble_service.dart`:

```dart
class BleService extends ChangeNotifier {
  HealthData healthData = HealthData();
  
  void parseData(String jsonString) {
    try {
      final data = json.decode(jsonString);
      healthData = HealthData.fromJson(data);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
  
  // Add helper getter
  double get stressLevel => healthData.stressLevel;
}
```

### Step 3: Display in UI

```dart
// In your screen
Consumer<BleService>(
  builder: (context, ble, child) {
    return Card(
      child: Column(
        children: [
          Text('Stress Level: ${ble.stressLevel.toStringAsFixed(1)}'),
          // Progress indicator
          LinearProgressIndicator(
            value: ble.stressLevel / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              ble.stressLevel > 70 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  },
)
```

---

## 5. Firmware Code Structure

### File: DigitalSaverWatch.ino

The complete firmware is in a single file for ESP32:

```cpp
// ============================================
//           CONFIGURATION
// ============================================
// Pins, UUIDs, thresholds, timing

// ============================================
//           GLOBAL OBJECTS
// ============================================
// Display, sensors, BLE

// ============================================
//           HEALTH DATA STRUCTURES
// ============================================
// HealthData struct with all metrics

// ============================================
//           SETUP & LOOP
// ============================================
// setup(), loop()

// ============================================
//           BLE FUNCTIONS
// ============================================
// BLEDevice, BLEServer, callbacks

// ============================================
//           SENSOR FUNCTIONS
// ============================================
// initMAX30102(), initMPU6050(), readSensors()

// ============================================
//           HEALTH ALGORITHMS
// ============================================
// calculateHRV(), estimateBP(), detectFall()

// ============================================
//           DISPLAY FUNCTIONS
// ============================================
// updateDisplay(), showHeartScreen(), etc.

// ============================================
//           UTILITY FUNCTIONS
// ============================================
// formatTime(), vibrate(), triggerEmergency()
```

### Key Firmware Components

| Section | Functions | Purpose |
|---------|-----------|---------|
| Configuration | `#define` | Pins, UUIDs, thresholds |
| HealthData | struct | Data container |
| Setup | `setup()` | Initialize hardware |
| Loop | `loop()` | Main logic |
| BLE | `BLECallbacks` | Phone communication |
| Sensors | `readSensors()` | Read MAX30102, MPU6050 |
| Algorithms | `calculateHRV()` | Health calculations |
| Display | `updateDisplay()` | OLED rendering |

---

## 6. Adding Firmware Features

### Adding a New Sensor

```cpp
// 1. Define pins
#define NEW_SENSOR_PIN 32

// 2. Add to setup()
void setup() {
  // ... existing setup ...
  
  // Initialize new sensor
  pinMode(NEW_SENSOR_PIN, INPUT);
}

// 3. Add read function
float readNewSensor() {
  int rawValue = analogRead(NEW_SENSOR_PIN);
  // Convert to real units
  float value = rawValue * 3.3 / 4095.0;
  return value;
}

// 4. Add to main data in loop()
void loop() {
  // Read sensor
  float newValue = readNewSensor();
  
  // Include in BLE data
  char buffer[256];
  snprintf(buffer, sizeof(buffer),
    "{\"hr\":%.0f,\"spo2\":%.0f,\"new\":%.2f}",
    healthData.heartRate,
    healthData.spO2,
    newValue
  );
  
  // Send via BLE
  pCharacteristic->setValue(buffer);
  pCharacteristic->notify();
}
```

### Adding BLE Command Handler

```cpp
// In BLECallbacks class
class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String command = pCharacteristic->getValue().c_str();
    
    if (command.startsWith("CONFIG:")) {
      // Parse config
      String value = command.substring(7);
      applyConfiguration(value);
    }
    else if (command.startsWith("CALIBRATE:")) {
      // Run calibration
      calibrateSensors();
    }
  }
};

void applyConfiguration(String config) {
  // Parse JSON-like: "key:value,key2:value2"
  // Apply to firmware
}

void calibrateSensors() {
  // Calibration routine
}
```

---

## 7. Debugging

### App Debugging

```dart
// Use debugPrint for console output
debugPrint('Health data: ${ble.healthData.heartRate}');

// Use breakpoints in VS Code/Android Studio

// Check BLE connection
if (ble.isConnected) {
  debugPrint('Watch connected');
} else {
  debugPrint('Watch disconnected');
}
```

### Firmware Debugging

```cpp
// Serial output
Serial.begin(115200);
Serial.println("Starting...");

// Conditional debug
#ifdef DEBUG
  Serial.print("HR: ");
  Serial.println(healthData.heartRate);
#endif

// Check sensor connection
if (!particleSensor.begin()) {
  Serial.println("MAX30102 not found!");
  while(1);
}
```

### PlatformIO Debug Commands

```bash
# Upload and monitor
pio run -t upload -monitor

# Build only
pio run

# Clean and rebuild
pio run --target clean
pio run
```

---

## 8. Testing Without Hardware

### App Demo Mode

The app has a demo mode for testing without a watch:

```dart
// In ble_service.dart
class BleService extends ChangeNotifier {
  bool demoMode = true;  // Enable for testing
  
  void startDemoMode() {
    demoMode = true;
    Timer.periodic(Duration(seconds: 1), (timer) {
      healthData = HealthData(
        heartRate: 60 + Random().nextInt(40),
        spO2: 95 + Random().nextInt(5),
        // Random demo data
      );
      notifyListeners();
    });
  }
}
```

### Firmware Simulation

Test firmware logic without actual hardware:

```cpp
// Use mock sensor values
void loop() {
  #ifdef SIMULATE
    // Simulated data for testing
    healthData.heartRate = 70 + random(-5, 5);
    healthData.spO2 = 97 + random(-2, 0);
  #else
    // Real sensor reading
    readSensors();
  #endif
  
  // Continue with normal flow
  sendBLEData();
  updateDisplay();
}
```

Compile with: `-DSIMULATE` flag in platformio.ini

---

## 9. Common Patterns

### Provider Pattern (App)

```dart
// Provide data from anywhere
class MyProvider extends ChangeNotifier {
  int _value = 0;
  int get value => _value;
  
  void update(int newValue) {
    _value = newValue;
    notifyListeners();  // Update all listeners
  }
}

// Use in widget
Consumer<MyProvider>(
  builder: (context, provider, child) {
    return Text('Value: ${provider.value}');
  },
)
```

### Callback Pattern (Firmware)

```cpp
// BLE connection callbacks
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  }
  
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");
  }
};
```

### State Machine Pattern

```cpp
enum WatchMode {
  MODE_CLOCK,
  MODE_HEART,
  MODE_BP,
  MODE_ACTIVITY,
  MODE_SLEEP,
  MODE_SETTINGS
};

WatchMode currentMode = MODE_CLOCK;

void handleButtonPress() {
  switch(currentMode) {
    case MODE_CLOCK:
      currentMode = MODE_HEART;
      break;
    case MODE_HEART:
      currentMode = MODE_BP;
      break;
    // ... etc
  }
}
```

---

## 10. BLE Protocol Reference

### Data Format (JSON)

```json
{
  "hr": 72,
  "spo2": 97,
  "bp_sys": 120,
  "bp_dia": 80,
  "hrv": 45.2,
  "steps": 5420,
  "sleep_deep": 45,
  "sleep_light": 120,
  "battery": 85,
  "fall": false,
  "timestamp": "2026-07-24T10:30:00Z"
}
```

### Commands (App -> Watch)

| Command | Purpose | Example |
|---------|---------|---------|
| `PING` | Check connection | `PING` |
| `CONFIG:brightness:5` | Set setting | `CONFIG:key:value` |
| `SYNC:start` | Start sync | `SYNC:start` |

### Responses (Watch -> App)

| Response | Purpose | Example |
|----------|---------|---------|
| `OK` | Command success | `OK` |
| `ERROR:reason` | Command failed | `ERROR:invalid_param` |
| `ALERT:EMERGENCY` | Emergency trigger | `ALERT:EMERGENCY` |

---

## 11. File-by-File Guide

### App Files

#### main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(url: url, anonKey: key);
  
  // Initialize services
  await StorageService.init();
  
  runApp(const DigitalSaverApp());
}
```

#### services/ble_service.dart
- Manages BLE connection
- Scans for watch by name
- Parses JSON health data
- Notifies UI on updates

#### services/health_analysis_service.dart
- HRV calculation (RMSSD, SDNN)
- Blood pressure estimation
- Sleep stage classification
- Health score algorithm

#### screens/dashboard_screen.dart
- Main entry point after auth
- Shows connection status
- Quick health overview
- Navigation to other screens

### Firmware Files

#### DigitalSaverWatch.ino
- Complete firmware in one file
- Modular sections with clear comments
- 1000+ lines of code
- All features implemented

#### platformio.ini
- PlatformIO configuration
- Library dependencies
- Build flags

---

**Document Version:** 1.0.0
**Last Updated:** July 2026
**Author:** Cambric Engineering Team
**Copyright © 2026 Cambric. All Rights Reserved.
