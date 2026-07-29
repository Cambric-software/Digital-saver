# DIGITAL SAVER ONYX WATCH - COMPLETE TECHNICAL DOCUMENTATION

> **Document Version:** 3.0.3  
> **Last Updated:** July 2026  
> **Watch Model:** Onyx (Digital Saver Smartwatch)  
> **Company:** Cambric  
> **Copyright:** © 2026 Cambric. All Rights Reserved.

---

# ═══════════════════════════════════════════
# 📖 TABLE OF CONTENTS
# ═══════════════════════════════════════════

## PART 1: HARDWARE DOCUMENTATION
1. [Hardware Overview](#1-hardware-overview)
2. [ESP32 Microcontroller](#2-esp32-microcontroller)
3. [MAX30102 Heart Rate Sensor](#3-max30102-heart-rate-sensor)
4. [MPU6050 Accelerometer](#4-mpu6050-accelerometer)
5. [SSD1306 OLED Display](#5-ssd1306-oled-display)
6. [Pin Configuration](#6-pin-configuration)
7. [Power System](#7-power-system)
8. [Buttons and Controls](#8-buttons-and-controls)
9. [I2C Communication Explained](#9-i2c-communication-explained)
10. [Wiring Diagram](#10-wiring-diagram)

## PART 2: SOFTWARE DOCUMENTATION
11. [Firmware Overview](#11-firmware-overview)
12. [BLE Communication Protocol](#12-ble-communication-protocol)
13. [Display & Themes](#13-display--themes)
14. [Watch Modes](#14-watch-modes)
15. [BLE Commands Reference](#15-ble-commands-reference)
16. [Data Format](#16-data-format)
17. [Watch Code Structure](#17-watch-code-structure)

## PART 3: BUILDING & PROGRAMMING
18. [Required Tools](#18-required-tools)
19. [Install PlatformIO](#19-install-platformio)
20. [Build Firmware](#20-build-firmware)
21. [Flash to Watch](#21-flash-to-watch)
22. [Serial Monitor](#22-serial-monitor)

## PART 4: TROUBLESHOOTING
23. [Common Problems](#23-common-problems)
24. [Hardware Debugging](#24-hardware-debugging)
25. [Software Debugging](#25-software-debugging)
26. [Recovery](#26-recovery)

---

# ═══════════════════════════════════════════
# PART 1: HARDWARE DOCUMENTATION
# ═══════════════════════════════════════════

---

# 1. HARDWARE OVERVIEW

## 1.1 What Is The Onyx Watch?

The **Digital Saver Onyx** is a smartwatch that monitors your health. It has sensors to measure:
- Heart rate (like a fitness band)
- Blood oxygen (SpO2)
- Movement and steps
- Falls

## 1.2 Main Components

Here is a list of EVERYTHING inside the watch:

| Component | Part Number | How Many | What It Does |
|-----------|-----------|----------|--------------|
| Microcontroller | ESP32-WROOM-32 | 1 | Brain of the watch - runs all code |
| Heart Rate Sensor | MAX30102 | 1 | Measures heart rate and blood oxygen |
| Accelerometer | MPU6050 | 1 | Detects movement, steps, falls |
| Display | SSD1306 OLED 0.96" | 1 | Shows time, heart rate, etc |
| Battery | LiPo 502035 500mAh | 1 | Powers the watch |
| Battery Charger | TP4056 | 1 | Charges the battery |
| Vibration Motor | 3V ERM | 1 | Makes the watch buzz |
| Red LED | 3mm | 1 | Shows status (red light) |
| Green LED | 3mm | 1 | Shows status (green light) |
| Buttons | 3x | 3 | Mode, Emergency, Back buttons |

## 1.3 System Diagram

This shows how everything connects:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ONYX SMARTWATCH - INSIDE                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ╔══════════════════════════════════════════════════════════════════╗  │
│  ║                      ESP32-WROOM-32                               ║  │
│  ║                   (The Brain / Main Chip)                         ║  │
│  ║  ┌────────────────────────────────────────────────────────────┐  ║  │
│  ║  │  • CPU: 240MHz Dual Core                                   │  ║  │
│  ║  │  • WiFi: 802.11 b/g/n                                      │  ║  │
│  ║  │  • Bluetooth: BLE 4.2                                       │  ║  │
│  ║  │  • Flash: 4MB                                              │  ║  │
│  ║  │  • RAM: 520KB                                              │  ║  │
│  ║  └────────────────────────────────────────────────────────────┘  ║  │
│  ╚══════════════════════════════════════════════════════════════════╝  │
│                                    │                                      │
│                    ┌───────────────┼───────────────┐                    │
│                    │               │               │                    │
│                    ▼               ▼               ▼                    │
│  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  │
│  │   MAX30102        │  │    MPU6050        │  │    SSD1306        │  │
│  │  Heart Sensor     │  │  Accelerometer    │  │  OLED Display     │  │
│  │                   │  │                   │  │                   │  │
│  │  • Heart Rate     │  │  • Steps          │  │  • 128x64 pixels │  │
│  │  • Blood Oxygen   │  │  • Fall Detect    │  │  • I2C Display   │  │
│  │  • I2C Address    │  │  • I2C Address     │  │  • I2C Address    │  │
│  │    0x57           │  │    0x68           │  │    0x3C           │  │
│  └───────────────────┘  └───────────────────┘  └───────────────────┘  │
│                                    │                                      │
│  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐  │
│  │   BUTTONS         │  │   LEDs + MOTOR    │  │   BATTERY        │  │
│  │                   │  │                   │  │                   │  │
│  │  • Mode Button    │  │  • Red LED        │  │  • 500mAh LiPo   │  │
│  │  • Emergency Btn  │  │  • Green LED      │  │  • USB-C Charge  │  │
│  │  • Back Button    │  │  • Vibration      │  │  • TP4056 Chip   │  │
│  └───────────────────┘  └───────────────────┘  └───────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

# 2. ESP32 MICROCONTROLLER

## 2.1 What Is ESP32?

The **ESP32** is the main chip that runs everything. Think of it like the brain of the watch.

## 2.2 ESP32 Specifications

| Property | Value |
|----------|-------|
| **CPU Speed** | 240MHz (2 cores) |
| **WiFi** | 802.11 b/g/n |
| **Bluetooth** | BLE 4.2 |
| **Flash Memory** | 4MB |
| **RAM** | 520KB |
| **GPIO Pins** | 34 pins |
| **Operating Voltage** | 3.3V |
| **Input Voltage** | 5V (via USB) |

## 2.3 ESP32 Pin Layout

This is what the ESP32 chip looks like (top view):

```
         ┌─────────────────────────────────────┐
    3V3 ─│  ●                                  │
    GND ─│                                     │
   GPIO36│                                     │
   GPIO39│         ESP32-WROOM-32              │
   GPIO34│                                     │
   GPIO35│       (Top View of Chip)            │
    GPIO4│                                     │
    GPIO0│                                     │
    GPIO2│                                     │
   GPIO15│                                     │
    GND ─│                                     │
   GPIO16│                                     │
   GPIO17│                                     │
    GPIO5│                                     │
   GPIO18│                                  ●──│─── (Top dot = Pin 1)
   GPIO19│                                     │
    GND ─│                                     │
   GPIO21│                                     │
   GPIO22│                                     │
   GPIO26│                                     │
   GPIO27│                                     │
   GPIO25│                                     │
   GPIO32│                                     │
   GPIO33│                                     │
   GPIO14│                                     │
   GPIO12│                                     │
   GPIO13│                                     │
    GND ─│                                     │
     EN ─│                                     │
   VIN ─│                                     │
         └─────────────────────────────────────┘

IMPORTANT PINS FOR OUR WATCH:
─────────────────────────────────────────────────
Pin 18 = I2C SCL (Clock)
Pin 19 = I2C SDA (Data)
Pin 25 = Vibration Motor
Pin 26 = Heart Rate Sensor Interrupt
Pin 27 = Motion Sensor Interrupt
Pin 4  = Red LED
Pin 16 = Green LED
Pin 17 = Mode Button
Pin 34 = Emergency Button
Pin 35 = Back Button
```

## 2.4 ESP32 Power Pins

| Pin | Name | What It Does |
|-----|------|--------------|
| 3V3 | 3.3V Power | Powers sensors (3.3V) |
| VIN | Voltage Input | 5V from USB |
| GND | Ground | Common ground for everything |

---

# 3. MAX30102 HEART RATE SENSOR

## 3.1 What Does It Do?

The **MAX30102** sensor sits on the back of the watch and touches your wrist. It:
- Shines light into your skin
- Measures how much light bounces back
- Calculates your heart rate from the pulse
- Measures blood oxygen (SpO2)

## 3.2 MAX30102 Specifications

| Property | Value |
|----------|-------|
| **I2C Address** | 0x57 (decimal 87) |
| **Operating Voltage** | 1.8V - 3.3V |
| **LED Voltage** | 3.3V |
| **Sample Rate** | 100Hz to 3200Hz (configurable) |
| **ADC Resolution** | 18 bits |
| **Red LED Wavelength** | 660nm |
| **Infrared LED Wavelength** | 880nm |

## 3.3 MAX30102 Pinout

```
        ┌───────────────────────┐
   VIN ─│ ●                   ● │ ── VLED+
    -  │                     │ ── VLED-
   GND ─│    MAX30102         │ ── SCL (I2C Clock)
   SDA ─│   (Top View)        │ ── INT (Interrupt)
   SCL ─│                     │
   INT ─│                     │
         └───────────────────────┘

Wiring for our watch:
  MAX30102 VIN  →  ESP32 3V3
  MAX30102 GND  →  ESP32 GND
  MAX30102 SDA  →  ESP32 GPIO18 (or GPIO21)
  MAX30102 SCL  →  ESP32 GPIO19 (or GPIO22)
  MAX30102 INT  →  ESP32 GPIO26
```

## 3.4 MAX30102 Important Registers

A **register** is a memory location inside the chip that you can read or write to control it.

| Register Name | Address | What It Does |
|---------------|---------|--------------|
| MODE_CONFIG | 0x09 | Sets the sensor mode (HR, SpO2, etc) |
| SPO2_CONFIG | 0x06 | Sets SpO2 measurement settings |
| LED_CONFIG | 0x09 | Sets LED brightness (current) |
| FIFO_WR_PTR | 0x04 | Points to next write location in memory |
| OVF_COUNTER | 0x05 | Counts how many times FIFO overflowed |
| FIFO_RD_PTR | 0x06 | Points to next read location in memory |
| FIFO_DATA | 0x07 | READ THIS to get sensor data |
| MODE_STATUS | 0x08 | Shows sensor status |
| INT_STATUS | 0x00 | Shows what interrupts are active |
| INT_ENABLE | 0x02 | Enables/disables interrupts |

## 3.5 How To Read Heart Rate (Code)

```cpp
// Step 1: Setup I2C
Wire.begin(18, 19);  // SDA=18, SCL=19

// Step 2: Configure sensor
Wire.beginTransmission(0x57);  // MAX30102 address
Wire.write(0x09);              // MODE_CONFIG register
Wire.write(0x03);              // Enable HR + SpO2 mode
Wire.endTransmission();

// Step 3: Read FIFO data (contains IR and Red values)
Wire.beginTransmission(0x57);
Wire.write(0x07);  // FIFO_DATA register
Wire.endTransmission(false);
Wire.requestFrom(0x57, 6);  // Request 6 bytes

int irValue = (Wire.read() << 8) | Wire.read();  // IR LED value
int redValue = (Wire.read() << 8) | Wire.read(); // Red LED value
```

---

# 4. MPU6050 ACCELEROMETER

## 4.1 What Does It Do?

The **MPU6050** measures:
- Which direction is "down" (like a level)
- How fast it's moving (acceleration)
- How it's rotating (gyroscope)
- Falls (when sudden movement detected)

## 4.2 MPU6050 Specifications

| Property | Value |
|----------|-------|
| **I2C Address** | 0x68 (decimal 104) |
| **Operating Voltage** | 3.3V |
| **Accelerometer Range** | ±2g, ±4g, ±8g, ±16g |
| **Gyroscope Range** | ±250, ±500, ±1000, ±2000 °/s |
| **ADC Resolution** | 16 bits |

## 4.3 MPU6050 Pinout

```
        ┌───────────────────────┐
    VCC ─│ ●                   ● │ ── AD0 (Address select)
   INT ─│                     │ ── FSYNC
   SCL ─│     MPU6050         │ ── SDA
   SDA ─│    (Top View)        │
    GND ─│                     │
         └───────────────────────┘

Wiring for our watch:
  MPU6050 VCC  →  ESP32 3V3
  MPU6050 GND  →  ESP32 GND
  MPU6050 SDA  →  ESP32 GPIO18 (or GPIO21)
  MPU6050 SCL  →  ESP32 GPIO19 (or GPIO22)
  MPU6050 INT  →  ESP32 GPIO27
  MPU6050 AD0  →  ESP32 GND (sets address to 0x68)
```

## 4.4 MPU6050 Important Registers

| Register Name | Address | What It Does |
|---------------|---------|--------------|
| PWR_MGMT_1 | 0x6B | Power management (turn on sensor) |
| ACCEL_XOUT_H | 0x3B | X acceleration (high byte) |
| ACCEL_XOUT_L | 0x3C | X acceleration (low byte) |
| ACCEL_YOUT_H | 0x3D | Y acceleration (high byte) |
| ACCEL_YOUT_L | 0x3E | Y acceleration (low byte) |
| ACCEL_ZOUT_H | 0x3F | Z acceleration (high byte) |
| ACCEL_ZOUT_L | 0x40 | Z acceleration (low byte) |
| TEMP_OUT_H | 0x41 | Temperature (high byte) |
| INT_STATUS | 0x3A | Shows what interrupts happened |

## 4.5 How To Read Acceleration (Code)

```cpp
// Step 1: Wake up the sensor
Wire.beginTransmission(0x68);  // MPU6050 address
Wire.write(0x6B);              // PWR_MGMT_1 register
Wire.write(0x00);              // Wake up (clear sleep bit)
Wire.endTransmission();

// Step 2: Read X, Y, Z acceleration
Wire.beginTransmission(0x68);
Wire.write(0x3B);  // Start reading from ACCEL_XOUT_H
Wire.endTransmission(false);
Wire.requestFrom(0x68, 6);  // Request 6 bytes (X, Y, Z)

int ax = (Wire.read() << 8) | Wire.read();  // X acceleration
int ay = (Wire.read() << 8) | Wire.read();  // Y acceleration
int az = (Wire.read() << 8) | Wire.read();  // Z acceleration

// Convert to "g" units (divide by 16384 for ±2g range)
float ax_g = ax / 16384.0;
float ay_g = ay / 16384.0;
float az_g = az / 16384.0;

// Calculate total acceleration magnitude
float total_accel = sqrt(ax_g*ax_g + ay_g*ay_g + az_g*az_g);
```

## 4.6 How Fall Detection Works

```cpp
// Fall is detected when acceleration suddenly changes
void checkForFall() {
    // Read current acceleration
    float ax, ay, az;
    readAcceleration(ax, ay, az);
    
    // Calculate magnitude
    float accel = sqrt(ax*ax + ay*ay + az*az);
    
    // Normal gravity is ~1g. A fall creates much higher acceleration.
    if (accel > FALL_THRESHOLD) {  // FALL_THRESHOLD = 2.5g
        // Fall detected!
        startEmergencyProtocol();
    }
}
```

---

# 5. SSD1306 OLED DISPLAY

## 5.1 What Does It Do?

The **SSD1306** is a small screen that shows:
- Time
- Heart rate
- Menu options
- Status icons

## 5.2 SSD1306 Specifications

| Property | Value |
|----------|-------|
| **Resolution** | 128 x 64 pixels |
| **I2C Address** | 0x3C (decimal 60) |
| **Operating Voltage** | 3.3V |
| **Max Current** | 25mA |
| **Colors** | Monochrome (white on black) |
| **Interface** | I2C or SPI |

## 5.3 SSD1306 Pinout

```
        ┌───────────────────────┐
    GND ─│ ●                   ● │ ── VCC (3.3V)
   SCL ─│                     │
   SDA ─│     SSD1306         │
     DC ─│    (Top View)       │
     CS ─│                     │
    RES ─│                     │
         └───────────────────────┘

Wiring for our watch (I2C mode):
  SSD1306 GND  →  ESP32 GND
  SSD1306 VCC  →  ESP32 3V3
  SSD1306 SDA  →  ESP32 GPIO18 (or GPIO21)
  SSD1306 SCL  →  ESP32 GPIO19 (or GPIO22)
```

## 5.4 SSD1306 Important Commands

| Command | Hex | What It Does |
|---------|-----|--------------|
| DISPLAY_OFF | 0xAE | Turn display off |
| DISPLAY_ON | 0xAF | Turn display on |
| SET_CONTRAST | 0x81 | Set screen brightness |
| ENTIRE_DISPLAY_ON | 0xA5 | All pixels on |
| ENTIRE_DISPLAY_OFF | 0xA4 | Normal display mode |
| SET_MEM_ADDR_MODE | 0x20 | Set memory addressing |
| SET_COL_ADDR | 0x21 | Set column address |
| SET_PAGE_ADDR | 0x22 | Set page address |
| SET_START_LINE | 0x40 | Set display start line |

## 5.5 How To Use The Display (Code)

```cpp
#include <Adafruit_SSD1306.h>

// Create display object
Adafruit_SSD1306 display(128, 64, &Wire, -1);  // -1 = no reset pin

void setup() {
    // Initialize display
    display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
    
    // Clear screen
    display.clearDisplay();
    
    // Set text size (1 = smallest, 8 = largest)
    display.setTextSize(2);
    
    // Set text color
    display.setTextColor(SSD1306_WHITE);
    
    // Set cursor position
    display.setCursor(10, 10);
    
    // Print text
    display.println("Hello!");
    
    // Send to screen
    display.display();
}

void loop() {
    // Show heart rate
    display.clearDisplay();
    display.setTextSize(3);
    display.setCursor(20, 20);
    display.println("72 BPM");
    display.display();
    delay(1000);
}
```

---

# 6. PIN CONFIGURATION

## 6.1 Complete Pin Assignment Table

This table shows EVERY pin we use on the ESP32:

| ESP32 Pin | Name | Connected To | Purpose |
|-----------|------|-------------|---------|
| GPIO18 | I2C_SCL | MAX30102, MPU6050, SSD1306 | I2C Clock |
| GPIO19 | I2C_SDA | MAX30102, MPU6050, SSD1306 | I2C Data |
| GPIO26 | HR_INT | MAX30102 INT | Heart sensor interrupt |
| GPIO27 | MOTION_INT | MPU6050 INT | Motion sensor interrupt |
| GPIO25 | VIB_MOTOR | Vibration Motor | Vibration alerts |
| GPIO4 | LED_RED | Red LED (+) | Status indicator |
| GPIO16 | LED_GREEN | Green LED (+) | Status indicator |
| GPIO17 | BUTTON_MODE | Mode Button | Cycle modes |
| GPIO34 | BUTTON_EMERGENCY | Emergency Button | Emergency alert |
| GPIO35 | BUTTON_BACK | Back Button | Go back |
| 3V3 | 3.3V | All sensors | Power (3.3V) |
| GND | Ground | All components | Common ground |

## 6.2 Pin Diagram

```
                    ESP32-WROOM-32
                   ╔════════════════════╗
    3V3 ───────────║ 1              38  ║─────────── (unused)
    GND ───────────║ 2              37  ║─────────── (unused)
   GPIO36──────────║ 3              35  ║─────────── GPIO35 (BACK BTN)
   GPIO39──────────║ 4              32  ║─────────── (unused)
   GPIO34──────────║ 5              33  ║─────────── (unused)
   GPIO35──────────║ 6              25  ║─────────── GPIO25 (VIB_MOTOR)
   GPIO4───────────║ 7              26  ║─────────── GPIO26 (HR_INT)
   GPIO0───────────║ 8              27  ║─────────── GPIO27 (MOTION_INT)
   GPIO2───────────║ 9              14  ║─────────── (unused)
   GPIO15──────────║ 10             12  ║─────────── (unused)
    GND ───────────║ 11             13  ║─────────── (unused)
   GPIO16──────────║ 12             15  ║─────────── (unused)
   GPIO17──────────║ 13             16  ║─────────── GPIO16 (LED_GREEN)
   GPIO5───────────║ 14             17  ║─────────── GPIO17 (MODE_BTN)
   GPIO19──────────║ 15    ESP32   18  ║─────────── GPIO18 (I2C_SDA)
   GND ────────────║ 19             21  ║─────────── (unused)
                   ╚════════════════════╝
```

---

# 7. POWER SYSTEM

## 7.1 Power Flow Diagram

```
                    ┌─────────────────┐
                    │    USB Cable    │
                    │    (5V Input)   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   TP4056        │
                    │  Battery        │
                    │  Charger        │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌─────────┐    ┌─────────┐    ┌─────────┐
        │ Battery │    │  3.3V   │    │  3.3V   │
        │ (500mAh)│    │ Regulator│    │  LDO    │
        └─────────┘    └─────────┘    └─────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌─────────┐  ┌────────────┐  ┌─────────┐
        │ESP32    │  │  Sensors   │  │  LEDs   │
        │         │  │ MAX30102   │  │  Motor  │
        │         │  │ MPU6050    │  │         │
        │         │  │ SSD1306    │  │         │
        └─────────┘  └────────────┘  └─────────┘
```

## 7.2 Battery Specifications

| Property | Value |
|----------|-------|
| **Type** | Lithium Polymer (LiPo) |
| **Capacity** | 500mAh |
| **Voltage** | 3.7V (nominal) |
| **Size** | 50mm x 20mm x 3.5mm |
| **Charge Current** | 500mA |
| **Charge Time** | ~2 hours |

## 7.3 Power Consumption

| Mode | Current | How Long |
|------|---------|----------|
| Active (measuring) | 120mA | ~4 hours |
| Idle (BLE connected) | 30mA | ~16 hours |
| Sleep (display off) | 10μA | ~50,000 hours |
| Battery Life (typical) | - | 2-3 days |

---

# 8. BUTTONS AND CONTROLS

## 8.1 Button Locations

```
┌─────────────────────────────────────────┐
│                                         │
│              WATCH FACE                 │
│           (SSD1306 Display)             │
│                                         │
│    ┌─────────────────────────────┐     │
│    │         12:45              │     │
│    │      MON, JAN 15           │     │
│    └─────────────────────────────┘     │
│                                         │
│  ┌─────┐                    ┌─────┐    │
│  │MODE │                    │ ⚠️  │    │
│  │BTN  │                    │EMERG│    │
│  └─────┘                    └─────┘    │
│                                         │
│              ┌─────┐                   │
│              │BACK │                   │
│              │BTN  │                   │
│              └─────┘                   │
│                                         │
└─────────────────────────────────────────┘
```

## 8.2 Button Functions

| Button | Label | Single Press | Long Press (3 sec) |
|--------|-------|--------------|---------------------|
| **MODE** | MODE | Cycle to next mode | Toggle sleep mode |
| **EMERGENCY** | ⚠️ | (nothing - safety) | Trigger emergency alert |
| **BACK** | ← | Go to previous mode | Reset watch |

## 8.3 Button Wiring

| ESP32 Pin | Button | Connected To |
|-----------|--------|-------------|
| GPIO17 | MODE | 3.3V (via button) → GND |
| GPIO34 | EMERGENCY | 3.3V (via button) → GND |
| GPIO35 | BACK | 3.3V (via button) → GND |

---

# 9. I2C COMMUNICATION EXPLAINED

## 9.1 What Is I2C?

**I2C** is a way for chips to talk to each other using just 2 wires:
- **SCL** = Clock (controls timing)
- **SDA** = Data (the actual information)

## 9.2 I2C Wiring

```
┌─────────────┐                    ┌─────────────┐
│   ESP32     │                    │   Sensor    │
│             │                    │  (any chip) │
│   GPIO18 ──┼──── SCL ──────────▶│ ─── SCL     │
│             │                    │             │
│   GPIO19 ──┼──── SDA ◀─────────▶│ ─── SDA     │
│             │                    │             │
│   3.3V  ───┼──── VCC ──────────▶│ ─── VCC     │
│             │                    │             │
│   GND   ───┼──── GND ──────────▶│ ─── GND     │
└─────────────┘                    └─────────────┘
```

## 9.3 I2C Addresses Of All Devices

Each device has a unique address on the I2C bus:

| Device | I2C Address | Binary | Notes |
|--------|-------------|--------|-------|
| **MAX30102** | 0x57 | 0101 0111 | Heart rate sensor |
| **MPU6050** | 0x68 | 0110 1000 | Accelerometer |
| **SSD1306** | 0x3C | 0011 1100 | OLED display |

## 9.4 How I2C Communication Works

**Step 1:** Master (ESP32) pulls SDA low while SCL is high = "START condition"

**Step 2:** Master sends the device address (7 bits) + R/W bit (1 bit)
```
Example: Send "0x57" to MAX30102 (to read)
         01010111 + 1 = 0xAF
```

**Step 3:** Device sends "ACK" (acknowledgment) by pulling SDA low

**Step 4:** Master sends register address to read from
```
Example: Send 0x07 to read FIFO data
```

**Step 5:** Master reads data bytes (device pulls SDA for each bit)

**Step 6:** Master sends "STOP condition" (SCL high, then SDA high)

## 9.5 I2C Code Example

```cpp
// READ from MAX30102 register
uint8_t readMAX30102Register(uint8_t reg) {
    Wire.beginTransmission(0x57);  // Device address
    Wire.write(reg);                // Register to read
    Wire.endTransmission(false);     // Don't release bus
    
    Wire.requestFrom(0x57, 1);     // Request 1 byte
    
    if (Wire.available()) {
        return Wire.read();         // Return the byte
    }
    return 0;
}

// WRITE to MAX30102 register
void writeMAX30102Register(uint8_t reg, uint8_t value) {
    Wire.beginTransmission(0x57);   // Device address
    Wire.write(reg);                // Register to write
    Wire.write(value);              // Value to write
    Wire.endTransmission();         // Send and release bus
}
```

---

# 10. WIRING DIAGRAM

## 10.1 Complete Wiring Table

| Component | ESP32 Pin | Wire Color (Suggested) |
|-----------|-----------|----------------------|
| **I2C Bus (shared)** | | |
| I2C SCL | GPIO18 | Yellow |
| I2C SDA | GPIO19 | Blue |
| **MAX30102** | | |
| VIN | 3V3 | Red |
| GND | GND | Black |
| SCL | GPIO18 | Yellow (shared) |
| SDA | GPIO19 | Blue (shared) |
| INT | GPIO26 | Purple |
| **MPU6050** | | |
| VCC | 3V3 | Red |
| GND | GND | Black |
| SCL | GPIO18 | Yellow (shared) |
| SDA | GPIO19 | Blue (shared) |
| INT | GPIO27 | Green |
| AD0 | GND | Black (sets address 0x68) |
| **SSD1306 Display** | | |
| VCC | 3V3 | Red |
| GND | GND | Black |
| SCL | GPIO18 | Yellow (shared) |
| SDA | GPIO19 | Blue (shared) |
| **Buttons** | | |
| MODE Button | GPIO17 | White |
| EMERGENCY Button | GPIO34 | Orange |
| BACK Button | GPIO35 | Gray |
| **LEDs & Motor** | | |
| Red LED (+) | GPIO4 | Red |
| Green LED (+) | GPIO16 | Green |
| Vibration Motor (+) | GPIO25 | Brown |
| All GND for LEDs/Motor | GND | Black |

## 10.2 I2C Bus Pull-Up Resistors

Each I2C line needs a pull-up resistor (4.7KΩ to 10KΩ):

```
3.3V ──[4.7KΩ]───┬──── SCL ──── ESP32 GPIO18
                  │
                  └── Sensor SCL pins

3.3V ──[4.7KΩ]───┬──── SDA ──── ESP32 GPIO19
                  │
                  └── Sensor SDA pins
```

---

# ═══════════════════════════════════════════
# PART 2: SOFTWARE DOCUMENTATION
# ═══════════════════════════════════════════

---

# 11. FIRMWARE OVERVIEW

## 11.1 What Is Firmware?

**Firmware** is the code that runs on the ESP32. It's like the "operating system" of the watch.

## 11.2 Firmware Features

| Feature | Description |
|---------|-------------|
| **Heart Rate Monitor** | Measures BPM using PPG sensor |
| **SpO2 Monitor** | Measures blood oxygen percentage |
| **Blood Pressure** | Estimates BP from PPG waveform |
| **Step Counter** | Counts steps using accelerometer |
| **Fall Detection** | Detects falls and triggers alerts |
| **Sleep Tracking** | Monitors sleep quality |
| **5 Display Themes** | Customizable watch appearance |
| **BLE Communication** | Sends data to phone app |
| **Emergency Alerts** | Falls trigger emergency protocol |

## 11.3 Firmware File Structure

```
firmware/esp32/DigitalSaverWatch/
├── DigitalSaverWatch.ino          ← MAIN CODE (this is the only file)
├── platformio.ini                 ← Build settings
└── (other files if needed)
```

## 11.4 Code Sections

The main firmware file (DigitalSaverWatch.ino) has these sections:

| Section | Line Numbers | Purpose |
|---------|--------------|---------|
| Header/Comments | 1-22 | Documentation |
| Includes | 23-31 | Library imports |
| Configuration | 33-75 | #define settings |
| Global Objects | 76-95 | Display, sensors, BLE |
| Data Structures | 97-126 | HealthData, SensorData structs |
| State Variables | 130-170 | Current mode, theme, etc. |
| Setup Function | 200-330 | Initialize everything |
| Loop Function | 330-450 | Main processing |
| BLE Functions | 370-550 | BLE setup and callbacks |
| Sensor Functions | 550-750 | Read sensors |
| Display Functions | 750-1100 | Draw to screen |
| Utility Functions | 1100-1300 | Helpers |

---

# 12. BLE COMMUNICATION PROTOCOL

## 12.1 What Is BLE?

**BLE (Bluetooth Low Energy)** is a wireless technology that uses very little power. It's how the watch talks to the phone app.

## 12.2 BLE Service & Characteristics

| Item | UUID | What It Is |
|------|------|------------|
| **Service** | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` | Main BLE service |
| **Data Characteristic** | `beb5483e-36e1-4688-b7f5-ea07361b26a8` | Watch sends health data here |
| **Command Characteristic** | `beb5483e-36e1-4688-b7f5-ea07361b26f0` | Phone sends commands here |

## 12.3 BLE Connection Settings

| Setting | Value | Why |
|---------|-------|-----|
| Device Name | "Digital Saver" | Shows in phone's Bluetooth list |
| Connection Interval | 100ms | How often they talk |
| Slave Latency | 0 | No delay allowed |
| Supervision Timeout | 4000ms | Drop connection after 4 seconds |
| MTU Size | 512 bytes | Max data per packet |

## 12.4 BLE Flow Diagram

```
┌─────────────┐                              ┌─────────────┐
│   WATCH     │                              │   PHONE     │
│   (ESP32)   │                              │   (App)     │
│             │                              │             │
│             │  ┌──────────────────────┐   │             │
│  [Sensor]──▶│──│ Data Characteristic │◀──│──[Health    │
│             │  │  (Notify)            │   │    Screen]  │
│             │  └──────────────────────┘   │             │
│             │                              │             │
│             │  ┌──────────────────────┐   │             │
│  [Display]◀│──│ Command Characteristic│──│──[Settings] │
│             │  │  (Write)            │   │             │
│             │  └──────────────────────┘   │             │
└─────────────┘                              └─────────────┘
```

---

# 13. DISPLAY & THEMES

## 13.1 Watch Themes (v3.0.3+)

The watch supports **5 different themes** that change how the display looks:

| Theme ID | Name | Text Color | Background | Best For |
|----------|------|------------|------------|----------|
| **0** | Default | White | Black | Normal use |
| **1** | Inverted | Black | White | Outdoor/bright |
| **2** | High Contrast | Bold White | Black | Easy reading |
| **3** | Night Mode | Red | Black | Dark rooms |
| **4** | Minimal | White | Black | Stealth mode |

## 13.2 Theme Color Codes

The SSD1306 display supports these colors:

| Color | Hex Value | What It Is |
|-------|-----------|------------|
| SSD1306_WHITE | 0x01 | White pixel (lit) |
| SSD1306_BLACK | 0x00 | Black pixel (off) |
| SSD1306_INVERSE | - | Inverts current pixel |

## 13.3 Theme Switching Code

```cpp
// Theme enum definition
enum WatchTheme {
    THEME_DEFAULT = 0,      // White on black
    THEME_INVERTED = 1,    // Black on white
    THEME_HIGH_CONTRAST = 2, // Bold white
    THEME_NIGHT = 3,        // Red on black
    THEME_MINIMAL = 4       // Binary dots
};

// Current theme
WatchTheme currentTheme = THEME_DEFAULT;

// Get color based on theme
uint16_t getThemeColor(bool isBackground) {
    switch (currentTheme) {
        case THEME_DEFAULT:
            return isBackground ? SSD1306_BLACK : SSD1306_WHITE;
        case THEME_INVERTED:
            return isBackground ? SSD1306_WHITE : SSD1306_BLACK;
        case THEME_HIGH_CONTRAST:
            return SSD1306_WHITE;
        case THEME_NIGHT:
            return isBackground ? SSD1306_BLACK : SSD1306_RED;
        case THEME_MINIMAL:
            return SSD1306_WHITE;
    }
}
```

---

# 14. WATCH MODES

## 14.1 All Watch Modes

The watch has 6 different modes you can switch between:

| Mode ID | Mode Name | What It Shows | What It Does |
|---------|-----------|---------------|--------------|
| **0** | MODE_CLOCK | Time, date, battery | Default display |
| **1** | MODE_HEART_RATE | HR, SpO2, HRV | Heart monitoring |
| **2** | MODE_BLOOD_PRESSURE | Systolic, diastolic | BP tracking |
| **3** | MODE_ACTIVITY | Steps, calories | Activity tracking |
| **4** | MODE_SLEEP | Sleep score | Sleep monitoring |
| **5** | MODE_SETTINGS | Settings options | Configuration |

## 14.2 Mode Navigation

**Using Buttons:**
- Press **MODE** button → Cycle to next mode
- Press **BACK** button → Go to previous mode

**Using BLE (from phone):**
```
Command: MODE:1
Response: Watch switches to Heart Rate mode
```

## 14.3 Clock Mode Display

```
┌────────────────────────────────┐
│  ●                         ▮   │  ← BLE status, Battery
│                                │
│          ┌──────────┐          │
│          │  12:45   │          │  ← Time (large)
│          └──────────┘          │
│                                │
│       Mon, January 15          │  ← Date
│                                │
└────────────────────────────────┘
```

## 14.4 Heart Rate Mode Display

```
┌────────────────────────────────┐
│  HR                        BPM │
│                                │
│          ┌──────────┐          │
│          │   72     │          │  ← Heart Rate
│          └──────────┘          │
│                                │
│  SpO2:  98%                   │
│  HRV:   45ms                  │
│                                │
└────────────────────────────────┘
```

---

# 15. BLE COMMANDS REFERENCE

## 15.1 Command Overview

You can send these commands from the phone app to the watch:

| Command | Example | What It Does |
|---------|---------|--------------|
| THEME:X | THEME:3 | Change to theme X |
| MODE:X | MODE:1 | Switch to mode X |
| PING | PING | Test connection |
| STATUS | STATUS | Get current status |

## 15.2 Set Theme Command

**Send this to change the watch display theme:**

```
┌─────────────────────────────────────────┐
│ Command: THEME:<0-4>                     │
│                                          │
│ Example: THEME:3                        │
│                                          │
│ Response: Watch vibrates 50ms           │
│          Serial: [THEME] Set to theme 3 │
└─────────────────────────────────────────┘
```

**Theme IDs:**
- 0 = Default (white on black)
- 1 = Inverted (black on white)
- 2 = High Contrast
- 3 = Night Mode (red)
- 4 = Minimal

## 15.3 Set Mode Command

**Send this to change the watch mode:**

```
┌─────────────────────────────────────────┐
│ Command: MODE:<0-5>                     │
│                                          │
│ Example: MODE:2                         │
│                                          │
│ Response: Watch switches to Blood       │
│          Pressure mode                   │
└─────────────────────────────────────────┘
```

**Mode IDs:**
- 0 = Clock
- 1 = Heart Rate
- 2 = Blood Pressure
- 3 = Activity
- 4 = Sleep
- 5 = Settings

## 15.4 Ping Command

**Test if watch is connected:**

```
┌─────────────────────────────────────────┐
│ Command: PING                           │
│                                          │
│ Example: Send "PING"                   │
│                                          │
│ Response: PONG                          │
│                                          │
│ Use this to verify connection!          │
└─────────────────────────────────────────┘
```

## 15.5 Status Command

**Get current watch status:**

```
┌─────────────────────────────────────────┐
│ Command: STATUS                         │
│                                          │
│ Example: Send "STATUS"                  │
│                                          │
│ Response: THEME:0,MODE:0,BATT:85       │
│                                          │
│ Fields:                                  │
│   THEME: Current theme (0-4)           │
│   MODE: Current mode (0-5)              │
│   BATT: Battery level (0-100)           │
└─────────────────────────────────────────┘
```

## 15.6 Command Handler Code

```cpp
class BLECommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        std::string rxData = pCharacteristic->getValue();
        
        // THEME command
        if (rxData.substr(0, 6) == "THEME:") {
            int themeId = atoi(rxData.substr(6).c_str());
            switch (themeId) {
                case 0: currentTheme = THEME_DEFAULT; break;
                case 1: currentTheme = THEME_INVERTED; break;
                case 2: currentTheme = THEME_HIGH_CONTRAST; break;
                case 3: currentTheme = THEME_NIGHT; break;
                case 4: currentTheme = THEME_MINIMAL; break;
            }
            vibrate(50);  // Confirm
        }
        
        // MODE command
        else if (rxData.substr(0, 5) == "MODE:") {
            int modeId = atoi(rxData.substr(5).c_str());
            switch (modeId) {
                case 0: currentMode = MODE_CLOCK; break;
                case 1: currentMode = MODE_HEART_RATE; break;
                case 2: currentMode = MODE_BLOOD_PRESSURE; break;
                case 3: currentMode = MODE_ACTIVITY; break;
                case 4: currentMode = MODE_SLEEP; break;
                case 5: currentMode = MODE_SETTINGS; break;
            }
        }
        
        // PING command
        else if (rxData == "PING") {
            pCommandCharacteristic->setValue("PONG");
            pCommandCharacteristic->notify();
        }
        
        // STATUS command
        else if (rxData == "STATUS") {
            char status[64];
            snprintf(status, sizeof(status), 
                "THEME:%d,MODE:%d,BATT:%d", 
                currentTheme, currentMode, getBatteryLevel());
            pCommandCharacteristic->setValue(status);
            pCommandCharacteristic->notify();
        }
    }
};
```

---

# 16. DATA FORMAT

## 16.1 Health Data Sent To Phone

The watch sends health data to the phone app via the Data Characteristic (notify).

**Format:** JSON string

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

## 16.2 Data Fields Explained

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| hr | integer | BPM | Heart rate (beats per minute) |
| spo2 | integer | % | Blood oxygen saturation |
| bps | float | mmHg | Systolic blood pressure |
| bpd | float | mmHg | Diastolic blood pressure |
| hrv | float | ms | Heart rate variability |
| steps | integer | count | Total step count |
| cal | float | kcal | Calories burned |
| temp | float | °C | Body temperature |
| irreg | boolean | - | Irregular heartbeat detected |
| fall | boolean | - | Fall detected |
| ax | float | g | Accelerometer X |
| ay | float | g | Accelerometer Y |
| az | float | g | Accelerometer Z |

## 16.3 Code To Send Data

```cpp
void sendBLEData() {
    if (!deviceConnected) return;
    
    char buffer[256];
    
    // Create JSON string with all health data
    snprintf(buffer, sizeof(buffer),
        "{\"hr\":%.0f,\"spo2\":%.0f,\"bps\":%.0f,\"bpd\":%.0f,"
        "\"hrv\":%.2f,\"steps\":%lu,\"cal\":%.1f,\"temp\":%.1f,"
        "\"irreg\":%d,\"fall\":%d,\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f}",
        currentHealth.heartRate,
        currentHealth.spO2,
        currentHealth.bloodPressureSys,
        currentHealth.bloodPressureDia,
        currentHealth.hrvRMSSD,
        currentHealth.steps,
        currentHealth.calories,
        currentHealth.temperature,
        currentHealth.irregularHeartbeat,
        currentHealth.fallDetected,
        rawData.accelX,
        rawData.accelY,
        rawData.accelZ
    );
    
    // Send via BLE
    pCharacteristic->setValue(buffer);
    pCharacteristic->notify();
}
```

---

# 17. WATCH CODE STRUCTURE

## 17.1 Main Sections Of DigitalSaverWatch.ino

```cpp
/***************************************************************************
 * SECTION 1: HEADER
 * Lines 1-22
 * Documentation and version info
 ***************************************************************************/

/***************************************************************************
 * SECTION 2: INCLUDES  
 * Lines 23-31
 * Import all libraries
 ***************************************************************************/
#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <SparkFunMAX3010x.h>

/***************************************************************************
 * SECTION 3: CONFIGURATION
 * Lines 33-75
 * All #define settings
 ***************************************************************************/
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26f0"
// ... more defines

/***************************************************************************
 * SECTION 4: GLOBAL OBJECTS
 * Lines 76-95
 * Create instances of sensors and display
 ***************************************************************************/
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
MAX30105 particleSensor;
BLEServer* pServer = NULL;

/***************************************************************************
 * SECTION 5: DATA STRUCTURES
 * Lines 97-126
 * Define HealthData and RawSensorData
 ***************************************************************************/
struct HealthData {
    float heartRate;
    float spO2;
    float bloodPressureSys;
    float bloodPressureDia;
    // ... more fields
};

enum WatchMode { MODE_CLOCK, MODE_HEART_RATE, MODE_BLOOD_PRESSURE, ... };
enum WatchTheme { THEME_DEFAULT, THEME_INVERTED, THEME_HIGH_CONTRAST, ... };

/***************************************************************************
 * SECTION 6: STATE VARIABLES
 * Lines 130-170
 * Current state of the watch
 ***************************************************************************/
WatchMode currentMode = MODE_CLOCK;
WatchTheme currentTheme = THEME_DEFAULT;
HealthData currentHealth;
bool deviceConnected = false;

/***************************************************************************
 * SECTION 7: SETUP FUNCTION
 * Lines 200-330
 * Initialize everything once at startup
 ***************************************************************************/
void setup() {
    Serial.begin(115200);
    Wire.begin(18, 19);  // I2C pins
    
    initDisplay();        // Start OLED
    initSensors();        // Start MAX30102 and MPU6050
    initBLE();           // Start Bluetooth
}

/***************************************************************************
 * SECTION 8: LOOP FUNCTION
 * Lines 330-450
 * Main code that runs forever
 ***************************************************************************/
void loop() {
    readSensors();       // Get data from sensors
    updateDisplay();     // Draw to screen
    sendBLEData();       // Send to phone
    checkButtons();      // Check button presses
    delay(100);          // Wait a bit
}

/***************************************************************************
 * SECTION 9: BLE FUNCTIONS
 * Lines 370-550
 * Bluetooth setup and callbacks
 ***************************************************************************/
void initBLE() { ... }
class BLEServerCallbacks { ... }
class BLECommandCallbacks { ... }

/***************************************************************************
 * SECTION 10: SENSOR FUNCTIONS
 * Lines 550-750
 * Read from MAX30102 and MPU6050
 ***************************************************************************/
void initSensors() { ... }
void readMAX30102() { ... }
void readMPU6050() { ... }
void calculateHeartRate() { ... }

/***************************************************************************
 * SECTION 11: DISPLAY FUNCTIONS
 * Lines 750-1100
 * Draw screens for each mode
 ***************************************************************************/
void updateDisplay() { ... }
void showClockDisplay() { ... }
void showHeartRateDisplay() { ... }
void showMinimalDisplay() { ... }

/***************************************************************************
 * SECTION 12: UTILITY FUNCTIONS
 * Lines 1100-1300
 * Helpers, format time, etc.
 ***************************************************************************/
String formatTime() { ... }
String formatDate() { ... }
void vibrate(int ms) { ... }
```

---

# ═══════════════════════════════════════════
# PART 3: BUILDING & PROGRAMMING
# ═══════════════════════════════════════════

---

# 18. REQUIRED TOOLS

## 18.1 Software You Need

| Tool | Why | Download |
|------|-----|----------|
| **Visual Studio Code** | Code editor | code.visualstudio.com |
| **PlatformIO Extension** | Build & flash ESP32 | vscode marketplace |
| **USB Driver** | Connect ESP32 | silabs.com/developers/usb-to-uart-bridge-vcp-drivers |

## 18.2 Hardware You Need

| Item | Why |
|------|-----|
| **ESP32 Development Board** | To program the watch |
| **USB Cable** | Connect ESP32 to computer |
| **Computer** | Windows, Mac, or Linux |

---

# 19. INSTALL PLATFORMIO

## 19.1 Step By Step Installation

**Step 1:** Download and install Visual Studio Code

Go to: https://code.visualstudio.com/
Click the big Download button for your OS.

**Step 2:** Open VS Code

Double-click the VS Code icon.

**Step 3:** Install PlatformIO extension

1. Click the Extensions icon (left side, looks like 4 squares)
2. Search for "PlatformIO IDE"
3. Click "Install"
4. Wait for installation to complete
5. Click "Reload" when asked

**Step 4:** Verify installation

1. Press Ctrl+Shift+P (or Cmd+Shift+P on Mac)
2. Type "PlatformIO"
3. You should see "PlatformIO: Home" option

---

# 20. BUILD FIRMWARE

## 20.1 Open The Project

**Step 1:** Open PlatformIO Home

1. Press Ctrl+Shift+P
2. Type "PlatformIO: Home"
3. Press Enter

**Step 2:** Open the watch firmware

1. Click "Open Project"
2. Navigate to: `firmware/esp32/DigitalSaverWatch`
3. Click "Open"

## 20.2 Build The Code

**Method 1: Using Menu**

1. Click the PlatformIO icon (ant head) on the left
2. Click "Build" (checkmark icon)

**Method 2: Using Keyboard**

1. Press Ctrl+Alt+B (or Cmd+Alt+B on Mac)

**Method 3: Using Terminal**

1. Open terminal in the project folder
2. Type: `pio run`

## 20.3 Build Output

```
> pio run

Processing esp32dev (platform: espressif32)
Verbose mode can be enabled via `-v` CLI option
Compiling .pio/build/esp32dev/src/DigitalSaverWatch.ino.o
Linking .pio/build/esp32dev/firmware.elf
Building .pio/build/esp32dev/firmware.bin
Flash size: 4.00 MB
========================= [SUCCESS] Took 12.34 seconds =========================
```

---

# 21. FLASH TO WATCH

## 21.1 Connect ESP32

1. Connect ESP32 to computer using USB cable
2. Make sure you see a COM port (Windows) or /dev/ttyUSB* (Linux/Mac)

## 21.2 Flash The Firmware

**Method 1: Build + Flash at once**

```bash
pio run --target upload
```

**Method 2: Upload to specific port**

```bash
pio run --target upload --upload-port COM3
```

(Replace COM3 with your actual port)

**Linux/Mac example:**
```bash
pio run --target upload --upload-port /dev/ttyUSB0
```

## 21.3 Erase And Flash (Clean Install)

If you have problems, erase the flash first:

```bash
pio run --target erase
pio run --target upload
```

## 21.4 Flash Output

```
> pio run --target upload

Looking for upload port...
Auto-detected: /dev/ttyUSB0
Uploading .pio/build/esp32dev/firmware.bin @ 0x1000
...
Hard resetting via RTS pin...
========================= [SUCCESS] Took 8.45 seconds =========================
```

---

# 22. SERIAL MONITOR

## 22.1 Open Serial Monitor

**Method 1: Using Menu**

1. Click the PlatformIO icon
2. Click "Monitor" (screen icon)

**Method 2: Using Terminal**

```bash
pio device monitor
```

## 22.2 Serial Monitor Settings

| Setting | Value |
|---------|-------|
| Baud Rate | 115200 |
| Data Bits | 8 |
| Parity | None |
| Stop Bits | 1 |

## 22.3 What You Should See

When the watch starts up, you should see this in Serial Monitor:

```
[OK] Initializing sensors...
[OK] MAX30102 found
[OK] MPU6050 found
[OK] OLED initialized
[OK] BLE initialized - waiting for connection...
[BLE] Device connected
[CMD] Received: THEME:3
[THEME] Set to theme 3
```

---

# ═══════════════════════════════════════════
# PART 4: TROUBLESHOOTING
# ═══════════════════════════════════════════

---

# 23. COMMON PROBLEMS

## 23.1 Display Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| Display shows nothing | No power | Check 3.3V connection |
| Display shows nothing | I2C not working | Check SDA/SCL wiring |
| Display shows noise | Wrong I2C address | Use 0x3C for SSD1306 |
| Display flickers | Loose wires | Secure all connections |

## 23.2 Sensor Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| Heart rate shows "--" | Sensor not touching skin | Wear watch snugly |
| Heart rate always 0 | MAX30102 not found | Check I2C wiring |
| Steps not counting | MPU6050 not working | Check I2C wiring |
| Sensor reads wrong | Wrong register | Check register addresses |

## 23.3 BLE Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| Can't find device | BLE not advertising | Check initBLE() |
| Connects then disconnects | Signal weak | Move phone closer |
| Data not sending | Not connected | Wait for connection first |

## 23.4 Build Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| "Board not found" | Wrong platform | Install espressif32 |
| "Library not found" | Missing deps | pio lib install |
| "Compile error" | Code bug | Check error message |

---

# 24. HARDWARE DEBUGGING

## 24.1 Test I2C Devices

Run this code to find all I2C devices:

```cpp
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    Wire.begin(18, 19);  // Your I2C pins
    
    Serial.println("I2C Scanner starting...");
    
    for (byte address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        byte error = Wire.endTransmission();
        
        if (error == 0) {
            Serial.print("✓ Found device at 0x");
            Serial.println(address, HEX);
        }
        else if (error == 4) {
            Serial.print("✗ Unknown error at 0x");
            Serial.println(address, HEX);
        }
    }
    
    Serial.println("Scan complete!");
}

void loop() {}
```

**Expected output:**
```
I2C Scanner starting...
✓ Found device at 0x3C   ← SSD1306 Display
✓ Found device at 0x57   ← MAX30102 Heart Rate
✓ Found device at 0x68   ← MPU6050 Accelerometer
Scan complete!
```

## 24.2 Test Individual Sensors

**Test MAX30102:**
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

**Test MPU6050:**
```cpp
#include <Wire.h>

void setup() {
    Serial.begin(115200);
    Wire.begin(18, 19);
    
    Wire.beginTransmission(0x68);
    Wire.write(0x6B);  // PWR_MGMT_1
    Wire.write(0x00);   // Wake up
    byte result = Wire.endTransmission();
    
    if (result == 0) {
        Serial.println("MPU6050 OK");
    } else {
        Serial.println("MPU6050 FAILED");
    }
}
```

## 24.3 Test Display

```cpp
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);

void setup() {
    Serial.begin(115200);
    
    if (display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("SSD1306 OK");
        
        // Draw something
        display.clearDisplay();
        display.setTextSize(2);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(10, 20);
        display.println("HELLO!");
        display.display();
    } else {
        Serial.println("SSD1306 FAILED");
    }
}
```

---

# 25. SOFTWARE DEBUGGING

## 25.1 Enable Debug Output

Add this to print debug messages:

```cpp
#define DEBUG_MODE true

void debugPrint(const char* message) {
    #ifdef DEBUG_MODE
    Serial.println(message);
    #endif
}

void debugPrintValue(const char* label, int value) {
    #ifdef DEBUG_MODE
    Serial.print(label);
    Serial.println(value);
    #endif
}
```

## 25.2 Check BLE Connection

```cpp
void sendStatus() {
    if (deviceConnected) {
        Serial.println("[BLE] Connected - sending data");
        sendBLEData();
    } else {
        Serial.println("[BLE] Not connected");
    }
}
```

## 25.3 Common Error Messages

| Error | Meaning | Fix |
|-------|--------|-----|
| `Wire.endTransmission() returned 2` | NACK on address | Check wiring |
| `Wire.endTransmission() returned 3` | NACK on data | Sensor not responding |
| `Wire.endTransmission() returned 4` | Other error | Check I2C pins |
| `ESP32 chip sync error` | Boot mode wrong | Hold BOOT button |

---

# 26. RECOVERY

## 26.1 Factory Reset

1. Hold all 3 buttons for 10 seconds
2. LEDs will flash
3. Release buttons
4. Watch resets to defaults

## 26.2 Erase ESP32 Flash

If the ESP32 is bricked:

**Step 1:** Connect ESP32 via USB

**Step 2:** Erase flash

```bash
# Linux/Mac
esptool.py --chip esp32 erase_flash

# Windows (using esptool from PlatformIO)
pio run --target erase
```

**Step 3:** Flash new firmware

```bash
pio run --target upload
```

## 26.3 Boot Mode Flash

If you can't upload:

1. Hold the **BOOT** button on ESP32
2. While holding BOOT, press and release **RESET**
3. Release **BOOT**
4. Now upload should work

---

# ═══════════════════════════════════════════
# QUICK REFERENCE CARDS
# ═══════════════════════════════════════════

## I2C Addresses
```
MAX30102 = 0x57
MPU6050  = 0x68
SSD1306  = 0x3C
```

## Pin Connections
```
SCL = GPIO18
SDA = GPIO19
HR_INT = GPIO26
MOTION_INT = GPIO27
VIB_MOTOR = GPIO25
LED_RED = GPIO4
LED_GREEN = GPIO16
MODE_BTN = GPIO17
EMERG_BTN = GPIO34
BACK_BTN = GPIO35
```

## BLE Commands
```
THEME:0-4    Change theme
MODE:0-5     Change mode
PING         Test connection
STATUS       Get status
```

## Build Commands
```
pio run              Build
pio run --target upload    Flash
pio run --target erase     Erase
pio device monitor         Serial monitor
```

---

# ═══════════════════════════════════════════
# END OF DOCUMENT
# ═══════════════════════════════════════════

**Document Version:** 3.0.3  
**Last Updated:** July 2026  
**Company:** Cambric  
**Copyright:** © 2026 Cambric. All Rights Reserved.

If you have questions, check the troubleshooting section or contact the development team.
