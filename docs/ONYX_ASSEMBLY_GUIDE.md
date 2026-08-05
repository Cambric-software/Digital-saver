# Digital Saver Onyx - Complete Assembly Guide

**Version:** 1.0  
**Target Build:** 3 Weeks  
**Difficulty:** Intermediate  
**Time to Build:** 4-6 hours  

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Tools Needed](#tools-needed)
3. [Parts Checklist](#parts-checklist)
4. [Step 1: Prepare the ESP32](#step-1-prepare-the-esp32)
5. [Step 2: Wire the MAX30102 Sensor](#step-2-wire-the-max30102-sensor)
6. [Step 3: Wire the MPU6050 Sensor](#step-3-wire-the-mpu6050-sensor)
7. [Step 4: Wire the SSD1306 Display](#step-4-wire-the-ssd1306-display)
8. [Step 5: Wire the Battery & Charger](#step-5-wire-the-battery--charger)
9. [Step 6: Wire the LEDs and Buttons](#step-6-wire-the-leds-and-buttons)
10. [Step 7: Assemble the Case](#step-7-assemble-the-case)
11. [Step 8: Upload Firmware](#step-8-upload-firmware)
12. [Step 9: Testing](#step-9-testing)
13. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting:
- [ ] Read the full [WATCH_FIRMWARE.md](WATCH_FIRMWARE.md)
- [ ] Verify all parts have arrived
- [ ] Install Arduino IDE or PlatformIO
- [ ] Install required libraries
- [ ] Set up your development environment

---

## Tools Needed

| Tool | Purpose |
|------|---------|
| Soldering Iron (60W) | Connect components |
| Solder Wire (0.8mm) | For soldering |
| Wire Cutters | Cut wires to size |
| Wire Strippers | Strip wire ends |
| Multimeter | Test connections |
| USB-C Cable | Power and upload |
| Helping Hands | Hold components while soldering |
| Flux | Improve solder joints |
| IPA (Isopropyl Alcohol) | Clean PCB |
| Magnifying Glass | Inspect solder joints |

---

## Parts Checklist

### Electronics
```
[ ] ESP32 Development Board (x1)
[ ] MAX30102 Heart Rate Sensor (x1)
[ ] MPU6050 Accelerometer (x1)
[ ] SSD1306 OLED Display 0.96" (x1)
[ ] TP4056 USB-C Battery Charger (x1)
[ ] 350mAh LiPo Battery (x1)
[ ] Red LED 3mm (x1)
[ ] Green LED 3mm (x1)
[ ] Resistor 220 Ohm (x2)
[ ] Resistor 10K Ohm (x3)
[ ] Jumper Wires (M/M x20)
[ ] Prototype PCB 5x7cm (x1)
```

### Case & Hardware
```
[ ] 3D Printed Case Top (x1)
[ ] 3D Printed Case Bottom (x1)
[ ] Silicone Watch Band 22mm (x1)
[ ] Glass Watch Face 40mm (x1)
[ ] Screws M1.5x3mm (x4)
[ ] Double Sided Tape
```

---

## Step 1: Prepare the ESP32

### 1.1 Test the Board
Before soldering anything, test your ESP32 board:

1. Connect ESP32 to PC via USB-C
2. Open Arduino IDE
3. Select: Tools → Board → ESP32 Dev Module
4. Select correct COM port
5. Upload a blank sketch (File → New → Upload)
6. Verify no errors

### 1.2 Mark the Pins
Using a marker, label these pins on your ESP32:
- **GPIO 21** = I2C SDA
- **GPIO 22** = I2C SCL
- **GPIO 4** = LED Red
- **GPIO 16** = LED Green
- **GPIO 17** = Button Mode
- **GPIO 34** = Button SOS
- **GPIO 35** = Button Back

---

## Step 2: Wire the MAX30102 Sensor

### 2.1 Pinout
```
MAX30102 Pin    →    ESP32 Pin
────────────────────────────────
VIN             →    3V3
GND             →    GND
SDA             →    GPIO 21 (I2C SDA)
SCL             →    GPIO 22 (I2C SCL)
INT             →    GPIO 25
```

### 2.2 Soldering Steps

1. **Tin the pads** on both MAX30102 and ESP32
2. **Cut 4 wires** to ~5cm each (SDA, SCL, VCC, GND)
3. **Strip ends** and tin them
4. **Solder SDA** (Orange wire typically): MAX30102 SDA → ESP32 GPIO 21
5. **Solder SCL** (Blue wire): MAX30102 SCL → ESP32 GPIO 22
6. **Solder VCC**: MAX30102 VIN → ESP32 3V3
7. **Solder GND**: MAX30102 GND → ESP32 GND
8. **Solder INT** (Optional): MAX30102 INT → ESP32 GPIO 25

### 2.3 Test MAX30102
Upload the test sketch to verify:
```cpp
#include <Wire.h>
void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22); // SDA, SCL
  Serial.println("I2C Scanner starting...");
}
void loop() {
  byte error, address;
  int nDevices;
  nDevices = 0;
  for(address = 1; address < 127; address++ ) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      Serial.print("I2C device found at 0x");
      if (address<16) Serial.print("0");
      Serial.println(address,HEX);
      nDevices++;
    }
  }
  delay(5000);
}
```
**Expected:** Should find device at 0x57

---

## Step 3: Wire the MPU6050 Sensor

### 3.1 Pinout
```
MPU6050 Pin     →    ESP32 Pin
────────────────────────────────
VCC             →    3V3
GND             →    GND
SDA             →    GPIO 21 (shared with MAX30102)
SCL             →    GPIO 22 (shared with MAX30102)
INT             →    GPIO 27
```

### 3.2 Soldering Steps

1. **Cut 4 wires** for power (red, black) and I2C (can share with MAX30102)
2. **Solder VCC**: MPU6050 VCC → ESP32 3V3
3. **Solder GND**: MPU6050 GND → ESP32 GND
4. **Solder SDA**: MPU6050 SDA → ESP32 GPIO 21 (same as MAX30102)
5. **Solder SCL**: MPU6050 SCL → ESP32 GPIO 22 (same as MAX30102)
6. **Solder INT**: MPU6050 INT → ESP32 GPIO 27

### 3.3 Test MPU6050
Upload test sketch - should find device at 0x68

---

## Step 4: Wire the SSD1306 Display

### 4.1 Pinout
```
SSD1306 Pin     →    ESP32 Pin
────────────────────────────────
VCC             →    3V3
GND             →    GND
SDA             →    GPIO 21 (shared)
SCL             →    GPIO 22 (shared)
```

### 4.2 Soldering Steps

1. **Cut 4 wires** ~8cm each
2. **Solder VCC**: Display VCC → ESP32 3V3
3. **Solder GND**: Display GND → ESP32 GND
4. **Solder SDA**: Display SDA → ESP32 GPIO 21
5. **Solder SCL**: Display SCL → ESP32 GPIO 22

### 4.3 Test Display
Upload Adafruit SSD1306 test sketch - should show "SSD1306 allocation failed" if not found

---

## Step 5: Wire the Battery & Charger

### 5.1 Pinout
```
TP4056 Pin      →    Connection
────────────────────────────────
B+              →    Battery + (Red wire)
B-              →    Battery - (Black wire)
OUT+            →    ESP32 USB 5V (for charging) + Battery Protection Circuit
OUT-            →    GND

Battery         →    ESP32 3V3 (via protection circuit)
```

### 5.2 IMPORTANT: Battery Protection

⚠️ **NEVER connect battery directly to ESP32 without protection!**

1. **Install a protection circuit** between battery and ESP32:
   ```
   Battery + → [Protection IC TP4056] → ESP32 3V3
   Battery - → GND → ESP32 GND
   ```

2. **Or use a breadboard power module** with built-in protection

### 5.3 Charging Circuit

1. **Solder battery leads** to TP4056 B+ and B- pads
2. **Connect TP4056 OUT+** to ESP32 VUSB (5V)
3. **Connect TP4056 OUT-** to ESP32 GND
4. **Connect Battery** directly to ESP32 3V3 and GND (for power when USB disconnected)

---

## Step 6: Wire the LEDs and Buttons

### 6.1 LEDs (with resistors)

```
Red LED:
  ESP32 GPIO 4 → [220 Ohm Resistor] → [Red LED +] → GND

Green LED:
  ESP32 GPIO 16 → [220 Ohm Resistor] → [Green LED +] → GND
```

**Steps:**
1. Bend LED leads - longer lead is + (anode)
2. Solder 220Ω resistor to GPIO 4
3. Solder resistor to Red LED + lead
4. Solder Red LED - lead to GND
5. Repeat for Green LED with GPIO 16

### 6.2 Buttons

```
Mode Button:
  ESP32 3V3 ───┬─── [Button] ─── GPIO 17
  
SOS Button:
  ESP32 3V3 ───┬─── [Button] ─── GPIO 34

Back Button:
  ESP32 3V3 ───┬─── [Button] ─── GPIO 35
```

**Steps:**
1. Connect one side of each button to 3V3
2. Connect other side to respective GPIO
3. Use internal pull-down (or pull-up with INPUT_PULLUP mode)

---

## Step 7: Assemble the Case

### 7.1 Prepare Components

1. **Clean all PCBs** with IPA
2. **Test fit** all components in case
3. **Mark screw holes** on PCB
4. **Drill holes** if needed

### 7.2 Mount Order

```
Bottom Case
├── Battery (glue with double-sided tape)
├── ESP32 + Sensors PCB (screws)
├── Display (glue or clip)
└── Top Case (screws)
```

### 7.3 Final Assembly

1. **Place battery** in bottom case, glue if loose
2. **Route wires** neatly, use zip ties
3. **Mount ESP32 PCB** with M1.5 screws
4. **Connect display** - can use ribbon cable for flexibility
5. **Close case** - ensure buttons are accessible
6. **Attach watch band**

---

## Step 8: Upload Firmware

### 8.1 Required Libraries

Install via Arduino Library Manager:
- [x] Adafruit GFX Library
- [x] Adafruit SSD1306
- [x] Adafruit BusIO
- [x] SparkFun MAX3010x (for MAX30102)
- [x] MPU6050 (various libraries available)

### 8.2 Upload via PlatformIO

```bash
cd firmware/esp32/DigitalSaverOnyx
pio run --target upload
```

### 8.3 Upload via Arduino IDE

1. Open `firmware/esp32/DigitalSaverOnyx/src/main.cpp`
2. Configure board settings
3. Upload

---

## Step 9: Testing

### 9.1 Power Test
- [ ] USB-C charges battery
- [ ] Battery powers ESP32 when USB disconnected
- [ ] No smoke/hot components

### 9.2 Display Test
- [ ] Watch face appears on screen
- [ ] Screen updates every second

### 9.3 Sensor Test
- [ ] Place finger on MAX30102 - heart rate appears
- [ ] Move watch - steps increment
- [ ] SpO2 reading shows 95%+

### 9.4 Button Test
- [ ] Mode button changes screen
- [ ] SOS button triggers emergency mode
- [ ] Back button returns to previous

### 9.5 BLE Test
- [ ] Watch appears in Digital Saver app
- [ ] Data syncs to phone
- [ ] Emergency alerts work

---

## Troubleshooting

### Display Issues
- **No display**: Check I2C connections (SDA/SCL)
- **Garbled text**: Try different I2C address (0x3D vs 0x3C)

### Sensor Issues
- **MAX30102 not found**: Check 3V3 power, try reset
- **No heart rate**: Ensure finger covers sensor completely
- **MPU6050 freeze**: Add pull-up resistors on SDA/SCL

### Battery Issues
- **Battery drains fast**: Check for short circuits
- **Won't charge**: Verify TP4056 connections

### BLE Issues
- **Not visible**: Check device name in code
- **Won't connect**: Clear Bluetooth cache on phone

---

## Next Steps

After assembly:
1. Connect to Digital Saver app
2. Set up user profile
3. Calibrate sensors
4. Test emergency features
5. Start wearing!

---

**Good luck with your Onyx build! 🔧❤️**
