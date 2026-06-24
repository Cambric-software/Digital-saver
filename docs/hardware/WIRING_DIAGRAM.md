# Digital Saver - Complete Wiring Diagram & Assembly Guide

## 🔌 Pin Connection Overview

### ESP32-WROOM-32 DevKit Pinout
```
    +------------------+
    |                  |
    |   ESP32-WROOM-32 |
    |    DevKit v4     |
    |                  |
GND-| 1  2  3  4  5   |-VIN (5V USB)
    | 6  7  8  9  10  |-GND
    | 11 12 13 14 15   |-3V3
    | 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33|
    |------------------------------------------------|
    +------------------------------------------------+

Key Pins Used:
- 3V3  → Power (3.3V)
- GND  → Ground
- GPIO 21 (SDA) → I2C Data
- GPIO 22 (SCL) → I2C Clock
- GPIO 26 → MAX30102 INT (Interrupt)
- GPIO 25 → Vibration Motor
- GPIO 4  → Red LED
- GPIO 16 → Green LED
- GPIO 17 → Button 1 (Mode)
- GPIO 34 → Button 2 (Emergency)
- GPIO 35 → Button 3 (Back)
- GPIO 5  → Display Reset
```

---

## 🔴 CONNECTING THE MAX30102 (Heart Rate + SpO2)

### MAX30102 Pinout
```
    +-------------------+
    |   MAX30102 Module |
    |                   |
SCL |-------+           |
    |       |           |
SDA |-------+           |
    |               --- |
VCC |-------------|   |-|-- VIN (3.3V)
GND |-------------|___|-|-- GND
    |                   |
INT |-------------------|
    +-------------------+
```

### Wiring (MAX30102 → ESP32)
| MAX30102 | ESP32 | Wire Color | Notes |
|----------|-------|------------|-------|
| VCC | 3V3 | Red | 3.3V power |
| GND | GND | Black | Ground |
| SDA | GPIO 21 (SDA) | Yellow | I2C Data |
| SCL | GPIO 22 (SCL) | Orange | I2C Clock |
| INT | GPIO 26 | Blue | Interrupt output |

### I2C Address
- MAX30102 default address: **0x57** (binary: 1010111)

---

## 📐 CONNECTING THE MPU6050 (Accelerometer + Gyroscope)

### MPU6050 Pinout
```
    +-------------------+
    |   MPU6050 Module  |
    |                   |
VCC |-------------|     |
GND |-------------|-----+
    |               --- |
SCL |-------------|   |-|-- I2C Clock
SDA |-------------|___|-|-- I2C Data
    |               --- |
INT |-------------|   |-|-- Interrupt
    +-------------------+
```

### Wiring (MPU6050 → ESP32)
| MPU6050 | ESP32 | Wire Color | Notes |
|---------|-------|------------|-------|
| VCC | 3V3 | Red | 3.3V power |
| GND | GND | Black | Ground |
| SDA | GPIO 21 (SDA) | Yellow | I2C Data (shared with MAX30102) |
| SCL | GPIO 22 (SCL) | Orange | I2C Clock (shared with MAX30102) |
| INT | GPIO 27 | Purple | Interrupt output |

### I2C Address
- MPU6050 default address: **0x68** (can be 0x69 if AD0 is HIGH)

---

## 📺 CONNECTING THE OLED DISPLAY (SSD1306)

### OLED 0.96" Pinout
```
    +-------------------+
    |   OLED 0.96"     |
    |   (SSD1306)      |
    |                   |
GND |-------------------|
VCC |-------------------|
SCL |-------------------|
SDA |-------------------|
    +-------------------+
```

### Wiring (OLED → ESP32)
| OLED | ESP32 | Wire Color | Notes |
|------|-------|------------|-------|
| VCC | 3V3 | Red | 3.3V power |
| GND | GND | Black | Ground |
| SCL | GPIO 22 (SCL) | Orange | I2C Clock (shared) |
| SDA | GPIO 21 (SDA) | Yellow | I2C Data (shared) |

### I2C Address
- SSD1306 default address: **0x3C**

---

## 🔋 CONNECTING BATTERY & CHARGING

### TP4056 LiPo Charger Pinout
```
    +---------------------+
    |     TP4056          |
    |                     |
    |  B+  B-  OUT  OUT   |
    |  |   |   |    |     |
    |  |   |   |    |     |
    +---------------------+
      |   |   |    |
      |   |   |    +--- USB+ → USB 5V
      |   |   +-------- USB- → USB GND
      |   +------------ Battery-
      +---------------- Battery+
```

### Complete Power Circuit
```
                    +------------------+
                    |                  |
    USB 5V ----→----| VIN          3V3 |------→ ESP32 (3.3V)
    USB GND ----→---| GND          GND |------→ All GND
                    |                  |
                    |   TP4056 Module  |
                    |                  |
    Battery + ----→--| B+             |
    Battery - ----→--| B-             |
                    |                  |
                    +------------------+
```

### Detailed Wiring
| Component | TP4056 | Wire Color | Notes |
|-----------|--------|------------|-------|
| Battery + | B+ | Red | LiPo battery positive |
| Battery - | B- | Black | LiPo battery negative |
| ESP32 VIN | OUT+ or directly to USB 5V | Red | Power input |
| ESP32 GND | OUT- or directly to USB GND | Black | Ground |

### IMPORTANT: Battery Protection
- ALWAYS use a LiPo battery with built-in protection circuit
- NEVER short battery wires
- Connect B+ and B- to battery BEFORE connecting to circuit
- TP4056's built-in protection: overcharge, over-discharge, short circuit

---

## 🖐️ CONNECTING BUTTONS

### Button Circuit (Pull-Down Resistor)
```
         10kΩ
  3V3 ───/\/\/────┬──── Button ──── GND
                  │
                  └──── GPIO (Input)
```

### Button Wiring
| Button | ESP32 GPIO | Wire Color | Function |
|--------|------------|------------|---------|
| Button 1 (Mode) | GPIO 17 | Blue | Cycle through modes |
| Button 2 (Emergency) | GPIO 34 | Red | Send emergency alert |
| Button 3 (Back) | GPIO 35 | Green | Go back / Dismiss |

### Button Connection Details
| Button | 10kΩ Resistor | ESP32 | Ground |
|--------|---------------|-------|--------|
| 1 | → GPIO 17 | → GPIO 17 | → GND |
| 2 | → GPIO 34 | → GPIO 34 | → GND |
| 3 | → GPIO 35 | → GPIO 35 | → GND |

**Note:** GPIO 34, 35, 36, 39 are input-only (no internal pull-ups)

---

## 💡 CONNECTING LEDs

### LED Circuit (with Resistor)
```
         330Ω
  3V3 ───/\/\/────┬──── LED+ ──── LED- ──── GPIO
                  |
```

### LED Wiring
| LED | ESP32 GPIO | Resistor | Notes |
|-----|------------|----------|-------|
| Red LED | GPIO 4 | 330Ω | Status indicator |
| Green LED | GPIO 16 | 330Ω | Status indicator |

### LED Color Code
| State | Red LED | Green LED |
|-------|---------|-----------|
| Booting | ON | OFF |
| Connected to phone | OFF | ON |
| Measuring | Blinking | Blinking |
| Emergency | Fast Blink | OFF |
| Error | ON | OFF |

---

## 📳 CONNECTING VIBRATION MOTOR

### Vibration Motor Pinout
```
    +-------------------+
    |   Vibration Motor |
    |   (3V, 80mA)     |
    |                   |
  +-----------------------+
  |                       |
  |     (+)         (-)   |
  +-----------------------+
    |                   |
    |                   |
```

### Motor Wiring
| Motor | ESP32 | External Power | Notes |
|-------|-------|----------------|-------|
| Motor + | GPIO 25 (via transistor) | 3.3V via transistor | Can't drive directly |
| Motor - | GND | - | Ground |

### Transistor Circuit (For Motor Control)
```
         1kΩ
GPIO ───/\/\/────┬──── Base (NPN: 2N2222)
                 |
              Collector ─── Motor ─── 3V3
                 |
              Emitter ─── GND
```

**OR use a Relay Module (simpler):**
| Relay Module | ESP32 | Power | Motor |
|--------------|-------|-------|-------|
| IN | GPIO 25 | - | - |
| VCC | 3V3 | - | - |
| GND | GND | - | - |
| COM | - | - | 3V3 |
| NO | - | - | Motor+ |

---

## 🔗 COMPLETE WIRING DIAGRAM (Visual)

```
                         I2C BUS (SCL/SDA)
                              │
              ┌───────────────┼───────────────┐
              │               │               │
             SCL            SDA             VCC
              │               │               │
    ┌─────────┴─────────┐     │     ┌─────────┴─────────┐
    │                   │     │     │                   │
 [MAX30102]         [MPU6050] │  [OLED 0.96"]
    │                   │     │     │                   │
    │ GPIO 26 (INT)    │     │     │                   │
    │                   │     │     │                   │
    └─────────┬─────────┴─────┴─────┴───────────────────┘
              │               │               │
             GND            GND             GND
              │               │               │
              └───────────────┼───────────────┘
                              │
                         ALL GND BUS
                              │
              ┌───────────────┼───────────────┐
              │               │               │
           [TP4056]       [ESP32]         [LEDs]
              │               │               │
              │            VIN 5V            │
         Battery+            │            GPIO 4 (R)
         Battery-           GND            GPIO 16 (G)
              │               │               │
              │          USB 5V              │
              │               │               │
              └───────────────┴───────────────┘
                              │
                         USB POWER
```

---

## 🎯 STEP-BY-STEP ASSEMBLY

### Step 1: Prepare Workspace
1. Clear desk and ground yourself (touch metal)
2. Organize all components
3. Verify all components work before soldering

### Step 2: Test I2C Devices First
**BEFORE soldering, test on breadboard:**

```
ESP32    →    Breadboard    →    MAX30102
3V3      →    3V3 rail      →    VCC
GND      →    GND rail      →    GND
GPIO 21  →    SDA row       →    SDA
GPIO 22  →    SCL row       →    SCL
```

**Test with this Arduino code:**
```cpp
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22); // ESP32 SDA, SCL
}

void loop() {
  byte error, address;
  Serial.println("Scanning I2C...");
  
  for(address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      Serial.print("I2C found: 0x");
      Serial.println(address, HEX);
    }
  }
  delay(1000);
}
```

**Expected addresses:**
- MAX30102: 0x57
- MPU6050: 0x68 (or 0x69)
- OLED SSD1306: 0x3C

### Step 3: Solder Components to PCB

**Soldering Order:**
1. Sockets (for ESP32, sensors) - allows replacement
2. Passive components (resistors, capacitors)
3. connectors (battery, display, buttons)
4. Active components (LEDs, transistors)

**Soldering Tips:**
- Use flux pen for easier soldering
- Keep iron tip clean (brass wool)
- Don't hold iron on component for >3 seconds
- Check polarity on LEDs, battery connector

### Step 4: Connect Power System
1. Solder TP4056 to PCB
2. Connect battery connector (observe polarity!)
3. Test with multimeter: 3.3V on ESP32 3V3 pin
4. Test charging: plug in USB, LED should be red

### Step 5: Mount in Case
1. Use double-sided tape to mount ESP32
2. Use hot glue for battery and sensors
3. Secure OLED with screws (if case has standoffs)
4. Route wires neatly, use zip ties

### Step 6: Upload Firmware
1. Connect USB-Serial converter (or use ESP32's USB)
2. Open Arduino IDE / PlatformIO
3. Select correct board: "ESP32 Dev Module"
4. Upload firmware
5. Test all functions

---

## ⚠️ SAFETY WARNINGS

### Battery Safety
- **NEVER** solder directly to battery tabs (heat damages battery)
- **ALWAYS** use a battery with protection circuit
- **NEVER** puncture battery
- **NEVER** leave battery charging unattended
- **NEVER** use damaged battery

### Soldering Safety
- Work in ventilated area
- Wash hands after handling lead solder
- Don't touch iron tip (gets to 400°C)
- Keep solder away from children

### Electrical Safety
- Disconnect power when making changes
- Check for shorts before powering
- Use correct voltage (3.3V, NOT 5V for sensors)

---

## 🔧 TROUBLESHOOTING

### I2C Device Not Found
1. Check all 4 connections (VCC, GND, SDA, SCL)
2. Verify 3.3V on VCC (multimeter)
3. Try different I2C address
4. Check for solder bridges

### ESP32 Not Uploading
1. Hold BOOT button while connecting USB
2. Select correct COM port
3. Update USB drivers (CH340/CP2102)
4. Try different USB cable

### Battery Not Charging
1. Check battery polarity (+ to B+, - to B-)
2. Measure battery voltage (>3.0V)
3. Try different USB cable
4. Check USB power (use phone charger)

### Random Crashes
1. Check all GND connections
2. Add 100nF capacitor near ESP32
3. Check for voltage drops under load
4. Reduce wire lengths

---

## 📏 MECHANICAL DIMENSIONS

### ESP32-WROOM-32 DevKit
- Length: 52mm
- Width: 28mm  
- Height: 10mm (without headers)
- Pin spacing: 2.54mm (0.1")

### MAX30102 Module
- Length: 20mm
- Width: 14mm
- Height: 4mm

### OLED 0.96"
- Length: 27mm
- Width: 27mm
- Height: 4mm

### LiPo 502030 Battery
- Length: 30mm
- Width: 20mm
- Height: 5mm

### Suggested Case Internal Dimensions
- Length: 45mm minimum
- Width: 40mm minimum
- Height: 15mm minimum

---

## 📞 Component Placement Guide

### Top View (Inside Watch)
```
    ┌────────────────────────┐
    │                        │
    │    ┌────────────────┐  │
    │    │    OLED 0.96"  │  │
    │    │   (Top Layer)  │  │
    │    └────────────────┘  │
    │                        │
    │  ┌────┐      ┌────┐    │
    │  │LED │      │LED │    │
    │  │ R  │      │ G  │    │
    │  └────┘      └────┘    │
    │                        │
    │    ┌────────────────┐   │
    │    │     ESP32     │   │
    │    │  DevKit v4    │   │
    │    └────────────────┘   │
    │                        │
    │  ┌──────┐  ┌──────┐    │
    │  │BATT. │  │MAX30 │    │
    │  │502030│  │102   │    │
    │  └──────┘  └──────┘    │
    │                        │
    │  ┌──────┐  ┌──────┐    │
    │  │MPU6050│ │TP4056│    │
    │  └──────┘  └──────┘    │
    │                        │
    └────────────────────────┘
```

---

**Document Version:** 1.0  
**Last Updated:** June 2024
