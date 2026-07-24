# Digital Saver Onyx Watch - Complete Firmware Documentation

> **Document Version:** 1.0.0  
> **Last Updated:** July 2026  
> **Watch Model:** Onyx (Digital Saver Smartwatch)  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

## Table of Contents

1. [Hardware Overview](#1-hardware-overview)
2. [Pin Configuration](#2-pin-configuration)
3. [I2C Communication](#3-i2c-communication)
4. [Sensor Specifications](#4-sensor-specifications)
5. [BLE Protocol](#5-ble-protocol)
6. [Firmware Architecture](#6-firmware-architecture)
7. [Power Management](#7-power-management)
8. [Emergency System](#8-emergency-system)
9. [Display System](#9-display-system)
10. [Build & Flash Instructions](#10-build--flash-instructions)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Hardware Overview

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
│           │  GPIO21 (SDA)    │                                      │
│           │  GPIO22 (SCL)    │                                      │
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

## 2. Pin Configuration

### ESP32 Pinout

```
┌────────────────────────────────────────────┐
│              ESP32-WROOM-32               │
├────────────────────────────────────────────┤
│                                            │
│  3V3  ──────────────────────  (Power)       │
│  GND  ──────────────────────  (Ground)     │
│                                            │
│  GPIO21  ──────────────────  I2C SDA      │
│  GPIO22  ──────────────────  I2C SCL      │
│                                            │
│  GPIO5   ──────────────────  (Unused)       │
│  GPIO17  ──────────────────  (Unused)     │
│                                            │
│  GPIO35  ──────────────────  (ADC Battery) │
│                                            │
│  GPIO0   ──────────────────  (Boot Mode)   │
│  EN     ──────────────────  (Enable)      │
│                                            │
└────────────────────────────────────────────┘
```

### I2C Bus Connections

```
ESP32 GPIO21 (SDA) ──┬── MAX30102 SDA
                     │
                     ├── MPU6050 SDA  
                     │
                     └── OLED SSD1306 SDA

ESP32 GPIO22 (SCL) ──┬── MAX30102 SCL
                     │
                     ├── MPU6050 SCL
                     │
                     └── OLED SSD1306 SCL

3V3 ─────────────────┬── MAX30102 VCC
                     ├── MPU6050 VCC
                     └── OLED VCC

GND ─────────────────┬── MAX30102 GND
                     ├── MPU6050 GND
                     └── OLED GND
```

### Power System

```
Battery (3.7V LiPo) ──── TP4056 IN+ / IN-
                          │
                          ├─────── Battery Level ADC (GPIO35)
                          │
                          └─────── ESP32 3V3 (via LDO regulator)
```

---

## 3. I2C Communication

### I2C Address Map

| Device | I2C Address | Notes |
|--------|-------------|-------|
| MAX30102 | 0x57 | Heart rate + SpO2 |
| MPU6050 | 0x68 | Accelerometer + Gyro |
| SSD1306 | 0x3C | OLED Display |

### I2C Initialization Code

```cpp
#include <Wire.h>

// I2C pins
#define I2C_SDA 21
#define I2C_SCL 22

void setupI2C() {
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000); // 400kHz Fast Mode
  
  // Initialize sensors
  initMAX30102();
  initMPU6050();
  initOLED();
}
```

### I2C Scanning Code

```cpp
void scanI2CDevices() {
  Serial.println("Scanning I2C devices...");
  
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("Device found at 0x");
      Serial.println(address, HEX);
    }
  }
}
```

---

## 4. Sensor Specifications

### MAX30102 PPG Sensor

#### Features
- Heart rate measurement (30-210 BPM)
- SpO2 measurement (70-100%)
- Red LED (660nm) + IR LED (880nm)
- I2C interface
- Low power consumption

#### Register Map (Key Registers)

| Register | Address | Function |
|----------|---------|----------|
| MODE_CONFIG | 0x09 | Mode selection |
| SpO2_CONFIG | 0x0A | LED pulse rate, width |
| LED_RED_PA | 0x0C | Red LED pulse amplitude |
| LED_IR_PA | 0x0D | IR LED pulse amplitude |
| FIFO_DATA | 0x07 | FIFO read pointer |
| FIFO_WR_PTR | 0x04 | FIFO write pointer |

#### MAX30102 Code

```cpp
#include <MAX30105.h>
#include <heartRate.h>

MAX30105 particleSensor;

void initMAX30102() {
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30105 not found!");
    while (1);
  }
  
  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  particleSensor.setPulseAmplitudeIR(0x0A);
}

void readHeartRate() {
  long irValue = particleSensor.getIR();
  
  if (checkForBeat(irValue) == true) {
    // Calculate BPM
    float delta = millis() - lastBeat;
    lastBeat = millis();
    float bpm = 60 / (delta / 1000.0);
    
    if (bpm > 30 && bpm < 210) {
      Serial.print("BPM: ");
      Serial.println(bpm);
    }
  }
}
```

### MPU6050 Accelerometer

#### Features
- 3-axis accelerometer
- 3-axis gyroscope
- Digital output
- I2C interface
- Low power

#### MPU6050 Code

```cpp
#include <MPU6050.h>

MPU6050 mpu;

void initMPU6050() {
  mpu.initialize();
  
  if (!mpu.testConnection()) {
    Serial.println("MPU6050 connection failed!");
    while (1);
  }
  
  // Configure accelerometer
  mpu.setFullScaleAccelRange(MPU6050_ACCEL_FS_2);
  mpu.setFullScaleGyroRange(MPU6050_GYRO_FS_250);
}

void readAccelerometer() {
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);
  
  // Convert to g
  float accelX = ax / 16384.0;
  float accelY = ay / 16384.0;
  float accelZ = az / 16384.0;
  
  // Calculate total acceleration
  float totalAccel = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);
  
  Serial.print("Total Accel: ");
  Serial.println(totalAccel);
}

void detectFall() {
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);
  
  // Calculate g-force
  float gForce = sqrt(ax*ax + ay*ay + az*az) / 16384.0;
  
  // Fall threshold: > 2.5g for 100ms
  if (gForce > 2.5) {
    fallDetected = true;
    triggerEmergency();
  }
}
```

---

## 5. BLE Protocol

### Service Configuration

| Property | Value |
|----------|-------|
| Device Name | `Digital Saver` |
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Characteristic UUID | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| Data Format | JSON string |
| Update Rate | 1 Hz (every second) |

### BLE Initialization

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer;
BLEService* pService;
BLECharacteristic* pCharacteristic;

void initBLE() {
  BLEDevice::init("Digital Saver");
  
  pServer = BLEDevice::createServer();
  pService = pServer->createService(SERVICE_UUID);
  
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  
  pServer->getAdvertising()->start();
}
```

### JSON Data Format

```cpp
void sendHealthData() {
  StaticJsonDocument<256> doc;
  
  doc["hr"] = currentHeartRate;        // Heart rate (BPM)
  doc["spo2"] = currentSpO2;          // Blood oxygen (%)
  doc["bps"] = systolicBP;             // Systolic BP (mmHg)
  doc["bpd"] = diastolicBP;           // Diastolic BP (mmHg)
  doc["hrv"] = hrvRMSSD;              // HRV RMSSD (ms)
  doc["steps"] = stepCount;            // Step count
  doc["cal"] = caloriesBurned;         // Calories
  doc["temp"] = bodyTemperature;       // Temperature (°C)
  doc["irreg"] = irregularHeartbeat;   // 0 or 1
  doc["fall"] = fallDetected;          // 0 or 1
  doc["ax"] = accelX;                 // Accelerometer X
  doc["ay"] = accelY;                 // Accelerometer Y
  doc["az"] = accelZ;                 // Accelerometer Z
  
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  
  pCharacteristic->setValue(jsonBuffer);
  pCharacteristic->notify();
}
```

### Example JSON Packet

```json
{
  "hr": 72,
  "spo2": 98,
  "bps": 118,
  "bpd": 76,
  "hrv": 45.2,
  "steps": 6234,
  "cal": 312.5,
  "temp": 36.7,
  "irreg": 0,
  "fall": 0,
  "ax": 0.01,
  "ay": 0.02,
  "az": 0.98
}
```

---

## 6. Firmware Architecture

### Main Loop Structure

```cpp
unsigned long lastSensorRead = 0;
unsigned long lastBLESend = 0;
const int SENSOR_INTERVAL = 100;      // 100ms
const int BLE_INTERVAL = 1000;         // 1000ms (1Hz)

void loop() {
  unsigned long currentMillis = millis();
  
  // Read sensors every 100ms
  if (currentMillis - lastSensorRead >= SENSOR_INTERVAL) {
    lastSensorRead = currentMillis;
    readSensors();
    updateDisplay();
  }
  
  // Send BLE data every 1 second
  if (currentMillis - lastBLESend >= BLE_INTERVAL) {
    lastBLESend = currentMillis;
    sendHealthData();
  }
  
  // Check for button press
  checkButtons();
  
  // Power management
  handleSleepMode();
}
```

### Sensor Reading Functions

```cpp
struct HealthData {
  int heartRate;
  int spO2;
  int systolic;
  int diastolic;
  float hrv;
  int steps;
  float calories;
  float temperature;
  bool irregularBeat;
  bool fallDetected;
  float accelX, accelY, accelZ;
};

HealthData healthData;

void readSensors() {
  // Read heart rate
  healthData.heartRate = readHeartRate();
  healthData.spO2 = readSpO2();
  
  // Read blood pressure (estimated)
  estimateBloodPressure();
  
  // Read accelerometer
  readAccelerometer();
  calculateSteps();
  detectFall();
  
  // Calculate HRV
  calculateHRV();
}

int readHeartRate() {
  long irValue = particleSensor.getIR();
  
  if (checkForBeat(irValue) == true) {
    // Calculate instantaneous BPM
    long delta = millis() - lastBeat;
    lastBeat = millis();
    
    float bpm = 60 / (delta / 1000.0);
    
    // Low-pass filter to smooth BPM
    if (bpm > 30 && bpm < 210) {
      smoothedBpm = 0.7 * smoothedBpm + 0.3 * bpm;
      return (int)smoothedBpm;
    }
  }
  return 0;
}

void calculateSteps() {
  // Step detection using peak counting
  if (accelMagnitude > stepThreshold && 
      (millis() - lastStepTime) > stepDebounce) {
    stepCount++;
    lastStepTime = millis();
  }
  
  // Calculate calories
  healthData.calories = stepCount * 0.04; // Rough estimate
}
```

---

## 7. Power Management

### Sleep Mode Implementation

```cpp
bool isSleepMode = false;
unsigned long sleepTimeout = 30000; // 30 seconds
unsigned long lastActivity = 0;

void handleSleepMode() {
  if (isSleepMode) {
    // Deep sleep until interrupt
    esp_light_sleep_start();
    return;
  }
  
  // Check for sleep timeout
  if (millis() - lastActivity > sleepTimeout) {
    enterSleepMode();
  }
}

void enterSleepMode() {
  // Turn off LEDs
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, LOW);
  
  // Turn off display
  display.sleep();
  
  // Configure wake-up sources
  esp_sleep_enable_ext0_wakeup(GPIO_NUM_34, 0); // Button wake
  esp_sleep_enable_timer_wakeup(60 * 1000000);  // Wake every 60s for HR monitoring
  
  isSleepMode = true;
  esp_light_sleep_start();
  
  // After wake
  isSleepMode = false;
  display.wakeup();
  lastActivity = millis();
}
```

### Battery Monitoring

```cpp
#define BATTERY_PIN 35
#define BATTERY_DIVIDER 2.0

float readBatteryLevel() {
  int adcValue = analogRead(BATTERY_PIN);
  float voltage = adcValue * (3.3 / 4095.0) * BATTERY_DIVIDER;
  
  // LiPo voltage: 3.0V (0%) to 4.2V (100%)
  float percentage = (voltage - 3.0) / 1.2 * 100;
  
  if (percentage < 0) percentage = 0;
  if (percentage > 100) percentage = 100;
  
  return percentage;
}

void checkBattery() {
  float level = readBatteryLevel();
  
  if (level < 10) {
    // Low battery warning
    digitalWrite(LED_RED, HIGH);
    delay(100);
    digitalWrite(LED_RED, LOW);
  }
}
```

---

## 8. Emergency System

### Emergency Button Handling

```cpp
#define EMERGENCY_BUTTON 34

void initEmergencyButton() {
  pinMode(EMERGENCY_BUTTON, INPUT_PULLUP);
  attachInterrupt(EMERGENCY_BUTTON, emergencyISR, FALLING);
}

unsigned long emergencyPressStart = 0;
bool emergencyTriggered = false;

void emergencyISR() {
  if (digitalRead(EMERGENCY_BUTTON) == LOW) {
    emergencyPressStart = millis();
  } else {
    // Button released
    if (emergencyPressStart > 0 && 
        (millis() - emergencyPressStart) > 3000) {
      // Held for 3+ seconds
      triggerEmergency();
    }
    emergencyPressStart = 0;
  }
}

void triggerEmergency() {
  if (emergencyTriggered) return;
  emergencyTriggered = true;
  
  // Vibrate in SOS pattern
  sosPattern();
  
  // Send critical BLE packet
  healthData.fallDetected = 1;
  healthData.irregularBeat = 1;
  
  // Flash red LED
  flashEmergencyLED();
}

void sosPattern() {
  // ... (SOS morse code vibration)
}
```

---

## 9. Display System

### OLED SSD1306 Display

```cpp
#include <SSD1306.h>

SSD1306 display(0x3C, I2C_SDA, I2C_SCL);

void initOLED() {
  display.init();
  display.flipScreenVertically();
  display.setFont(ArialMT_Plain_10);
}

void updateDisplay() {
  display.clear();
  
  // Header: Battery + Time
  display.setTextAlignment(TEXT_ALIGN_LEFT);
  display.drawString(0, 0, "Digital Saver");
  
  display.setTextAlignment(TEXT_ALIGN_RIGHT);
  display.drawString(128, 0, String(batteryLevel) + "%");
  
  // Heart rate display
  display.setTextAlignment(TEXT_ALIGN_CENTER);
  display.drawString(64, 20, String(healthData.heartRate));
  display.setFont(ArialMT_Plain_24);
  display.drawString(64, 35, "BPM");
  
  // SpO2
  display.setFont(ArialMT_Plain_10);
  display.drawString(10, 50, "SpO2: " + String(healthData.spO2) + "%");
  
  // Steps
  display.drawString(70, 50, "Steps: " + String(healthData.steps));
  
  display.display();
}
```

---

## 10. Build & Flash Instructions

### Development Environment

1. **Install PlatformIO** or **Arduino IDE with ESP32 board support**

2. **Required Libraries:**
   - Adafruit MAX30105 Library
   - Adafruit MPU6050 Library
   - Adafruit GFX Library
   - Adafruit SSD1306 Library
   - ESP32 BLE Arduino

### PlatformIO Configuration

```ini
; platformio.ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino

lib_deps = 
    adafruit/Adafruit MAX30105 Library@^1.0.5
    adafruit/Adafruit MPU6050@^2.2.4
    adafruit/Adafruit SSD1306@^1.7.2
    adafruit/Adafruit GFX Library@^1.11.9
    h2zero/NimBLE-Arduino@^1.4.1
```

### Upload Process

```bash
# Connect ESP32 in bootloader mode
# Hold BOOT button while clicking RESET

# Using PlatformIO
pio run --target upload

# Using Arduino IDE
# Select Tools > Upload
```

### Serial Monitor

```bash
# Connect at 115200 baud
pio device monitor --baud 115200
```

---

## 11. Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| I2C devices not found | Wrong wiring or address | Check SDA/SCL connections |
| No heart rate reading | Finger not on sensor | Press finger firmly on sensor |
| ESP32 won't upload | Boot mode issue | Hold BOOT + press RESET |
| Watch freezes | Power instability | Add 100nF cap across 3V3/GND |
| BLE not advertising | Incorrect service UUID | Verify UUID matches app config |
| Battery drains fast | Sleep mode disabled | Enable deep sleep when idle |

### Diagnostic Code

```cpp
void diagnosticMode() {
  Serial.println("=== Diagnostic Mode ===");
  
  // Check I2C
  scanI2CDevices();
  
  // Check battery
  Serial.print("Battery: ");
  Serial.print(readBatteryLevel());
  Serial.println("%");
  
  // Check memory
  Serial.print("Free Heap: ");
  Serial.println(ESP.getFreeHeap());
  
  // Test LEDs
  digitalWrite(LED_RED, HIGH);
  delay(500);
  digitalWrite(LED_RED, LOW);
  
  // Test vibration
  digitalWrite(VIBRATION_PIN, HIGH);
  delay(500);
  digitalWrite(VIBRATION_PIN, LOW);
}
```

---

**Document Version:** 1.0.0  
**Last Updated:** July 2026  
**Author:** Cambric Engineering Team  
**Copyright © 2026 Cambric. All Rights Reserved.**
