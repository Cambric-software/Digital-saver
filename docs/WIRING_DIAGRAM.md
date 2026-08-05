# Onyx Watch Wiring Diagram

## Quick Reference Pinout

```
ESP32-WROOM-32 Pinout
═══════════════════════════════════════════════════════════════════════

         ╔═══════════════════════════════════════╗
    3V3 ║  1 ●                               ● 38 ║ GPIO37
    GND ║  2                                 37 ║ GPIO38
  GPIO36 ║  3                                 36 ║ GPIO35 ← Button Back
  GPIO39 ║  4                                 35 ║ GPIO34 ← Button SOS
  GPIO34 ║  5                                 34 ║ GPIO33 ← Battery ADC
  GPIO35 ║  6                                 33 ║ GPIO32 ← Charge Status
   GPIO4 ║  7                                 32 ║ GPIO25 ← MAX30102 INT
   GPIO0 ║  8                                 31 ║ GPIO26
   GPIO2 ║  9                                 30 ║ GPIO27 ← MPU6050 INT
  GPIO15 ║ 10                                 29 ║ GPIO14
    GND ║ 11                                 28 ║ GPIO12
  GPIO16 ║ 12                                 27 ║ GPIO13
  GPIO17 ║ 13                                 26 ║ GPIO15
   GPIO5 ║ 14                                 25 ║ GPIO16 ← Green LED
  GPIO18 ║ 15          ESP32                24 ║ GPIO17 ← Button Mode
  GPIO19 ║ 16          WROOM-32              23 ║
    GND ║ 17                                 22 ║ GPIO21 ← I2C SDA
         ╚═══════════════════════════════════════╝

Pins 18 (GPIO18) = I2C SCL
Pins 19 (GPIO19) = I2C SDA
```

## Complete Wiring Table

### I2C Bus (Shared)
| Component | I2C Address | SDA | SCL |
|-----------|-------------|-----|-----|
| MAX30102 | 0x57 | GPIO 21 | GPIO 22 |
| MPU6050 | 0x68 | GPIO 21 | GPIO 22 |
| SSD1306 Display | 0x3C | GPIO 21 | GPIO 22 |

### Power Rails
| Rail | Voltage | Connected To |
|------|---------|-------------|
| 3V3 | 3.3V | All sensors, Display |
| GND | 0V | All components |
| USB 5V | 5V | TP4056 OUT+ |

### Individual Connections

#### MAX30102 (Heart Rate + SpO2)
```
MAX30102 Pin    →    ESP32 Pin
────────────────────────────────
VIN             →    3V3 (Red)
GND             →    GND (Black)
SDA             →    GPIO 21 (White)
SCL             →    GPIO 22 (Yellow)
INT             →    GPIO 25 (Optional, Green)
```

#### MPU6050 (Accelerometer)
```
MPU6050 Pin    →    ESP32 Pin
────────────────────────────────
VCC             →    3V3 (Red)
GND             →    GND (Black)
SDA             →    GPIO 21 (White) ← Shared with MAX30102
SCL             →    GPIO 22 (Yellow) ← Shared with MAX30102
INT             →    GPIO 27 (Orange)
```

#### SSD1306 OLED Display
```
SSD1306 Pin     →    ESP32 Pin
────────────────────────────────
VCC             →    3V3 (Red)
GND             →    GND (Black)
SDA             →    GPIO 21 (White) ← Shared
SCL             →    GPIO 22 (Yellow) ← Shared
```

#### LEDs (with 220Ω Resistors)
```
Red LED:
  GPIO 4 ─── [220Ω] ─── [LED +] ─── [LED -] ─── GND

Green LED:
  GPIO 16 ─── [220Ω] ─── [LED +] ─── [LED -] ─── GND
```

#### Buttons (Input with Pull-down)
```
Mode Button (GPIO 17):
  3V3 ─── [Button] ─── GPIO 17
  [10K resistor to GND on GPIO 17]

SOS Button (GPIO 34):
  3V3 ─── [Button] ─── GPIO 34
  [10K resistor to GND on GPIO 34]

Back Button (GPIO 35):
  3V3 ─── [Button] ─── GPIO 35
  [10K resistor to GND on GPIO 35]
```

#### Battery & Charger (TP4056)
```
TP4056 Pin     →    Connection
────────────────────────────────
B+             →    Battery + (Red wire)
B-             →    Battery - (Black wire)
OUT+           →    USB 5V (for charging)
OUT-           →    GND

Battery:
  Battery +     →    [Protection Circuit]    →    ESP32 3V3
  Battery -     →    GND                      →    ESP32 GND
```

## Visual Wiring Diagram

```
                    ┌─────────────────────────────────────┐
                    │          ESP32-WROOM-32             │
                    │                                     │
    3V3 ────────────┼─────────────────────────────────────┼─────────► MAX30102 VIN
    GND ────────────┼─────────────────────────────────────┼─────────► MAX30102 GND
                     │                                     │
    GPIO 21 ─────────┼──┬──────────────────────────────────┼─────────► MAX30102 SDA
                     │  │                                  │          MPU6050 SDA
                     │  │                                  │          SSD1306 SDA
                     │  │                                  │
    GPIO 22 ─────────┼──┼──┬───────────────────────────────┼─────────► MAX30102 SCL
                     │  │  │                               │          MPU6050 SCL
                     │  │  │                               │          SSD1306 SCL
                     │  │  │                               │
    GPIO 25 ────────┼──┼──┼───────────────────────────────┼─────────► MAX30102 INT
                     │  │  │                               │
    GPIO 27 ────────┼──┼──┼───────────────────────────────┼─────────► MPU6050 INT
                     │  │  │                               │
    GPIO 4 ─────────┼──┼──┼───────────────────────────────┼──[220Ω]─┐
                     │  │  │                               │         │► RED LED
    GPIO 16 ───────┼──┼──┼───────────────────────────────┼──[220Ω]─┤
                     │  │  │                               │         │► GREEN LED
                     │  │  │                               │         │
    GPIO 17 ────────┼──┼──┼───────────────────────────────┼─────────► MODE BTN
                     │  │  │                               │
    GPIO 34 ────────┼──┼──┼───────────────────────────────┼─────────► SOS BTN
                     │  │  │                               │
    GPIO 35 ────────┼──┼──┼───────────────────────────────┼─────────► BACK BTN
                     │  │  │                               │
    GPIO 33 ────────┼──┼──┼───────────────────────────────┼─────────► Battery ADC
                     │  │  │                               │
    GPIO 32 ────────┼──┼──┼───────────────────────────────┼─────────► Charge Status
                     │  │  │                               │
    USB 5V ─────────┼──┼──┼───────────────────────────────┼─────────► TP4056 OUT+
                     │  │  │                               │
    GND ─────────────┼──┴──┴───────────────────────────────┼─────────► Everything GND
                     │                                     │
                    ┌┴─────────────────────────────────────┴┐
                    │              TP4056                   │
                    │          Battery Charger               │
                    │                                          │
                    │   B+ ──────► Battery +                   │
                    │   B- ──────► Battery -                   │
                    │   OUT+ ────► From USB 5V                │
                    │   OUT- ────► GND                         │
                    └──────────────────────────────────────────┘
```

## Color Coding (Recommended)

| Wire Color | Purpose |
|-----------|---------|
| Red | 3V3 Power |
| Black | GND |
| White | I2C SDA |
| Yellow | I2C SCL |
| Orange | Interrupt pins |
| Blue | Buttons |
| Green | LEDs |

## I2C Scanner Sketch

Upload this to find all I2C addresses:

```cpp
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22); // SDA, SCL
  
  Serial.println("\nI2C Scanner");
  
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("Found: 0x");
      Serial.println(address, HEX);
    }
  }
}

void loop() {}
```

**Expected Results:**
- 0x57 = MAX30102
- 0x68 = MPU6050
- 0x3C = SSD1306 Display

## Common Issues

| Issue | Check |
|-------|-------|
| Sensors not found | Check SDA/SCL connections |
| LEDs always on | Check resistor values (220Ω) |
| No battery charging | Check TP4056 connections |
| Buttons not working | Check pull-down resistors |
| Display garbled | Try I2C address 0x3D |

---

**Last Updated:** August 2026
