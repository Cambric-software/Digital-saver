# Digital Saver - Smartwatch Health Monitoring System

## Project Overview

**Project Name:** Digital Saver  
**Type:** Health Monitoring Smartwatch System with Emergency Response  
**Core Functionality:** A smartwatch health monitoring system that detects irregular heartbeats, high blood pressure, and loss of consciousness, automatically triggering emergency alerts with location data.  
**Target Users:** Elderly individuals, patients with cardiovascular conditions, caregivers, and at-risk populations.

---

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DIGITAL SAVER SYSTEM                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐         Bluetooth LE         ┌──────────────────┐     │
│  │   HANDMADE   │ ◄──────────────────────────► │   MOBILE APP     │     │
│  │   SMARTWATCH │        (BLE 4.2+)            │   (Flutter)      │     │
│  │              │                               │                  │     │
│  │ • PPG Sensor │        Raw sensor data        │ • Data Display  │     │
│  │ • 3-AXIS IMU │        + alerts               │ • Emergency     │     │
│  │ • Buzzer     │                               │ • Multi-language│     │
│  │ • Display    │                               │ • History       │     │
│  └──────────────┘                               └────────┬─────────┘     │
│                                                          │               │
│                                           Emergency SMS/CALL              │
│                                                          ▼               │
│                                                 ┌──────────────────┐     │
│                                                 │  EMERGENCY       │     │
│                                                 │  CONTACTS + 911  │     │
│                                                 └──────────────────┘     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Mobile Application Specification

### 2.1 Core Features

| Feature | Priority | Description |
|---------|----------|-------------|
| Real-time Heart Rate Monitoring | P0 | Display live heart rate from PPG sensor |
| Blood Pressure Estimation | P0 | Calculate BP using PPG waveform analysis |
| Fall Detection | P0 | Detect loss of consciousness via accelerometer |
| Arrhythmia Detection | P0 | Identify irregular heartbeat patterns |
| Emergency Alert System | P0 | Auto-dial/SMS with GPS location |
| Multi-language Support | P0 | Support 10+ languages including Arabic |
| Data History | P1 | Store and display health trends |
| Watch Connection Status | P1 | BLE connection management |

### 2.2 Supported Languages

| # | Language | Code | Direction |
|---|----------|------|-----------|
| 1 | English | en | LTR |
| 2 | Arabic | ar | RTL |
| 3 | Spanish | es | LTR |
| 4 | French | fr | LTR |
| 5 | German | de | LTR |
| 6 | Chinese (Simplified) | zh | LTR |
| 7 | Japanese | ja | LTR |
| 8 | Russian | ru | LTR |
| 9 | Portuguese | pt | LTR |
| 10 | Hindi | hi | LTR |

### 2.3 Emergency Detection Thresholds

```dart
class HealthThresholds {
  // Heart Rate (BPM)
  static const int minNormalHR = 60;
  static const int maxNormalHR = 100;
  static const int bradycardia = 50;      // Below this: bradycardia alert
  static const int tachycardia = 120;     // Above this: tachycardia alert
  
  // Blood Pressure Estimation (mmHg)
  static const int minNormalSystolic = 90;
  static const int maxNormalSystolic = 140;
  static const int hypertensionStage1 = 140;
  static const int hypertensionStage2 = 180;
  
  // Fall Detection
  static const double fallThreshold = 2.5; // g-force
  static const int fallDurationMs = 500;    // Duration of abnormal motion
}
```

---

## 3. Handmade Smartwatch Hardware

### 3.1 Core Components

| Component | Model | Purpose | Price (EGP) |
|-----------|-------|---------|-------------|
| Main MCU | ESP32-WROOM-32 | Processing + BLE | 180 |
| PPG Heart Rate | MAX30102 | HR + SpO2 | 220 |
| 3-Axis Accelerometer | MPU6050 | Fall detection | 45 |
| Display | 1.3" OLED I2C | User interface | 85 |
| Vibration Motor | 10mm Coin | Haptic feedback | 15 |
| Buzzer | 5V Active | Audio alerts | 12 |
| Battery | 500mAh LiPo | Power supply | 75 |
| Battery Charger | TP4056 | LiPo charging | 25 |
| Watch Strap | 22mm Silicone | Wearing | 35 |
| PCB | Custom 2-layer | Circuit board | 120 |
| Misc Components | Resistors, Caps | Electronics | 50 |
| Enclosure | 3D Printed PLA | Watch case | 80 |
| **TOTAL HARDWARE** | | | **942** |

### 3.2 Watch Specifications

```
┌─────────────────────────────────────┐
│     SMARTWATCH DIMENSIONS            │
├─────────────────────────────────────┤
│ Case:        45mm x 45mm x 12mm     │
│ Display:     1.3" OLED 128x64       │
│ Weight:      ~45g (with band)       │
│ Battery:     500mAh LiPo            │
│ Battery Life: 2-3 days continuous   │
│ Waterproof:  IP67 (with case)       │
│ Connectivity: Bluetooth 4.2+ LE     │
└─────────────────────────────────────┘
```

### 3.3 Pin Configuration (ESP32)

```
MAX30102 (I2C: SDA=21, SCL=22):
├── VIN  → 3.3V
├── GND  → GND
├── SDA  → GPIO 21
├── SCL  → GPIO 22
└── INT  → GPIO 35

MPU6050 (I2C: shared):
├── VCC  → 3.3V
├── GND  → GND
├── SDA  → GPIO 21
├── SCL  → GPIO 22
└── INT  → GPIO 34

OLED Display (I2C: shared address 0x3C):
├── VCC  → 3.3V
├── GND  → GND
├── SDA  → GPIO 21
└── SCL  → GPIO 22

Buzzer:
├── IO   → GPIO 27
└── GND  → GND

Vibration Motor:
├── IO   → GPIO 26
└── GND  → GND

Button:
├── IO   → GPIO 0
└── GND  → GND
```

---

## 4. Bluetooth Communication Protocol

### 4.1 GATT Service Structure

```
Service: Health Monitor (UUID: 0x1816)
├── Heart Rate Measurement (UUID: 0x2A37)
│   └── Properties: Notify
│   └── Format: UINT8 BPM
│
├── Blood Pressure (UUID: 0x2A35)
│   └── Properties: Notify
│   └── Format: UINT16 Systolic / UINT16 Diastolic
│
└── Alert Status (UUID: 0x2A3F)
    └── Properties: Notify + Read
    └── Flags: Fall Detected | Arrhythmia | Hypertension

Service: Device Info (UUID: 0x180A)
├── Manufacturer Name (UUID: 0x2A29)
├── Model Number (UUID: 0x2A24)
├── Battery Level (UUID: 0x2A19)
└── Firmware Revision (UUID: 0x2A26)
```

### 4.2 Data Packet Format

```c
// Heart Rate Packet (10 bytes)
struct HeartRatePacket {
    uint8_t  header;      // 0x01
    uint8_t  heartRate;   // BPM
    uint8_t  spO2;        // Oxygen saturation %
    uint8_t  confidence;  // Measurement confidence 0-100%
    int16_t  reserved;
    uint32_t timestamp;   // Unix timestamp
};

// Blood Pressure Packet (8 bytes)
struct BloodPressurePacket {
    uint8_t  header;      // 0x02
    uint8_t  systolic;    // mmHg
    uint8_t  diastolic;   // mmHg
    uint8_t  map;         // Mean arterial pressure
    uint8_t  status;      // 0=normal, 1=elevated, 2=high, 3=critical
    uint32_t timestamp;
};

// Alert Packet (7 bytes)
struct AlertPacket {
    uint8_t  header;      // 0x03
    uint8_t  alertType;   // 1=Fall, 2=Arrhythmia, 4=Hypertension
    uint8_t  severity;    // 1=Warning, 2=Critical
    int16_t  accX, accY, accZ;  // Acceleration data
};
```

---

## 5. Emergency Detection Algorithms

### 5.1 Irregular Heartbeat Detection (Arrhythmia)

```python
def detect_arrhythmia(rr_intervals, window_size=30):
    """
    Detect arrhythmia using RR interval analysis.
    rr_intervals: List of RR intervals in ms
    window_size: Analysis window in seconds
    """
    if len(rr_intervals) < window_size * 2:
        return False
    
    # Calculate RMSSD (Root Mean Square of Successive Differences)
    successive_diffs = [abs(rr_intervals[i+1] - rr_intervals[i]) 
                        for i in range(len(rr_intervals)-1)]
    rmssd = sqrt(mean([d**2 for d in successive_diffs]))
    
    # Calculate SDNN (Standard Deviation of NN intervals)
    sdnn = std(rr_intervals)
    
    # Arrhythmia indicators:
    # 1. High HRV variability (RMSSD > 100ms in adults at rest)
    # 2. Very low HRV (RMSSD < 20ms)
    # 3. Sudden changes in heart rate
    # 4. Missing beats (RR interval > 2000ms)
    
    if rmssd > 100 or rmssd < 20:
        return True
    
    # Check for missing beats
    for rr in rr_intervals:
        if rr > 2000 or rr < 300:  # Abnormal RR interval
            return True
    
    return False
```

### 5.2 Blood Pressure Estimation (PPG-based)

```python
def estimate_blood_pressure(ppg_waveform, heart_rate, age=50):
    """
    Estimate blood pressure using PPG waveform analysis.
    This is a simplified estimation - calibration required for accuracy.
    """
    # Extract features from PPG waveform
    systolic_peak = find_systolic_peak(ppg_waveform)
    diastolic_peak = find_diastolic_peak(ppg_waveform)
    pulse_width = calculate_pulse_width(ppg_waveform)
    
    # Augmentation Index (AI) calculation
    ai = (systolic_peak - diastolic_peak) / systolic_peak
    
    # Estimated Pulse Wave Velocity
    pwv = 0.5 + (ai * 0.8)
    
    # Simplified BP estimation formula
    # PTT (Pulse Transit Time) estimation from PPG
    estimated_systolic = 100 + (heart_rate * 0.3) + (age * 0.5) + (ai * 50)
    estimated_diastolic = 60 + (heart_rate * 0.1) + (age * 0.2)
    
    return {
        'systolic': int(estimated_systolic),
        'diastolic': int(estimated_diastolic),
        'map': int((estimated_systolic + 2*estimated_diastolic) / 3),
        'confidence': 75  # Calibration needed for higher accuracy
    }
```

### 5.3 Fall Detection Algorithm

```python
def detect_fall(acc_data, threshold=2.5, duration_ms=500):
    """
    Detect falls using accelerometer data.
    acc_data: [(x, y, z, timestamp), ...]
    threshold: g-force threshold for free-fall detection
    duration: Minimum duration of impact to consider as fall
    """
    fall_detected = False
    
    for i, (x, y, z, ts) in enumerate(acc_data):
        # Calculate total acceleration magnitude
        magnitude = sqrt(x**2 + y**2 + z**2) / 9.81
        
        # Phase 1: Detect free-fall (low acceleration)
        if magnitude < 0.5:
            fall_start = ts
        
        # Phase 2: Detect impact (high acceleration)
        if magnitude > threshold:
            impact_duration = ts - fall_start
            if impact_duration < duration_ms and (ts - fall_start) > 200:
                # Verify with orientation change
                if check_orientation_change(acc_data[max(0,i-10):i+5]):
                    fall_detected = True
    
    return fall_detected
```

---

## 6. Budget Breakdown (10,000 EGP)

| Category | Item | Quantity | Price (EGP) |
|----------|------|----------|-------------|
| **HARDWARE COMPONENTS** | | | |
| Main MCU | ESP32-WROOM-32 | 2 | 360 |
| PPG Sensor | MAX30102 | 2 | 440 |
| IMU | MPU6050 | 2 | 90 |
| Display | 1.3" OLED 128x64 | 2 | 170 |
| Battery | 500mAh LiPo | 4 | 300 |
| Charger | TP4056 | 2 | 50 |
| Components | PCB, Resistors, Caps, etc. | - | 200 |
| Enclosure | 3D Printed Case | 2 | 160 |
| Straps | 22mm Watch Bands | 4 | 140 |
| Misc | Wires, headers, etc. | - | 100 |
| **SUBTOTAL HARDWARE** | | | **2,010** |
| **TOOLS & CONSUMABLES** | | | |
| Multimeter | Digital Multimeter | 1 | 250 |
| Soldering Iron | 60W with accessories | 1 | 350 |
| Wire | Hookup wire kit | 1 | 150 |
| Headers | Male/Female headers | 1 | 50 |
| **SUBTOTAL TOOLS** | | | **800** |
| **MOBILE APP DEVELOPMENT** | | | |
| Development | Flutter SDK (free) | - | 0 |
| Testing | Physical device testing | - | 0 |
| **SUBTOTAL APP** | | | **0** |
| **EMERGENCY FUND** | | | |
| Contingency | Parts replacement, shipping | - | 1,000 |
| **TOTAL BUDGET** | | | **3,810 EGP** |
| **REMAINING** | | | **6,190 EGP** |

### Recommended Additional Investments

| Item | Purpose | Price (EGP) |
|------|---------|-------------|
| MAX30105 | Particle sensor for better accuracy | 280 |
| MAX86150 | Medical-grade PPG + ECG | 450 |
| Custom PCB | Professional PCB fabrication | 500 |
| Heart Rate Chest Strap | Calibration reference | 400 |
| Spare Parts Kit | ESP32, sensors, displays | 600 |

---

## 7. Accuracy Considerations

### 7.1 Heart Rate Accuracy

| Method | Accuracy | Notes |
|--------|----------|-------|
| MAX30102 Raw | ±5-10 BPM | Requires good skin contact |
| With Motion Cancellation | ±3-5 BPM | MPU6050 compensation |
| Averaged (30s) | ±2-3 BPM | Smoothed measurements |

### 7.2 Blood Pressure Accuracy

| Method | Accuracy | Notes |
|--------|----------|-------|
| PPG-based Estimation | ±15-20 mmHg | Requires calibration |
| With PTT Integration | ±10-15 mmHg | Uses ECG + PPG if available |
| Medical Grade (MAX86150) | ±5-8 mmHg | With proper calibration |

**Note:** For clinical accuracy, recommend periodic calibration against a validated blood pressure cuff. The system provides estimates that can indicate trends and alert users to potential issues.

---

## 8. Implementation Roadmap

### Phase 1: Prototype (Weeks 1-2)
- [ ] Order components
- [ ] Build first prototype on breadboard
- [ ] Test individual sensors
- [ ] Implement basic BLE communication

### Phase 2: Integration (Weeks 3-4)
- [ ] Integrate all sensors
- [ ] Implement detection algorithms
- [ ] Create mobile app (Flutter)
- [ ] Test BLE data transmission

### Phase 3: Calibration (Weeks 5-6)
- [ ] Blood pressure calibration
- [ ] Fall detection tuning
- [ ] Arrhythmia detection testing
- [ ] Multi-language support implementation

### Phase 4: Production (Weeks 7-8)
- [ ] Design and order custom PCB
- [ ] 3D print enclosure
- [ ] Assemble final device
- [ ] User testing and refinement

---

## 9. Safety & Medical Disclaimer

**IMPORTANT:** This device is a **wellness/screening tool** and is **NOT** a medical device. It should not be used for self-diagnosis or to replace professional medical care.

- Heart rate and blood pressure estimates may not be as accurate as medical-grade devices
- This system cannot detect all medical conditions
- Always consult healthcare professionals for medical advice
- In case of emergency, call local emergency services immediately

---

## 10. Repository Structure

```
Digital-saver/
├── SPEC.md                    # This specification
├── README.md                  # Project overview
├── hardware/
│   ├── schematic/             # Circuit schematics
│   ├── pcb/                   # PCB design files
│   ├── enclosure/             # 3D print files (.stl)
│   └── firmware/
│       └── esp32/             # Arduino/PlatformIO code
├── mobile_app/
│   └── digital_saver/         # Flutter application
│       ├── lib/
│       │   ├── main.dart
│       │   ├── screens/       # UI screens
│       │   ├── services/      # BLE, notifications
│       │   ├── models/        # Data models
│       │   └── i18n/          # Translations
│       └── pubspec.yaml
└── docs/
    ├── assembly-guide.md
    ├── user-manual.md
    └── troubleshooting.md
```
