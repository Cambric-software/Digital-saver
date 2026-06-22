# Assembly Guide - Digital Saver Smartwatch

## Overview

This guide will help you assemble the Digital Saver smartwatch from the components. The assembly process takes approximately 2-3 hours for the first prototype.

## Tools Required

| Tool | Purpose |
|------|---------|
| Soldering iron (60W) | Component soldering |
| Multimeter | Testing connections |
| Wire cutters | Cutting wires |
| Pliers | Component handling |
| Screwdrivers | Case assembly |
| 3D printer | Enclosure (optional) |

## Components List

### Electronics
- [x] ESP32-WROOM-32 module
- [x] MAX30102 PPG sensor module
- [x] MPU6050 accelerometer module
- [x] 1.3" OLED display (SH1106)
- [x] TP4056 LiPo charger module
- [x] 500mAh LiPo battery
- [x] 10mm vibration motor
- [x] 5V active buzzer
- [x] Tactile button
- [x] Resistors, capacitors (see schematic)

### Mechanical
- [x] 3D printed watch case (top and bottom)
- [x] 22mm silicone watch band
- [x] M2 screws (4x)
- [x] Double-sided tape

## Step 1: Prepare the PCB

1. **Cut the perfboard** to 45mm x 45mm
2. **Mark component locations** according to schematic
3. **Install headers** for ESP32, sensors
4. **Add solder bridges** for power distribution

## Step 2: Solder Components

### Power Circuit
```
1. Solder TP4056 charger module
2. Connect battery positive to TP4050 B+
3. Connect battery negative to TP4050 B-
4. Add 3.3V regulator if needed
```

### I2C Bus
```
1. Connect all SDA lines together (GPIO 21)
2. Connect all SCL lines together (GPIO 22)
3. Add 4.7K pull-up resistors on both lines
```

### Sensor Connections
| Sensor | Pin | ESP32 Pin |
|--------|-----|-----------|
| MAX30102 SDA | SDA | GPIO 21 |
| MAX30102 SCL | SCL | GPIO 22 |
| MAX30102 INT | INT | GPIO 35 |
| MPU6050 SDA | SDA | GPIO 21 |
| MPU6050 SCL | SCL | GPIO 22 |
| MPU6050 INT | INT | GPIO 34 |

### Output Devices
| Device | Pin | ESP32 Pin |
|--------|-----|-----------|
| OLED SDA | SDA | GPIO 21 |
| OLED SCL | SCL | GPIO 22 |
| Buzzer | IO | GPIO 27 |
| Motor | IO | GPIO 26 |
| Button | IO | GPIO 0 |

## Step 3: Test Connections

### Power Test
1. Connect battery
2. Measure 3.3V on ESP32
3. Check TP4056 charging indicator

### I2C Scan
```arduino
// Use I2C scanner sketch to verify all sensors respond
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);
  
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    if (Wire.endTransmission() == 0) {
      Serial.print("Found device at 0x");
      Serial.println(address, HEX);
    }
  }
}

void loop() {}
```

Expected addresses:
- MAX30102: 0x57
- MPU6050: 0x68
- OLED: 0x3C

## Step 4: Flash Firmware

### Option 1: PlatformIO (Recommended)
```bash
cd hardware/firmware/esp32
pio run --target upload
```

### Option 2: Arduino IDE
1. Install ESP32 board package
2. Install required libraries
3. Open DigitalSaverWatch.ino
4. Upload to board

## Step 5: Mechanical Assembly

### Case Assembly
1. **Insert display** into top case
2. **Secure PCB** with M2 screws
3. **Connect battery** to TP4056
4. **Install vibration motor** in dedicated slot
5. **Attach buzzer** to case
6. **Close case** and secure with screws

### Watch Band
1. **Thread band** through case lugs
2. **Secure with spring bars**
3. **Adjust to fit wrist** (typical 18-22cm)

## Step 6: Initial Setup

### First Boot
1. Battery should be charged via USB-C
2. Watch will display startup screen
3. LED will blink on MAX30102
4. Device name: "DigitalSaver Watch"

### Mobile App Setup
1. Install Digital Saver app from store (or build from source)
2. Enable Bluetooth and location permissions
3. Search for "DigitalSaver Watch"
4. Tap to connect

## Troubleshooting

### No Display
- Check OLED connections
- Verify I2C address (0x3C)
- Try adjusting contrast

### Sensors Not Detected
- Run I2C scanner
- Check pull-up resistors
- Verify solder connections

### BLE Not Connecting
- Move closer to phone
- Check Bluetooth permissions
- Restart watch and phone

## Safety Notes

⚠️ **Battery Safety**
- Do not puncture battery
- Charge only with TP4056
- Disconnect when not in use

⚠️ **Soldering Safety**
- Work in ventilated area
- Keep iron tip clean
- Allow components to cool

## Next Steps

After assembly:
1. Calibrate blood pressure readings
2. Test fall detection
3. Configure emergency contacts
4. Test emergency alerts
