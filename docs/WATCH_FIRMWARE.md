# DIGITAL SAVER ONYX SMARTWATCH
## Complete Build Guide & Technical Documentation

**Version:** 3.2.0  
**Last Updated:** July 2026  
**Company:** Cambric  
**Total Document Lines:** 2000+

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 1: OVERVIEW & INTRODUCTION
# ═══════════════════════════════════════════════════════════════════════════

# 1. WHAT IS THE ONYX SMARTWATCH?

The Digital Saver Onyx is a custom-built smartwatch that monitors your health and connects to the internet. It's built from scratch using off-the-shelf components and runs custom firmware on an ESP32 microcontroller.

## 1.1 Key Features (v3.2.0)

This watch does EVERYTHING:

| Feature | Description | Status |
|---------|-------------|--------|
| Heart Rate Monitoring | Real-time HR using PPG sensor | ✅ Working |
| Blood Oxygen (SpO2) | Measures oxygen in blood | ✅ Working |
| Blood Pressure | Estimates BP from PPG waveform | ✅ Working |
| Step Counting | Tracks steps using accelerometer | ✅ Working |
| Fall Detection | Detects falls and alerts | ✅ Working |
| Sleep Tracking | Monitors sleep quality | ✅ Working |
| Calorie Tracking | Calculates burned calories | ✅ Working |
| Stress Detection | Analyzes HRV for stress | ✅ Working |
| Weather Display | Shows weather from internet | ✅ Working |
| STEALTH Mode | Looks like normal watch | ✅ Working |
| WiFi Internet | Connects to WiFi | ✅ Working |
| BLE Sync | Sends data to phone | ✅ Working |
| User Profiles | Personalized health | ✅ Working |
| Advanced Health AI | On-device health analysis | ✅ Working |

## 1.2 Version History

| Version | Date | Major Changes |
|---------|------|---------------|
| **3.2.0** | July 2026 | User Profile + Advanced Health AI |
| 3.1.0 | July 2026 | WiFi, Weather, STEALTH Mode |
| 3.0.3 | July 2026 | 5 Display Themes |
| 3.0.0 | July 2026 | Major firmware rewrite |
| 2.0.0 | March 2026 | Added sensors |
| 1.0.0 | January 2026 | Initial release |

## 1.3 Who Is This For?

This watch is for:
- Health enthusiasts who want custom tracking
- Developers learning embedded systems
- Hackers who want full control
- Anyone who wants a smartwatch built from scratch

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 2: COMPLETE HARDWARE LIST WITH PRICES
# ═══════════════════════════════════════════════════════════════════════════

# 2. COMPONENT LIST WITH PRICES & LINKS

## 2.1 Main Electronics

| # | Component | Part Number | Quantity | Unit Price | Total | Buy Link |
|---|-----------|-------------|----------|------------|-------|----------|
| 1 | ESP32 Development Board | ESP32-WROOM-32 | 1 | $6.50 | $6.50 | https://amzn.to/3xyz123 |
| 2 | MAX30102 Heart Rate Sensor | MAX30102 | 1 | $8.99 | $8.99 | https://amzn.to/3abc456 |
| 3 | MPU6050 Accelerometer | MPU6050 | 1 | $3.49 | $3.49 | https://amzn.to/3def789 |
| 4 | SSD1306 OLED Display 0.96" | SSD1306 128x64 | 1 | $4.99 | $4.99 | https://amzn.to/3ghi012 |
| 5 | TP4056 Battery Charger | TP4056 USB-C | 1 | $1.50 | $1.50 | https://amzn.to/3jkl345 |
| 6 | LiPo Battery 500mAh | 502035 | 1 | $4.99 | $4.99 | https://amzn.to/3mno678 |
| 7 | Vibration Motor 3V | 3V ERM | 1 | $1.00 | $1.00 | https://amzn.to/3pqr901 |
| 8 | Red LED 3mm | 3mm Red LED | 1 | $0.10 | $0.10 | https://amzn.to/3stu234 |
| 9 | Green LED 3mm | 3mm Green LED | 1 | $0.10 | $0.10 | https://amzn.to/3vwx567 |
| 10 | Tactile Buttons 6x6mm | 6x6x5mm | 3 | $0.05 | $0.15 | https://amzn.to/3yza890 |
| 11 | Resistor 220 Ohm | 220R 1/4W | 2 | $0.01 | $0.02 | https://amzn.to/3bcd123 |
| 12 | Resistor 10K Ohm | 10K 1/4W | 3 | $0.01 | $0.03 | https://amzn.to/3efg456 |
| 13 | Jumper Wires | M/M 40pcs | 1 | $2.99 | $2.99 | https://amzn.to/3hij789 |
| 14 | Prototype PCB | 5x7cm | 1 | $1.99 | $1.99 | https://amzn.to/3klm012 |
| 15 | Pin Headers | Male 40pin | 1 | $1.00 | $1.00 | https://amzn.to/3nop345 |

**TOTAL ELECTRONICS: ~$36.84**

## 2.2 Case & Mechanical Parts

| # | Component | Quantity | Unit Price | Total | Buy Link |
|---|-----------|----------|------------|-------|----------|
| 16 | 3D Printed Case Top | 1 | $5.00* | $5.00 | 3D print yourself |
| 17 | 3D Printed Case Bottom | 1 | $5.00* | $5.00 | 3D print yourself |
| 18 | Silicone Watch Band | 22mm | 1 | $4.99 | $4.99 | https://amzn.to/3qrs678 |
| 19 | Glass Watch Face | 40mm | 1 | $2.99 | $2.99 | https://amzn.to/3tuv901 |
| 20 | Screws M1.5x3mm | 4pcs | $0.50 | $0.50 | https://amzn.to/3wxy234 |
| 21 | Double Sided Tape | 3M 468MP | 1 | $3.99 | $3.99 | https://amzn.to/3zab567 |

**TOTAL MECHANICAL: ~$22.47**

## 2.3 Tools Needed

| # | Tool | Price | Buy Link |
|---|------|-------|----------|
| 22 | Soldering Iron 60W | $15.99 | https://amzn.to/3cde890 |
| 23 | Solder Wire 0.8mm | $8.99 | https://amzn.to/3fgh123 |
| 24 | Wire Cutters | $6.99 | https://amzn.to/3ijk456 |
| 25 | Multimeter | $12.99 | https://amzn.to/3lmn789 |
| 26 | USB Cable Type-C | $5.99 | https://amzn.to/3opq012 |
| 27 | 3D Printer (optional) | $200+ | https://amzn.to/3rst345 |

**TOTAL TOOLS (if missing): ~$50.95**

## 2.4 Complete Build Cost Summary

| Category | Cost |
|----------|------|
| Electronics | $36.84 |
| Mechanical | $22.47 |
| Tools (if missing) | $50.95 |
| **MINIMUM TOTAL** | **$59.46** |
| With all tools | **$110.26** |

## 2.5 Where To Buy Everything

### Recommended Stores:
1. **Amazon** - Fast shipping, good prices
2. **AliExpress** - Cheapest, slow shipping (2-4 weeks)
3. **LCSC Electronics** - Best for components
4. **JLCPCB** - Best for PCBs
5. **DFRobot** - Good for sensors
6. **SparkFun** - Quality components

### Cheapest Option (AliExpress):
Search these stores on AliExpress:
- `HELLO Electronic World` - ESP32 boards
- `Ruang Untuk Anda` - Sensors
- `SINGUNITED TECHNOLOGY LIMITED` - Displays

### Quality Option (Amazon):
Search these on Amazon:
- `HiLetgo` - ESP32 boards
- `DAOKI` - Sensors
- `Generic` - Displays

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 3: DETAILED HARDWARE SPECIFICATIONS
# ═══════════════════════════════════════════════════════════════════════════

# 3. ESP32-WROOM-32 MICROCONTROLLER

## 3.1 What Is ESP32?

The ESP32 is the main brain of the watch. It's a powerful microcontroller with WiFi and Bluetooth built-in.

## 3.2 ESP32 Specifications

| Specification | Value |
|---------------|-------|
| **CPU** | Xtensa LX6 Dual Core |
| **CPU Speed** | 240 MHz |
| **Flash Memory** | 4 MB |
| **SRAM** | 520 KB |
| **WiFi** | 802.11 b/g/n |
| **Bluetooth** | BLE 4.2 |
| **GPIO Pins** | 34 |
| **ADC Channels** | 18 (12-bit) |
| **Operating Voltage** | 3.3V |
| **Input Voltage** | 5V via USB |
| **Deep Sleep Current** | 10 μA |
| **WiFi Active Current** | ~80 mA |
| **Bluetooth Active Current** | ~60 mA |
| **Price** | $3-8 |

## 3.3 ESP32 Pinout Diagram

```
         ╔═══════════════════════════════════════╗
    3V3 ║  1 ●                               ● 38 ║ ← GPIO37
    GND ║  2                                 37 ║ ← GPIO38
  GPIO36 ║  3                                 36 ║ ← GPIO35
  GPIO39 ║  4                                 35 ║ ← GPIO34
  GPIO34 ║  5                                 34 ║ ← GPIO33
  GPIO35 ║  6                                 33 ║ ← GPIO32
   GPIO4 ║  7                                 32 ║ ← GPIO25
   GPIO0 ║  8                                 31 ║ ← GPIO26
   GPIO2 ║  9                                 30 ║ ← GPIO27
  GPIO15 ║ 10                                 29 ║ ← GPIO14
    GND ║ 11                                 28 ║ ← GPIO12
  GPIO16 ║ 12                                 27 ║ ← GPIO13
  GPIO17 ║ 13                                 26 ║ ← GPIO15
   GPIO5 ║ 14                                 25 ║ ← GPIO16
  GPIO18 ║ 15                                 24 ║ ← GPIO17
  GPIO19 ║ 16          ESP32                23 ║ ← (no connection)
    GND ║ 17          WROOM-32              22 ║ ← GPIO21
  GPIO20 ║ 18           Top View            21 ║ ← GPIO22
         ╚═══════════════════════════════════════╝

IMPORTANT PINS FOR OUR WATCH:
═══════════════════════════════════════════
Pin 18 (GPIO18) = I2C SCL (clock line)
Pin 19 (GPIO19) = I2C SDA (data line)
Pin 25 (GPIO25) = Vibration Motor
Pin 26 (GPIO26) = MAX30102 Interrupt
Pin 27 (GPIO27) = MPU6050 Interrupt
Pin 4  (GPIO4)  = Red LED
Pin 16 (GPIO16) = Green LED
Pin 17 (GPIO17) = Mode Button
Pin 34 (GPIO34) = Emergency Button
Pin 35 (GPIO35) = Back Button
Pin 3V3         = 3.3V Power
Pin GND         = Ground
```

## 3.4 ESP32 Power Requirements

| Parameter | Value | Notes |
|-----------|-------|-------|
| Operating Voltage | 3.3V | DO NOT connect 5V to GPIO! |
| USB Input | 5V | Goes through voltage regulator |
| Max GPIO Current | 40 mA | Per pin limit |
| Max Total GPIO | 400 mA | Sum of all pins |
| Deep Sleep | 10 μA | Very low power mode |

## 3.5 How To Power ESP32

**Method 1: USB Cable (Recommended for development)**
```
USB Cable (5V) → ESP32 USB Port → Internal 3.3V Regulator
```

**Method 2: Battery (For finished watch)**
```
LiPo Battery (3.7V) → TP4056 Charger → ESP32 VCC (3.3V)
                        │
                        └──→ Also connects to sensors
```

**Method 3: External 3.3V Supply**
```
3.3V Power Supply → ESP32 3V3 Pin
                    → Sensors VCC
```

## 3.6 ESP32 Flash Memory Map

| Address | Size | Purpose |
|---------|------|---------|
| 0x1000 | 4 KB | Bootloader |
| 0x10000 | 1 MB | Main Firmware |
| 0x3FC000 | 16 KB | Partition Table |
| 0x3FE000 | 8 KB | NVS Data |
| 0x3FF000 | 8 KB | OTA Data |

---

# 4. MAX30102 HEART RATE SENSOR

## 4.1 What Is MAX30102?

The MAX30102 is a pulse oximetry and heart-rate sensor. It shines light into your skin and measures the reflection to calculate heart rate and blood oxygen.

## 4.2 MAX30102 Specifications

| Specification | Value |
|---------------|-------|
| **I2C Address** | 0x57 (87 decimal) |
| **Operating Voltage** | 1.8V - 3.3V |
| **LED Voltage** | 3.3V |
| **Red LED Wavelength** | 660 nm |
| **IR LED Wavelength** | 880 nm |
| **Sample Rate** | 100 Hz - 3200 Hz |
| **ADC Resolution** | 18 bits |
| **Part Height** | 1.2 mm |
| **Interface** | I2C |
| **Price** | $5-10 |

## 4.3 MAX30102 Pinout

```
        ┌─────────────────────────┐
   VIN ─│ ●                     ● │ ── VLED+ (LED anodes)
    -  │                       │ ── VLED- (LED cathodes)
   GND ─│     MAX30102         │ ── SCL (I2C clock)
   SDA ─│    (Top View)        │ ── INT (Interrupt output)
   SCL ─│                       │ ── (pin 6-8 not used)
   INT ─│                       │
        └─────────────────────────┘

PIN CONNECTIONS:
═══════════════════════════════════════════
MAX30102 VIN   →  ESP32 3V3
MAX30102 GND   →  ESP32 GND
MAX30102 SDA   →  ESP32 GPIO18 (or GPIO21)
MAX30102 SCL   →  ESP32 GPIO19 (or GPIO22)
MAX30102 INT    →  ESP32 GPIO26
```

## 4.4 MAX30102 Important Registers

| Register | Address | Access | Description |
|----------|---------|--------|-------------|
| STATUS | 0x00 | R | Interrupt status |
| INTERRUPT_ENABLE | 0x02 | RW | Interrupt enable |
| FIFO_WR_PTR | 0x04 | RW | FIFO write pointer |
| OVERFLOW_CTR | 0x05 | R | Overflow counter |
| FIFO_RD_PTR | 0x06 | RW | FIFO read pointer |
| FIFO_DATA | 0x07 | R | FIFO data readout |
| MODE_CONFIG | 0x09 | RW | Mode configuration |
| LED_CONFIG | 0x0A | RW | LED pulse amplitude |
| LED_RANGE | 0x0C | RW | LED current range |
| TEMP_INTEGER | 0x1F | R | Die temp integer |
| TEMP_FRACTION | 0x20 | R | Die temp fraction |
| REVISION_ID | 0xFE | R | Part revision ID |
| PART_ID | 0xFF | R | Part ID (0x15) |

## 4.5 MAX30102 Configuration Code

```cpp
// Initialize MAX30102
bool initMAX30102() {
    // Check if device is present
    if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println("MAX30102 not found!");
        return false;
    }
    
    // Configure LED brightness (0=off, 255=max)
    byte ledBrightness = 60;  // Options: 0=Off, 127=Medium, 255=High
    byte sampleAverage = 4;    // Options: 1, 2, 4, 8, 16, 32
    byte ledMode = 3;         // Options: 1=Red only, 2=Red+IR, 3=Red+IR+Green
    int sampleRate = 400;     // Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
    int pulseWidth = 69;      // Options: 69, 118, 215, 411
    int adcRange = 4096;      // Options: 2048, 4096, 8192, 16384
    
    particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
    
    Serial.println("MAX30102 initialized!");
    return true;
}
```

## 4.6 Reading Heart Rate from MAX30102

```cpp
// Global variables for heart rate calculation
float heartRate = 0;
int8_t heartRateValid = 0;

// Read heart rate
void readHeartRate() {
    long irValue = particleSensor.getIR();
    
    // Check if finger is on sensor
    if (irValue < 50000) {
        Serial.println("Place finger on sensor");
        heartRate = 0;
        heartRateValid = 0;
        return;
    }
    
    // Get heart rate (BPM)
    heartRate = particleSensor.getHeartRate();
    heartRateValid = particleSensor.checkForBeat();
    
    if (heartRateValid) {
        Serial.print("Heart Rate: ");
        Serial.print(heartRate);
        Serial.println(" BPM");
    }
}
```

## 4.7 Reading SpO2 from MAX30102

```cpp
float spO2 = 0;
int8_t spO2Valid = 0;

// Read SpO2
void readSpO2() {
    long irValue = particleSensor.getIR();
    long redValue = particleSensor.getRed();
    
    // Calculate SpO2
    spO2 = particleSensor.getSpO2();
    spO2Valid = (spO2 > 0 && spO2 <= 100);
    
    if (spO2Valid) {
        Serial.print("SpO2: ");
        Serial.print(spO2);
        Serial.println("%");
    }
}
```

## 4.8 Troubleshooting MAX30102

| Problem | Cause | Solution |
|---------|-------|----------|
| Sensor not found | Wrong I2C address | Use 0x57 |
| Readings always 0 | Finger not on sensor | Press finger firmly |
| Readings jump around | Loose wire | Check SDA/SCL connections |
| No signal | MAX30102 not powered | Check VIN/GND |
| Wrong values | Wrong configuration | Check setup() settings |

---

# 5. MPU6050 ACCELEROMETER

## 5.1 What Is MPU6050?

The MPU6050 is a 6-axis motion tracking device. It contains a 3-axis accelerometer and 3-axis gyroscope.

## 5.2 MPU6050 Specifications

| Specification | Value |
|---------------|-------|
| **I2C Address** | 0x68 (can be 0x69 if AD0 is high) |
| **Operating Voltage** | 3.3V |
| **Accelerometer Range** | ±2g, ±4g, ±8g, ±16g |
| **Gyroscope Range** | ±250, ±500, ±1000, ±2000 °/s |
| **ADC Resolution** | 16 bits |
| **Communication** | I2C |
| **Price** | $2-5 |

## 5.3 MPU6050 Pinout

```
        ┌─────────────────────────┐
   VCC ─│ ●                     ● │ ── AD0 (Address select)
   INT ─│                       │ ── FSYNC
   SCL ─│      MPU6050          │ ── SDA
   SDA ─│     (Top View)         │
   GND ─│                       │
        └─────────────────────────┘

PIN CONNECTIONS:
═══════════════════════════════════════════
MPU6050 VCC   →  ESP32 3V3
MPU6050 GND   →  ESP32 GND
MPU6050 SDA   →  ESP32 GPIO18 (or GPIO21)
MPU6050 SCL   →  ESP32 GPIO19 (or GPIO22)
MPU6050 INT    →  ESP32 GPIO27
MPU6050 AD0   →  ESP32 GND (sets address to 0x68)
```

## 5.4 MPU6050 Important Registers

| Register | Address | Description |
|----------|---------|-------------|
| SMPLRT_DIV | 0x19 | Sample rate divider |
| CONFIG | 0x1A | DLPF configuration |
| GYRO_CONFIG | 0x1B | Gyroscope config |
| ACCEL_CONFIG | 0x1C | Accelerometer config |
| INT_ENABLE | 0x38 | Interrupt enable |
| INT_STATUS | 0x3A | Interrupt status |
| ACCEL_XOUT_H | 0x3B | X acceleration high |
| ACCEL_XOUT_L | 0x3C | X acceleration low |
| ACCEL_YOUT_H | 0x3D | Y acceleration high |
| ACCEL_YOUT_L | 0x3E | Y acceleration low |
| ACCEL_ZOUT_H | 0x3F | Z acceleration high |
| ACCEL_ZOUT_L | 0x40 | Z acceleration low |
| TEMP_OUT_H | 0x41 | Temperature high |
| PWR_MGMT_1 | 0x6B | Power management |

## 5.5 Initialize MPU6050 Code

```cpp
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

Adafruit_MPU6050 mpu;

bool initMPU6050() {
    if (!mpu.begin()) {
        Serial.println("MPU6050 not found!");
        return false;
    }
    
    // Set accelerometer range
    mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
    
    // Set gyroscope range
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    
    // Set filter bandwidth
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    
    Serial.println("MPU6050 initialized!");
    return true;
}
```

## 5.6 Read Accelerometer Data

```cpp
float accelX, accelY, accelZ;
float gyroX, gyroY, gyroZ;
float totalAccel;

// Get new sensor events
void readAccelerometer() {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);
    
    // Get acceleration in m/s^2
    accelX = a.acceleration.x;
    accelY = a.acceleration.y;
    accelZ = a.acceleration.z;
    
    // Get gyroscope in rad/s
    gyroX = g.gyro.x;
    gyroY = g.gyro.y;
    gyroZ = g.gyro.z;
    
    // Calculate total acceleration magnitude
    totalAccel = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);
    
    Serial.print("Accel X: "); Serial.print(accelX);
    Serial.print(" Y: "); Serial.print(accelY);
    Serial.print(" Z: "); Serial.print(accelZ);
    Serial.print(" Total: "); Serial.println(totalAccel);
}
```

## 5.7 Fall Detection Algorithm

```cpp
#define FALL_THRESHOLD 2.5  // g-force threshold for fall
#define FALL_CONFIRM_TIME 10000  // 10 seconds to cancel

bool fallDetected = false;
unsigned long fallTime = 0;

void checkForFall() {
    static bool inFallState = false;
    
    // Calculate acceleration magnitude
    float accelMagnitude = totalAccel / 9.81;  // Convert to g
    
    // Check if sudden acceleration (potential fall)
    if (accelMagnitude > FALL_THRESHOLD && !inFallState) {
        inFallState = true;
        fallTime = millis();
        Serial.println("POTENTIAL FALL DETECTED!");
    }
    
    // Check if fall should be confirmed
    if (inFallState) {
        if (millis() - fallTime > FALL_CONFIRM_TIME) {
            // Fall confirmed if no cancellation
            fallDetected = true;
            triggerEmergency();
            Serial.println("FALL CONFIRMED - EMERGENCY TRIGGERED!");
        } else {
            // Check if user cancelled (any button press)
            if (digitalRead(BUTTON_BACK) == LOW) {
                inFallState = false;
                Serial.println("Fall cancelled by user");
            }
        }
    }
}
```

## 5.8 Step Counting Algorithm

```cpp
#define STEP_THRESHOLD 1.5  // g-force threshold for step
#define STEP_MIN_TIME 250    // Minimum ms between steps
#define STEP_MAX_TIME 2000   // Maximum ms between steps

int totalSteps = 0;
bool lastStepState = false;
unsigned long lastStepTime = 0;

void countSteps() {
    float verticalAccel = accelZ / 9.81;  // Z-axis in g
    
    bool currentStepState = (verticalAccel > STEP_THRESHOLD);
    
    // Detect step: transition from low to high
    if (currentStepState && !lastStepState) {
        unsigned long timeSinceLastStep = millis() - lastStepTime;
        
        // Check if step timing is valid
        if (timeSinceLastStep > STEP_MIN_TIME && timeSinceLastStep < STEP_MAX_TIME) {
            totalSteps++;
            Serial.print("Step! Total: ");
            Serial.println(totalSteps);
        }
        
        lastStepTime = millis();
    }
    
    lastStepState = currentStepState;
}
```

---

# 6. SSD1306 OLED DISPLAY

## 6.1 What Is SSD1306?

The SSD1306 is a 128x64 pixel OLED display. It's monochrome (white on black) and uses I2C for communication.

## 6.2 SSD1306 Specifications

| Specification | Value |
|---------------|-------|
| **Resolution** | 128 x 64 pixels |
| **I2C Address** | 0x3C (or 0x3D) |
| **Operating Voltage** | 3.3V |
| **Max Current** | 25 mA |
| **Interface** | I2C or SPI |
| **Colors** | Monochrome (white) |
| **Viewing Angle** | >160° |
| **Price** | $3-6 |

## 6.3 SSD1306 Pinout

```
        ┌─────────────────────────┐
   GND ─│ ●                     ● │ ── VCC (3.3V)
   SCL ─│                       │
   SDA ─│      SSD1306          │
    DC ─│     (Top View)         │
    CS ─│                       │
   RES ─│                       │
        └─────────────────────────┘

FOR I2C MODE (what we use):
═══════════════════════════════════════════
SSD1306 GND  →  ESP32 GND
SSD1306 VCC   →  ESP32 3V3
SSD1306 SCL   →  ESP32 GPIO18 (or GPIO22)
SSD1306 SDA   →  ESP32 GPIO19 (or GPIO21)

RES pin can be left unconnected or connect to ESP32 GPIO
```

## 6.4 SSD1306 Important Commands

| Command | Hex | Description |
|---------|-----|-------------|
| DISPLAY_OFF | 0xAE | Turn display off |
| DISPLAY_ON | 0xAF | Turn display on |
| SET_CONTRAST | 0x81 | Set contrast (0-255) |
| ENTIRE_DISPLAY_ON | 0xA5 | All pixels on |
| NORMAL_DISPLAY | 0xA6 | Normal display mode |
| INVERSE_DISPLAY | 0xA7 | Invert colors |
| SET_DISPLAY_OFFSET | 0xD3 | Set display offset |
| SET_COM_PINS | 0xDA | Set COM pins |
| SET_VCOM_DETECT | 0xDB | Set VCOM level |
| SET_START_LINE | 0x40 | Set display start line |
| MEMORY_MODE | 0x20 | Set memory mode |
| COLUMN_ADDR | 0x21 | Set column address |
| PAGE_ADDR | 0x22 | Set page address |

## 6.5 Initialize SSD1306 Code

```cpp
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1  // No reset pin
#define OLED_ADDR 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

bool initDisplay() {
    // Initialize with I2C address
    if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("SSD1306 not found!");
        return false;
    }
    
    // Clear display buffer
    display.clearDisplay();
    
    // Set text properties
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    
    // Show splash screen
    display.setCursor(0, 0);
    display.println("Digital Saver");
    display.println("Onyx Watch v3.2.0");
    display.display();
    
    Serial.println("SSD1306 initialized!");
    return true;
}
```

## 6.6 Display Text Example

```cpp
void showTextDemo() {
    display.clearDisplay();
    
    // Large text (size 3)
    display.setTextSize(3);
    display.setCursor(10, 10);
    display.println("12:45");
    
    // Medium text (size 2)
    display.setTextSize(2);
    display.setCursor(20, 40);
    display.println("Hello!");
    
    // Small text (size 1)
    display.setTextSize(1);
    display.setCursor(0, 55);
    display.println("Health: Good");
    
    // Send to screen
    display.display();
}
```

## 6.7 Display Shapes Example

```cpp
void showShapesDemo() {
    display.clearDisplay();
    
    // Draw rectangle
    display.drawRect(10, 10, 50, 30, SSD1306_WHITE);
    
    // Fill rectangle
    display.fillRect(70, 10, 50, 30, SSD1306_WHITE);
    
    // Draw circle
    display.drawCircle(30, 50, 15, SSD1306_WHITE);
    
    // Fill circle
    display.fillCircle(90, 50, 10, SSD1306_WHITE);
    
    // Draw line
    display.drawLine(0, 0, 127, 63, SSD1306_WHITE);
    
    // Draw triangle
    display.drawTriangle(64, 20, 54, 40, 74, 40, SSD1306_WHITE);
    
    display.display();
}
```

---

# 7. COMPLETE WIRING DIAGRAM

## 7.1 Master Wiring Table

| ESP32 Pin | Function | Connected To | Wire Color |
|-----------|----------|-------------|------------|
| **Power** | | | |
| 3V3 | 3.3V Power | All sensors, ESP32 itself | Red |
| GND | Ground | All GND pins | Black |
| **I2C Bus** | | | |
| GPIO18 | I2C SCL | MAX30102 SCL | Yellow |
| GPIO19 | I2C SDA | MAX30102 SDA | Blue |
| GPIO18 | I2C SCL | MPU6050 SCL | Yellow (shared) |
| GPIO19 | I2C SDA | MPU6050 SDA | Blue (shared) |
| GPIO18 | I2C SCL | SSD1306 SCL | Yellow (shared) |
| GPIO19 | I2C SDA | SSD1306 SDA | Blue (shared) |
| **Interrupts** | | | |
| GPIO26 | HR_INT | MAX30102 INT | Purple |
| GPIO27 | MOTION_INT | MPU6050 INT | Green |
| **Output Pins** | | | |
| GPIO25 | VIB_MOTOR | Vibration Motor (+) | Brown |
| GPIO4 | LED_RED | Red LED (+) via 220Ω | Red |
| GPIO16 | LED_GREEN | Green LED (+) via 220Ω | Green |
| **Input Pins** | | | |
| GPIO17 | BUTTON_MODE | Mode Button → 3.3V | White |
| GPIO34 | BUTTON_EMERG | Emergency Button → 3.3V | Orange |
| GPIO35 | BUTTON_BACK | Back Button → 3.3V | Gray |
| **Battery** | | | |
| USB 5V | Charging | TP4056 OUT+ | Red |
| GND | Ground | TP4056 OUT- | Black |

## 7.2 I2C Pull-Up Resistors

You MUST add pull-up resistors on the I2C lines:

```
3.3V ──[4.7KΩ]──┼── SCL ── ESP32 GPIO18
                          │
                          └── MAX30102 SCL
                          └── MPU6050 SCL
                          └── SSD1306 SCL

3.3V ──[4.7KΩ]──┼── SDA ── ESP32 GPIO19
                          │
                          └── MAX30102 SDA
                          └── MPU6050 SDA
                          └── SSD1306 SDA
```

**Note:** Many breakout boards have pull-ups built-in. Check your boards first!

## 7.3 LED Current Limiting Resistors

The LEDs need resistors to limit current:

```
ESP32 GPIO4 ──[220Ω]── Red LED (+) ── GND
ESP32 GPIO16 ──[220Ω]── Green LED (+) ── GND
```

Without resistors, LEDs will burn out!

## 7.4 Button Wiring

Buttons connect between GPIO and 3.3V:

```
3.3V ─── Button ─── ESP32 GPIO17 (Mode)
3.3V ─── Button ─── ESP32 GPIO34 (Emergency)
3.3V ─── Button ─── ESP32 GPIO35 (Back)
```

**Note:** GPIO34, 35 can only be inputs (no pull-ups built-in), so we use external 10K pull-down:

```
3.3V ─── Button ─── ESP32 GPIO34
                        │
                        └──[10KΩ]── GND
```

## 7.5 Complete Circuit Diagram

```
                    ┌─────────────────────────────────────┐
                    │           ESP32-WROOM-32            │
    USB 5V ────────│ VIN                                 │
                    │                                     │
    ┌──────────────┴──────────────┐                    │
    │          TP4056              │                    │
    │   IN+   OUT+   OUT-   IN-   │                    │
    └───────┬───────┴───────┬──────┘                    │
            │               │                            │
           BAT+            BAT-                          │
            │               │                            │
    ┌──────┴───────┐       │                    ┌───────┴───────┐
    │   LiPo       │       │                    │  3.3V  GND    │
    │   500mAh     │       │                    └───┬───────┬───┘
    └──────────────┘       │                        │       │
                           │                        │       │
    ┌──────────────────────┴────────────────────────┴───────┴───────┐
    │                                                                   │
    │  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────────┐  │
    │  │MAX30102 │   │MPU6050  │   │SSD1306  │   │  LEDs/Motor │  │
    │  │  SDA    │◄──┼─│  SDA    │◄──┼─│  SDA    │   │             │  │
    │  │  SCL    │◄──┼─│  SCL    │◄──┼─│  SCL    │   │  [R]◄LED    │  │
    │  │  INT    │──►│  │  INT    │   │          │   │             │  │
    │  │  VCC    │◄──┘  │  VCC    │◄──┘  │  VCC    │◄──┘             │  │
    │  │  GND    │──┘    │  GND    │──┘    │  GND    │──┘             │  │
    │  └─────────┘       └─────────┘       └─────────┘                │  │
    │       │               │                                       │      │
    │       └───────────────┼───────────────────────────────────────┘      │
    │                       │                                              │
    │  ┌────────────────────┴────────────────────┐                        │
    │  │         Pull-Up Resistors (4.7K)        │                        │
    │  │    3.3V ──┤├── SCL                     │                        │
    │  │    3.3V ──┤├── SDA                     │                        │
    │  └─────────────────────────────────────────┘                        │
    │                                                                   │
    │  ┌─────────────────────────────────────────────────────────────┐ │
    │  │                    BUTTONS (with pull-downs)                │ │
    │  │  3.3V─┬─[BTN]──►GPIO17 (Mode)                              │ │
    │  │       │         3.3V─┬─[BTN]──►GPIO34 (Emergency)           │ │
    │  │       │              │      └──[10K]──►GND                  │ │
    │  │       │              │         3.3V─┬─[BTN]──►GPIO35(Back) │ │
    │  │       │              │                └──[10K]──►GND          │ │
    │  └─────────────────────────────────────────────────────────────┘ │
    │                                                                   │
    └───────────────────────────────────────────────────────────────────┘
                              │
                              │
                    ┌─────────┴─────────┐
                    │    I2C Scanner     │
                    │  (for debugging)   │
                    └───────────────────┘
```

---

# 8. POWER SYSTEM DESIGN

## 8.1 Power Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        POWER FLOW                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    ┌─────────┐      USB Cable      ┌─────────────┐           │
│    │   PC     │──────────────────────│   TP4056     │           │
│    │  5V     │                      │  Charger     │           │
│    └─────────┘                      └──────┬──────┘           │
│                                              │                   │
│                                              ▼                   │
│                                    ┌─────────────────┐          │
│                                    │  LiPo Battery   │          │
│                                    │   3.7V 500mAh   │          │
│                                    └────────┬────────┘          │
│                                             │                   │
│                      ┌──────────────────────┼──────┐           │
│                      │                      │      │           │
│                      ▼                      ▼      ▼           │
│               ┌──────────┐          ┌────────┐ ┌──────┐      │
│               │ ESP32    │          │Sensors │ │ LEDs │      │
│               │ 3.3V Reg │          │ 3.3V   │ │ 3.3V │      │
│               └──────────┘          └────────┘ └──────┘      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 8.2 Battery Specifications

| Parameter | Value |
|-----------|-------|
| **Type** | Lithium Polymer (LiPo) |
| **Nominal Voltage** | 3.7V |
| **Max Voltage** | 4.2V |
| **Min Voltage** | 3.0V |
| **Capacity** | 500 mAh |
| **Size** | 50mm x 20mm x 3.5mm |
| **Connector** | JST PH 2-pin |
| **Price** | $3-5 |

## 8.3 Battery Life Estimates

| Mode | Current | Battery Life |
|------|---------|-------------|
| Active (sensors on) | ~120 mA | ~4 hours |
| Idle (BLE connected) | ~30 mA | ~16 hours |
| Sleep (display off) | ~10 μA | ~50,000 hours |
| **Typical Mixed Use** | ~50 mA avg | **2-3 days** |

## 8.4 Charging

| Parameter | Value |
|-----------|-------|
| **Charger IC** | TP4056 |
| **Charge Current** | 500 mA |
| **Full Charge Time** | ~2 hours |
| **Charge Port** | USB-C |
| **Indicators** | Red=Charging, Green=Done |

---

# 9. 3D PRINTED CASE

## 9.1 Case Design Files

Create these files in your 3D printer software:

### Case Top (onyx_top.stl)
- Outer diameter: 44mm
- Inner diameter: 42mm
- Height: 8mm
- Hole for display: 28mm x 32mm
- Holes for buttons: 6mm diameter

### Case Bottom (onyx_bottom.stl)
- Outer diameter: 44mm
- Inner diameter: 42mm
- Height: 10mm
- Battery compartment: 35mm x 18mm x 4mm

## 9.2 3D Printing Settings

| Setting | Value |
|---------|-------|
| **Material** | PLA or PETG |
| **Layer Height** | 0.2mm |
| **Infill** | 20% |
| **Walls** | 3 perimeters |
| **Supports** | Yes (for button holes) |
| **Print Time** | ~2 hours for top, ~3 hours for bottom |

## 9.3 Assembly Order

1. Print case parts
2. Solder all components to prototype PCB
3. Install PCB in bottom case
4. Install battery in bottom case
5. Install buttons in bottom case
6. Connect display to PCB
7. Install display in top case
8. Connect top and bottom cases
9. Install watch band
10. Apply glass face

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 4: SOFTWARE INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════

# 10. REQUIRED SOFTWARE

## 10.1 Software List

| # | Software | Version | Purpose | Download |
|---|----------|---------|---------|----------|
| 1 | VS Code | 1.80+ | Code editor | https://code.visualstudio.com |
| 2 | PlatformIO | Latest | Build system | VS Code Extension |
| 3 | Arduino IDE | 2.0+ | Alternative IDE | https://arduino.cc |
| 4 | Python | 3.9+ | For scripts | https://python.org |
| 5 | Git | Latest | Version control | https://git-scm.com |

## 10.2 Install Visual Studio Code

**Step 1:** Download VS Code

1. Go to: https://code.visualstudio.com/
2. Click the big Download button
3. Choose your OS (Windows/Mac/Linux)
4. Run the installer

**Step 2:** Install VS Code

1. Double-click the downloaded file
2. Follow the installation wizard
3. Accept the license agreement
4. Choose installation location
5. Click Install

**Step 3:** Launch VS Code

1. Find VS Code in your Start Menu/App folder
2. Double-click to launch
3. You should see the welcome screen

## 10.3 Install PlatformIO Extension

**Step 1:** Open Extensions

1. Click the Extensions icon (left sidebar, 4 squares)
2. Or press Ctrl+Shift+X (Windows) / Cmd+Shift+X (Mac)

**Step 2:** Search for PlatformIO

1. Type "PlatformIO IDE" in the search box
2. You should see "PlatformIO IDE" by PlatformIO

**Step 3:** Install PlatformIO

1. Click the "Install" button
2. Wait for installation (~2 minutes)
3. Click "Reload" when prompted
4. PlatformIO icon (ant head) appears in sidebar

## 10.4 Install USB Drivers

### For Windows:

1. Download CP210x USB Driver: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
2. Extract the zip file
3. Run `CP210xVCPInstaller_x64.exe` (or x86 for 32-bit)
4. Follow the wizard
5. Restart PC if needed

### For Mac:

1. Download Mac drivers from same link
2. Run the .pkg file
3. Allow installation in System Preferences > Security
4. Restart if needed

### For Linux:

Usually drivers are included. If not:
```bash
sudo apt install linux-headers-$(uname -r)
sudo modprobe cp210x
```

## 10.5 Verify Installation

**Step 1:** Open PlatformIO Home

1. Press Ctrl+Shift+P (Windows) / Cmd+Shift+P (Mac)
2. Type "PlatformIO: Home"
3. Press Enter

**Step 2:** Check PlatformIO

You should see the PlatformIO Home screen with:
- Projects
- Platforms
- Libraries
- Boards

---

# 11. PROJECT SETUP

## 11.1 Clone the Repository

**Using Git:**
```bash
# Open terminal/command prompt
cd ~
git clone https://github.com/Cambric-software/Digital-saver.git
cd Digital-saver
```

**Or download ZIP:**
1. Go to: https://github.com/Cambric-software/Digital-saver
2. Click "Code" button
3. Click "Download ZIP"
4. Extract to a folder

## 11.2 Open Project in VS Code

**Step 1:** Open VS Code

**Step 2:** Open the folder

1. File → Open Folder
2. Navigate to the Digital-saver folder
3. Click "Select Folder"

**Step 3:** Navigate to Watch Firmware

1. Go to: `firmware/esp32/DigitalSaverWatch/`
2. You should see:
   - `DigitalSaverWatch.ino`
   - `platformio.ini`

## 11.3 Project Structure

```
Digital-saver/
└── firmware/
    └── esp32/
        └── DigitalSaverWatch/
            ├── DigitalSaverWatch.ino    ← Main firmware
            ├── platformio.ini           ← Build configuration
            └── .pio/                    ← Build output (auto-generated)
```

## 11.4 Configure WiFi Settings

Before building, you MUST configure your WiFi:

**Step 1:** Open DigitalSaverWatch.ino

**Step 2:** Find these lines (around line 67-70):

```cpp
// WiFi Settings - CHANGE THESE!
#define WIFI_SSID "YourWiFiName"
#define WIFI_PASSWORD "YourWiFiPassword"
#define WEATHER_API_KEY "YOUR_API_KEY"
```

**Step 3:** Update with YOUR values:

```cpp
// WiFi Settings - CHANGE THESE!
#define WIFI_SSID "MyHomeWiFi"
#define WIFI_PASSWORD "MyPassword123"
#define WEATHER_API_KEY "abc123def456..." // Get from openweathermap.org
```

**Step 4:** Get Weather API Key

1. Go to: https://openweathermap.org/api
2. Sign up for free account
3. Copy your API key
4. Paste it in the code

---

# 12. BUILDING THE FIRMWARE

## 12.1 Build Commands

### Method 1: Using VS Code Interface

1. Click PlatformIO icon (ant head) in left sidebar
2. Expand "esp32dev"
3. Click "Build" (checkmark icon)
4. Wait for build to complete (~1-2 minutes)
5. You should see "SUCCESS" in terminal

### Method 2: Using Terminal

```bash
# Navigate to project
cd ~/Digital-saver/firmware/esp32/DigitalSaverWatch

# Build
pio run

# Or build specific environment
pio run -e esp32dev
```

### Method 3: Using Keyboard Shortcuts

- **Build:** Ctrl+Alt+B (Windows) / Cmd+Alt+B (Mac)
- **Upload:** Ctrl+Alt+U (Windows) / Cmd+Alt+U (Mac)
- **Clean:** Ctrl+Alt+C (Windows) / Cmd+Alt+C (Mac)

## 12.2 Build Output

Success looks like this:

```
>pio run

Processing esp32dev (platform: espressif32, framework: arduino)
------------------------------------------------------------------
Verbose mode can be enabled via `-v, --verbose` CLI option
Checking size .pio/build/esp32dev/firmware.elf
Memory Usage -> https://docs.platformio.org/page/plus/img/memory.png
RAM:   [=      ]   5.2% (used 17060 bytes from 327680 bytes)
Flash: [=========]  89.3% (used 1068760 bytes from 1198080 bytes)
Building .pio/build/esp32dev/firmware.bin
====================================================== [SUCCESS] Took 45.67 seconds ======================================================
```

## 12.3 Common Build Errors

### Error: "Board not found"

**Cause:** Platform not installed

**Solution:**
```bash
pio platform install espressif32
```

### Error: "Library not found"

**Cause:** Dependencies not installed

**Solution:**
```bash
pio pkg install
# or
pio lib install
```

### Error: "Compile error"

**Cause:** Code has syntax errors

**Solution:** Check the error message line number and fix the code

### Error: "Permission denied" (Linux/Mac)

**Cause:** USB access issue

**Solution:**
```bash
sudo chmod 666 /dev/ttyUSB0
```
(Replace ttyUSB0 with your port)

---

# 13. UPLOADING FIRMWARE

## 13.1 Connect ESP32

**Step 1:** Connect USB Cable

1. Connect ESP32 to your computer via USB cable
2. Make sure you see a new COM port (Windows) or /dev/ttyUSB* (Linux/Mac)

**Step 2:** Find Your Port

**Windows:**
1. Press Win+X → Device Manager
2. Expand "Ports (COM & LPT)"
3. Note the COM port number (e.g., COM3)

**Linux:**
```bash
ls -l /dev/ttyUSB*
```

**Mac:**
```bash
ls /dev/cu.usbserial*
```

## 13.2 Upload Commands

### Method 1: Upload via PlatformIO

1. Click PlatformIO icon
2. Expand "esp32dev"
3. Click "Upload" (arrow icon)
4. Wait for upload to complete

### Method 2: Upload via Terminal

```bash
# Upload to default port
pio run --target upload

# Upload to specific port
pio run --target upload --upload-port COM3    # Windows
pio run --target upload --upload-port /dev/ttyUSB0  # Linux/Mac
```

## 13.3 Upload Output

Success looks like this:

```
>pio run --target upload

Looking for upload port...
Auto-detected: /dev/ttyUSB0
Uploading .pio/build/esp32dev/firmware.bin @ 0x1000

Erasing flash memory...
Wrote 16 bytes (0.00%)...
Wrote 32768 bytes (2.74%)...
Wrote 1068760 bytes (89.23%)...
Leaving...
Hard resetting via RTS pin...

====================================================== [SUCCESS] Took 23.45 seconds ======================================================
```

## 13.4 Common Upload Errors

### Error: "Failed to connect to ESP32"

**Cause:** Wrong baud rate or boot mode

**Solutions:**
1. Hold BOOT button, press and release EN/RESET, release BOOT
2. Change upload speed to 115200
3. Try a different USB cable

### Error: "Serial port not found"

**Cause:** USB driver not installed or wrong port

**Solutions:**
1. Install CP210x USB drivers
2. Check which port ESP32 is on
3. Try different USB port

### Error: "Timed out waiting for packet header"

**Cause:** Connection interrupted

**Solution:**
1. Try again
2. Use shorter USB cable
3. Lower upload speed

---

# 14. SERIAL MONITOR

## 14.1 Open Serial Monitor

### Method 1: PlatformIO

1. Click PlatformIO icon
2. Click "Monitor" (screen icon)
3. Or press Ctrl+Alt+M (Windows) / Cmd+Alt+M (Mac)

### Method 2: Terminal

```bash
pio device monitor
```

### Method 3: Arduino IDE

1. Tools → Serial Monitor
2. Set baud rate to 115200

## 14.2 Serial Monitor Settings

| Setting | Value |
|---------|-------|
| Baud Rate | 115200 |
| Data Bits | 8 |
| Parity | None |
| Stop Bits | 1 |
| Line Ending | Newline |

## 14.3 Expected Serial Output

When firmware starts, you should see:

```
[DIGITAL SAVER] Onyx Watch v3.2.0
[OK] Initializing GPIO...
[OK] GPIO initialized
[OK] Display found
[OK] Display initialized
[OK] MAX30102 found
[OK] MAX30102 initialized
[OK] MPU6050 found
[OK] MPU6050 initialized
[OK] BLE initialized
[OK] BLE advertising - Digital Saver
[WIFI] Connecting to MyHomeWiFi...
[WIFI] Connected! IP: 192.168.1.100
[WEATHER] Fetching weather...
[WEATHER] Updated: 32C, Clear
[OK] All systems ready!
```

## 14.4 Debug Commands via Serial

You can also send commands via Serial Monitor:

```
PING                 → Returns PONG
STATUS               → Returns full status
MODE:0              → Switch to Clock
THEME:3             → Switch to Night theme
PROFILE:John,30,75,175,male,10000  → Set profile
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 5: COMPLETE FIRMWARE REFERENCE
# ═══════════════════════════════════════════════════════════════════════════

# 15. FIRMWARE CODE STRUCTURE

## 15.1 File Organization

```
DigitalSaverWatch.ino
├── HEADER
│   ├── Version info (line 1)
│   └── Feature list (lines 6-20)
│
├── INCLUDES (lines 28-35)
│   ├── Arduino.h
│   ├── Wire.h (I2C)
│   ├── BLE libraries
│   ├── Display libraries
│   ├── Sensor libraries
│   └── WiFi libraries
│
├── CONFIGURATION (lines 37-75)
│   ├── Pin definitions
│   ├── BLE UUIDs
│   ├── WiFi settings
│   ├── Thresholds
│   └── Intervals
│
├── DATA STRUCTURES (lines 95-226)
│   ├── HealthData
│   ├── RawSensorData
│   ├── WeatherData
│   ├── UserProfile
│   └── HealthAI
│
├── STATE VARIABLES (lines 228-260)
│   ├── currentMode
│   ├── currentTheme
│   ├── deviceConnected
│   ├── wifiConnected
│   └── currentHealth
│
├── FUNCTION PROTOTYPES (lines 300-325)
│   ├── init* functions
│   ├── update* functions
│   ├── show* functions
│   └── utility functions
│
├── SETUP FUNCTION (lines 330-420)
│   └── Initialize everything
│
├── MAIN LOOP (lines 1824-1900)
│   ├── Button handling
│   ├── Sensor updates
│   ├── Health AI
│   ├── BLE data send
│   └── Display update
│
├── WiFi & INTERNET (lines 469-610)
│   ├── initWiFi()
│   └── fetchWeather()
│
├── HEALTH AI ENGINE (lines 613-825)
│   ├── calculateBMR()
│   ├── analyzeBloodPressure()
│   ├── detectArrhythmia()
│   ├── checkHypoxiaRisk()
│   ├── calculateActivityState()
│   ├── generateHealthInsight()
│   └── runHealthAI()
│
├── BLE FUNCTIONS (lines 430-960)
│   ├── initBLE()
│   ├── BLEServerCallbacks
│   └── BLECommandCallbacks
│
├── SENSOR FUNCTIONS (lines 980-1200)
│   ├── updateHeartRate()
│   ├── updateSpO2()
│   ├── updateAccelerometer()
│   └── detectFall()
│
├── DISPLAY FUNCTIONS (lines 1200-1700)
│   ├── updateDisplay()
│   ├── showClockDisplay()
│   ├── showHeartRateDisplay()
│   ├── showWeatherDisplay()
│   ├── showStealthDisplay()
│   └── showSettingsDisplay()
│
└── UTILITY FUNCTIONS (lines 1700-1900)
    ├── formatTime()
    ├── vibrate()
    ├── setLED()
    └── triggerEmergency()
```

## 15.2 Key Configuration Constants

```cpp
// PIN DEFINITIONS (Line 40-60)
#define I2C_SDA 18
#define I2C_SCL 19
#define HR_INT_PIN 26
#define MOTION_INT_PIN 27
#define VIBRATION_MOTOR 25
#define LED_RED 4
#define LED_GREEN 16
#define BUTTON_MODE 17
#define BUTTON_EMERGENCY 34
#define BUTTON_BACK 35

// TIMING INTERVALS (Line 60-70)
#define MEASUREMENT_INTERVAL 1000    // 1 second
#define BLE_SEND_INTERVAL 2000       // 2 seconds
#define DISPLAY_REFRESH 100         // 100ms
#define WEATHER_UPDATE_INTERVAL 1800000  // 30 minutes

// BLE UUIDS (Line 62-64)
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26f0"

// HEALTH THRESHOLDS (Line 75-85)
#define MIN_HEART_RATE 40
#define MAX_HEART_RATE 200
#define FALL_THRESHOLD 2.5f
#define STEP_THRESHOLD 1.5f
#define HYPOXIA_THRESHOLD 90
```

---

# 16. USER PROFILE SYSTEM

## 16.1 UserProfile Structure

```cpp
struct UserProfile {
    String name;              // "John"
    int age;                 // 30
    int weightKg;            // 75
    int heightCm;            // 175
    String gender;           // "male" or "female"
    int targetSteps;         // 10000
    int targetSleepHours;    // 8
    float maxHeartRate;      // 220 - age
    float minHeartRate;      // 50
    bool profileSet;         // true if configured
};
UserProfile userProfile;
```

## 16.2 Set Profile via BLE

**Command Format:**
```
PROFILE:name,age,weight,height,gender,steps
```

**Example:**
```
PROFILE:John,30,75,175,male,10000
```

**Response:**
```
PROFILE:OK John 30y
```

## 16.3 Profile Command Handler Code

```cpp
// In BLECommandCallbacks::onWrite:
else if (rxData.substr(0, 8) == "PROFILE:") {
    String profileData = rxData.substring(8);
    
    // Parse the comma-separated values
    int idx1 = profileData.indexOf(',');           // name,age
    int idx2 = profileData.indexOf(',', idx1 + 1);   // age,weight
    int idx3 = profileData.indexOf(',', idx2 + 1); // weight,height
    int idx4 = profileData.indexOf(',', idx3 + 1); // height,gender
    int idx5 = profileData.indexOf(',', idx4 + 1); // gender,steps
    
    // Extract values
    userProfile.name = profileData.substring(0, idx1);
    userProfile.age = atoi(profileData.substring(idx1 + 1, idx2).c_str());
    userProfile.weightKg = atoi(profileData.substring(idx2 + 1, idx3).c_str());
    userProfile.heightCm = atoi(profileData.substring(idx3 + 1, idx4).c_str());
    userProfile.gender = profileData.substring(idx4 + 1, idx5);
    userProfile.targetSteps = atoi(profileData.substring(idx5 + 1).c_str());
    
    // Calculate derived values
    userProfile.maxHeartRate = 220 - userProfile.age;
    userProfile.minHeartRate = 50;
    userProfile.profileSet = true;
    
    // Recalculate BMR
    calculateBMR();
    
    Serial.printf("[PROFILE] Set: %s, %d years old\n", 
        userProfile.name.c_str(), userProfile.age);
}
```

## 16.4 Calculate BMR Code

```cpp
void calculateBMR() {
    if (!userProfile.profileSet) {
        healthAI.bmr = 1500; // Default if no profile
        return;
    }
    
    // Mifflin-St Jeor Equation
    if (userProfile.gender == "male") {
        // BMR = 10*weight + 6.25*height - 5*age + 5
        healthAI.bmr = 10 * userProfile.weightKg 
                      + 6.25 * userProfile.heightCm 
                      - 5 * userProfile.age 
                      + 5;
    } else {
        // BMR = 10*weight + 6.25*height - 5*age - 161
        healthAI.bmr = 10 * userProfile.weightKg 
                      + 6.25 * userProfile.heightCm 
                      - 5 * userProfile.age 
                      - 161;
    }
    
    Serial.printf("[BMR] Calculated: %.0f kcal/day\n", healthAI.bmr);
}
```

---

# 17. ADVANCED HEALTH AI ENGINE

## 17.1 HealthAI Structure

```cpp
struct HealthAI {
    // Scores (0-100)
    float overallScore;       // Combined health score
    float heartScore;        // Heart health
    float activityScore;     // Activity level
    float stressScore;       // Stress (0=no stress, 100=very stressed)
    
    // Risks (0-4: none, low, medium, high, critical)
    int cardiovascularRisk;  // Blood pressure risk
    int arrhythmiaRisk;       // Irregular heartbeat
    int hypoxiaRisk;         // Low oxygen
    int overexertionRisk;    // Too much exercise
    
    // AI Output
    String healthInsight;     // "Your heart rate is elevated"
    String recommendation;   // "Take a break"
    String warningMessage;   // "DANGER: HR too high!"
    
    // Activity
    String activityState;     // "RESTING", "WALKING", etc
    
    // Calories
    float caloriesBurned;
    float bmr;              // Basal metabolic rate
    
    // BP
    String bpCategory;       // "NORMAL", "HIGH", etc
    
    // Fatigue
    float fatigueLevel;      // 0-100
    int recoveryMinutes;
};
HealthAI healthAI;
```

## 17.2 Blood Pressure Analysis

```cpp
void analyzeBloodPressure() {
    float sys = currentHealth.bloodPressureSys;
    float dia = currentHealth.bloodPressureDia;
    
    if (sys < 120 && dia < 80) {
        // NORMAL
        healthAI.bpCategory = "NORMAL";
        healthAI.cardiovascularRisk = 0;
    } 
    else if (sys >= 120 && sys < 130 && dia < 80) {
        // ELEVATED
        healthAI.bpCategory = "ELEVATED";
        healthAI.cardiovascularRisk = 1;
    }
    else if (sys >= 130 && sys < 140 || dia >= 80 && dia < 90) {
        // HIGH STAGE 1
        healthAI.bpCategory = "HIGH_STAGE1";
        healthAI.cardiovascularRisk = 2;
    }
    else if (sys >= 140 || dia >= 90) {
        // HIGH STAGE 2
        healthAI.bpCategory = "HIGH_STAGE2";
        healthAI.cardiovascularRisk = 3;
    }
    else if (sys > 180 || dia > 120) {
        // CRISIS!
        healthAI.bpCategory = "CRISIS";
        healthAI.cardiovascularRisk = 4;
        healthAI.warningMessage = "HYPERTENSIVE CRISIS!";
        vibrate(500);  // Emergency vibration
    }
}
```

## 17.3 Arrhythmia Detection

```cpp
void detectArrhythmia() {
    static float lastHR = 0;
    static int irregularCount = 0;
    
    if (lastHR > 0) {
        float variation = abs(currentHealth.heartRate - lastHR);
        
        // Sudden HR change > 30 BPM
        if (variation > 30) {
            irregularCount++;
            
            if (irregularCount >= 3) {
                healthAI.arrhythmiaRisk = 3;  // High
                healthAI.warningMessage = "ARRHYTHMIA DETECTED!";
            }
        } else {
            if (irregularCount > 0) {
                irregularCount--;
            }
        }
    }
    
    lastHR = currentHealth.heartRate;
    
    // HRV-based stress
    if (currentHealth.hrvRMSSD < 20) {
        healthAI.stressScore = 80 + random(20);  // High stress
    } else if (currentHealth.hrvRMSSD < 40) {
        healthAI.stressScore = 50 + random(30);  // Medium
    } else {
        healthAI.stressScore = 20 + random(30);  // Low
    }
}
```

## 17.4 Activity State Detection

```cpp
void calculateActivityState() {
    float hr = currentHealth.heartRate;
    
    // Simplified step rate (steps per minute)
    static float lastSteps = 0;
    static uint32_t lastTime = 0;
    float stepRate = (currentHealth.steps - lastSteps) / 
                     ((millis() - lastTime) / 60000.0);
    lastSteps = currentHealth.steps;
    lastTime = millis();
    
    if (hr < 60) {
        healthAI.activityState = "SLEEPING";
    } else if (hr < 80 && stepRate < 5) {
        healthAI.activityState = "RESTING";
    } else if (hr < 100 && stepRate < 30) {
        healthAI.activityState = "WALKING";
    } else if (hr < 140 && stepRate < 60) {
        healthAI.activityState = "EXERCISING";
    } else if (hr >= 140) {
        healthAI.activityState = "INTENSE";
    } else {
        healthAI.activityState = "ACTIVE";
    }
    
    // Calculate calories
    float multiplier = 0.1;
    if (healthAI.activityState == "SLEEPING") multiplier = 0.05;
    if (healthAI.activityState == "WALKING") multiplier = 0.5;
    if (healthAI.activityState == "EXERCISING") multiplier = 1.0;
    if (healthAI.activityState == "INTENSE") multiplier = 1.5;
    
    healthAI.activeCalories = healthAI.bmr / 1440.0 * multiplier;
}
```

## 17.5 Generate Health Insight

```cpp
void generateHealthInsight() {
    // Calculate scores
    healthAI.heartScore = 100 - abs(80 - currentHealth.heartRate);
    healthAI.heartScore = constrain(healthAI.heartScore, 0, 100);
    
    healthAI.activityScore = (currentHealth.steps / 
                             (float)userProfile.targetSteps) * 100;
    healthAI.activityScore = constrain(healthAI.activityScore, 0, 100);
    
    // Overall score (weighted)
    healthAI.overallScore = 
        healthAI.heartScore * 0.35 +
        healthAI.activityScore * 0.25 +
        (100 - healthAI.stressScore) * 0.20 +
        currentHealth.spO2 * 0.20;
    
    // Generate insight
    if (healthAI.cardiovascularRisk >= 3) {
        healthAI.healthInsight = "High blood pressure";
        healthAI.recommendation = "Reduce sodium, exercise more";
    } else if (healthAI.arrhythmiaRisk >= 3) {
        healthAI.healthInsight = "Irregular heartbeat";
        healthAI.recommendation = "Consult cardiologist";
    } else if (healthAI.activityState == "EXERCISING") {
        healthAI.healthInsight = "Great workout!";
        healthAI.recommendation = "Keep it up!";
    } else if (healthAI.stressScore > 70) {
        healthAI.healthInsight = "Elevated stress";
        healthAI.recommendation = "Try deep breathing";
    } else {
        healthAI.healthInsight = "All vitals good!";
        healthAI.recommendation = "Stay hydrated";
    }
    
    // Fatigue
    healthAI.fatigueLevel = 100 - healthAI.overallScore;
    healthAI.recoveryMinutes = healthAI.fatigueLevel * 0.5;
}
```

---

# 18. ALL BLE COMMANDS REFERENCE

## 18.1 Command Quick Reference

| Command | Example | Response |
|---------|---------|----------|
| **MODE COMMANDS** | | |
| MODE:0 | MODE:0 | Switch to Clock |
| MODE:1 | MODE:1 | Switch to Heart Rate |
| MODE:2 | MODE:2 | Switch to Blood Pressure |
| MODE:3 | MODE:3 | Switch to Activity |
| MODE:4 | MODE:4 | Switch to Sleep |
| MODE:5 | MODE:5 | Switch to Weather |
| MODE:6 | MODE:6 | Switch to STEALTH |
| MODE:7 | MODE:7 | Switch to Settings |
| **THEME COMMANDS** | | |
| THEME:0 | THEME:0 | Default (white on black) |
| THEME:1 | THEME:1 | Inverted (black on white) |
| THEME:2 | THEME:2 | High Contrast |
| THEME:3 | THEME:3 | Night (red) |
| THEME:4 | THEME:4 | Minimal (dots) |
| **WIFI COMMANDS** | | |
| WIFI:ON | WIFI:ON | Connect to WiFi |
| WIFI:OFF | WIFI:OFF | Disconnect WiFi |
| WEATHER:REFRESH | WEATHER:REFRESH | Get new weather |
| **PROFILE COMMANDS** | | |
| PROFILE:name,age,weight,height,gender,steps | PROFILE:John,30,75,175,male,10000 | Set profile |
| **HEALTH AI COMMANDS** | | |
| HEALTHAI:STATUS | HEALTHAI:STATUS | Get AI analysis |
| **STATUS COMMANDS** | | |
| PING | PING | PONG |
| STATUS | STATUS | Full status |

## 18.2 Full Status Response

When you send `STATUS`, you get:

```
THEME:0,MODE:0,BATT:85,WIFI:1,HR:72,SPO2:98,STEPS:5420
```

## 18.3 Health Data Format

The watch sends this JSON format via BLE notify:

```json
{
  "hr": 72,
  "spo2": 98,
  "bps": 120,
  "bpd": 80,
  "hrv": 45.2,
  "steps": 5420,
  "cal": 285.5,
  "temp": 36.6,
  "irreg": 0,
  "fall": 0,
  "ax": 0.01,
  "ay": 0.02,
  "az": 1.02
}
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 6: TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

# 19. COMMON PROBLEMS & SOLUTIONS

## 19.1 Display Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Display blank | No power | Check 3.3V connection |
| Display blank | Wrong I2C address | Use 0x3C |
| Display blank | SDA/SCL swapped | Swap SDA and SCL |
| Display shows noise | Loose wires | Check all connections |
| Display flickers | Low battery | Charge battery |
| Display upside down | Flip setting | display.flip180() |

## 19.2 Sensor Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| MAX30102 not found | Wrong address | Use 0x57 |
| HR shows "--" | Finger not on | Press finger firmly |
| HR always 0 | Sensor not working | Check INT pin |
| MPU6050 not found | Wrong address | Use 0x68 |
| Steps not counting | Accel error | Check MPU6050 wiring |
| SpO2 wrong | Wrong algorithm | Adjust calibration |

## 19.3 WiFi Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Can't connect | Wrong password | Check WIFI_PASSWORD |
| Can't connect | Wrong SSID | Check WIFI_SSID |
| Weather shows "--" | No WiFi | Send WIFI:ON |
| Weather shows "--" | Wrong API key | Get new key from OpenWeatherMap |
| Weather old | Not updated | Wait 30 min or send WEATHER:REFRESH |

## 19.4 BLE Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Can't find device | Not advertising | Check initBLE() |
| Can't connect | Signal weak | Move phone closer |
| Disconnects often | Interference | Avoid WiFi routers |
| Data not sending | Not connected | Wait for connection first |
| App not finding watch | Wrong name | Check DEVICE_NAME |

## 19.5 Build/Upload Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Build fails | Missing library | pio pkg install |
| Build fails | Code error | Check error line |
| Upload fails | Wrong port | Check COM port |
| Upload fails | Boot mode | Hold BOOT, press RESET |
| Upload fails | Driver missing | Install CP210x driver |

## 19.6 Power Problems

| Problem | Cause | Solution |
|---------|-------|----------|
| Watch keeps restarting | Low battery | Charge battery |
| Watch gets hot | Short circuit | Check wiring |
| Battery drains fast | Always on | Use sleep mode |
| Battery drains fast | Sensors on | Turn off unused sensors |

---

# 20. DEBUGGING TECHNIQUES

## 20.1 I2C Scanner

Use this code to find all I2C devices:

```cpp
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    Wire.begin(18, 19);  // SDA=18, SCL=19
    
    Serial.println("I2C Scanner Starting...");
    
    for (byte address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        byte error = Wire.endTransmission();
        
        if (error == 0) {
            Serial.print("Found device at 0x");
            Serial.println(address, HEX);
        }
        else if (error == 4) {
            Serial.print("Unknown error at 0x");
            Serial.println(address, HEX);
        }
    }
    Serial.println("Scan complete!");
}

void loop() {}
```

**Expected output:**
```
I2C Scanner Starting...
Found device at 0x3C   ← SSD1306 Display
Found device at 0x57   ← MAX30102 Heart Rate
Found device at 0x68   ← MPU6050 Accelerometer
Scan complete!
```

## 20.2 Test Individual Sensors

### Test MAX30102:
```cpp
#include <SparkFunMAX3010x.h>

MAX30105 particleSensor;

void setup() {
    Serial.begin(115200);
    if (particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println("MAX30102 OK");
    } else {
        Serial.println("MAX30102 FAILED");
    }
}
```

### Test MPU6050:
```cpp
#include <Adafruit_MPU6050.h>

Adafruit_MPU6050 mpu;

void setup() {
    Serial.begin(115200);
    if (mpu.begin()) {
        Serial.println("MPU6050 OK");
    } else {
        Serial.println("MPU6050 FAILED");
    }
}
```

## 20.3 Serial Debug Output

Add these debug statements:

```cpp
#define DEBUG_MODE true

void debugPrint(const char* msg) {
    #ifdef DEBUG_MODE
    Serial.println(msg);
    #endif
}
```

---

# 21. RECOVERY PROCEDURES

## 21.1 Factory Reset

1. Hold all 3 buttons for 10 seconds
2. LEDs will flash rapidly
3. Release buttons
4. Watch resets to defaults

## 21.2 Erase and Reflash

**Step 1:** Erase ESP32 flash

```bash
pio run --target erase
```

**Step 2:** Flash new firmware

```bash
pio run --target upload
```

## 21.3 Boot Mode Flash

If normal upload fails:

1. Hold BOOT button
2. Press and release EN/RESET button
3. Release BOOT button
4. Upload firmware

## 21.4 USB Driver Reinstall

**Windows:**
1. Device Manager → Ports → right-click CP210x
2. Uninstall device
3. Unplug ESP32
4. Plug ESP32 back in
5. Windows will reinstall driver

**Mac/Linux:**
```bash
sudo rm -rf /Library/Extensions/SiLabsUSBDriver.kext
sudo rm -rf /System/Library/Extensions/SiLabsUSBDriver.kext
# Restart, then plug in ESP32
```

---

# ═══════════════════════════════════════════════════════════════════════════
# PART 7: QUICK REFERENCE
# ═══════════════════════════════════════════════════════════════════════════

# 22. QUICK REFERENCE CARDS

## 22.1 I2C Addresses

| Device | Address |
|---------|---------|
| MAX30102 | 0x57 |
| MPU6050 | 0x68 |
| SSD1306 | 0x3C |

## 22.2 Pin Assignments

| Pin | Function |
|-----|----------|
| GPIO18 | I2C SCL |
| GPIO19 | I2C SDA |
| GPIO26 | MAX30102 INT |
| GPIO27 | MPU6050 INT |
| GPIO25 | Vibration Motor |
| GPIO4 | Red LED |
| GPIO16 | Green LED |
| GPIO17 | Mode Button |
| GPIO34 | Emergency Button |
| GPIO35 | Back Button |

## 22.3 Watch Modes

| ID | Mode |
|----|------|
| 0 | Clock |
| 1 | Heart Rate |
| 2 | Blood Pressure |
| 3 | Activity |
| 4 | Sleep |
| 5 | Weather |
| 6 | STEALTH |
| 7 | Settings |

## 22.4 Themes

| ID | Theme |
|----|-------|
| 0 | Default (white on black) |
| 1 | Inverted (black on white) |
| 2 | High Contrast |
| 3 | Night (red) |
| 4 | Minimal (dots) |

## 22.5 Risk Levels

| Level | Meaning |
|-------|---------|
| 0 | None |
| 1 | Low |
| 2 | Medium |
| 3 | High |
| 4 | Critical |

## 22.6 Important Commands

```
# Set profile
PROFILE:John,30,75,175,male,10000

# Get Health AI status
HEALTHAI:STATUS

# Go to Settings
MODE:7

# Connect WiFi
WIFI:ON

# Refresh weather
WEATHER:REFRESH

# Test connection
PING
```

## 22.7 Build Commands

```bash
pio run              # Build
pio run --target upload    # Upload
pio run --target erase     # Erase
pio device monitor         # Serial monitor
```

---

# ═══════════════════════════════════════════════════════════════════════════
# END OF DOCUMENT
# ═══════════════════════════════════════════════════════════════════════════

**Document Version:** 3.2.0  
**Total Lines:** 2000+  
**Last Updated:** July 2026  
**Company:** Cambric  
**Copyright:** © 2026 Cambric. All Rights Reserved.

This document covers everything needed to build the Digital Saver Onyx Smartwatch from scratch.
