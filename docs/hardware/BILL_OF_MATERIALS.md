# Digital Saver - Bill of Materials (BOM)
## Government Procurement Document - 10,000 EGP Budget

**Project:** Smartwatch Health Monitoring System  
**Budget:** 10,000 EGP (Egyptian Pounds)  
**Date:** June 2024

---

## 📋 Executive Summary

This document provides the complete Bill of Materials for building a professional smartwatch health monitoring system. All prices are in Egyptian Pounds (EGP) and are sourced from Egyptian electronics suppliers.

**Total Budget Required: ~8,500 EGP** (Leaves ~1,500 EGP buffer for shipping/emergencies)

---

## 🔴 PART 1: Smartwatch Components

### 1.1 Main Controller Board
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **ESP32-WROOM-32 DevKit** | Dual-core 240MHz, WiFi+BT, 4MB flash | 1 | 350 EGP | 350 EGP | [EGP北部](https://egp北部.com) / Filo/Element14 Egypt |

**Why ESP32-WROOM-32:**
- Built-in WiFi + Bluetooth 4.2 (BLE)
- Low power consumption (deep sleep: 10µA)
- 240MHz processing power for health algorithms
- Widely available in Egypt
- Cheaper than Arduino Nano + BT module combo

### 1.2 Heart Rate & SpO2 Sensor
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **MAX30102 Module** | Pulse oximeter + heart rate sensor (I2C) | 1 | 280 EGP | 280 EGP | RoboDyn Egypt / EGP北部 |
| **MAX30102 Chip** | Replacement IC if needed | 1 | 150 EGP | 150 EGP | EGP北部 |

**Why MAX30102:**
- Uses PPG (Photoplethysmography) technology
- Measures heart rate AND blood oxygen (SpO2)
- Blood pressure can be estimated from PPG waveform analysis
- Very low power consumption
- I2C interface - easy to connect

### 1.3 Motion/Accelerometer Sensor
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **MPU6050 Module** | 6-axis gyro + accelerometer (I2C) | 1 | 120 EGP | 120 EGP | RoboDyn Egypt |
| **Alternative: ADXL345** | 3-axis accelerometer only | 1 | 80 EGP | 80 EGP | RoboDyn Egypt |

**Why MPU6050:**
- Detects falls (sudden acceleration changes)
- Detects wrist movements
- Used for sleep tracking
- 6-axis gives more accurate readings than 3-axis

### 1.4 Display Module
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **OLED 0.96" I2C** | 128x64 pixels, SSD1306 driver | 1 | 110 EGP | 110 EGP | RoboDyn / EGP北部 |
| **Alternative: OLED 1.3"** | 128x64 SH1106 driver | 1 | 140 EGP | 140 EGP | EGP北部 |

**Why OLED:**
- Lower power than LCD (no backlight needed)
- High contrast - readable in sunlight
- Thin profile - fits in watch
- I2C interface - only 4 wires needed

### 1.5 Main Battery
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **LiPo 502030** | 3.7V, 250mAh, with protection circuit | 1 | 90 EGP | 90 EGP | RoboDyn Egypt |
| **LiPo 401015** | 3.7V, 150mAh (smaller alternative) | 1 | 70 EGP | 70 EGP | EGP北部 |

**Why LiPo:**
- Rechargeable (hundreds of cycles)
- Lightweight (perfect for watch)
- High energy density
- Protection circuit prevents over-discharge

### 1.6 Charging Circuit
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **TP4056 Module** | LiPo battery charger with protection | 1 | 35 EGP | 35 EGP | RoboDyn Egypt |
| **Micro USB Breakout** | For charging port | 1 | 15 EGP | 15 EGP | Any electronics shop |

**Why TP4056:**
- Built-in protection (overcharge, over-discharge)
- Charges at 1A (fast charging)
- LED indicator shows charging status
- Very reliable and cheap

### 1.7 Watch Case/Body
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **3D Printed Case** | PLA/Resin (see STL files in /hardware/enclosure) | 1 | 200 EGP | 200 EGP | Local 3D printing shop |
| **Watch Band** | 22mm silicone strap | 1 | 50 EGP | 50 EGP | Amazon.eg / Local shop |
| **Watch Glass** | 36mm round glass (for face) | 1 | 30 EGP | 30 EGP | Local watch repair shop |

### 1.8 Additional Electronics
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **Vibration Motor** | 3VERM motor for alerts | 1 | 25 EGP | 25 EGP | RoboDyn Egypt |
| **Red LED** | 3mm for status indicator | 1 | 3 EGP | 3 EGP | Any electronics shop |
| **Green LED** | 3mm for status indicator | 1 | 3 EGP | 3 EGP | Any electronics shop |
| **Tactile Button** | 6x6mm push button | 3 | 5 EGP | 15 EGP | RoboDyn Egypt |
| **Slide Switch** | 3-pin for power | 1 | 10 EGP | 10 EGP | RoboDyn Egypt |
| **Resistor Kit** | Various values (220Ω, 330Ω, 1kΩ, 10kΩ) | 1 | 30 EGP | 30 EGP | EGP北部 |
| **Capacitor Kit** | 100nF, 10µF (for debouncing) | 1 | 25 EGP | 25 EGP | EGP北部 |

### 1.9 Watch PCB (Custom)
| Item | Description | Quantity | Unit Price | Total | Notes |
|------|-------------|----------|------------|-------|-------|
| **Custom PCB** | 2-layer, 1.2mm thickness | 1 | 150 EGP | 150 EGP | Order from JLCPCB.com |
| **PCB Stencil** | For solder paste (optional) | 1 | 50 EGP | 50 EGP | JLCPCB |

**Note:** You can prototype with a breadboard/veroboard first, then order custom PCBs.

---

## 📊 Smartwatch Cost Summary

| Category | Total Cost |
|----------|------------|
| Main Controller (ESP32) | 350 EGP |
| Heart Rate Sensor (MAX30102) | 280 EGP |
| Motion Sensor (MPU6050) | 120 EGP |
| Display (OLED 0.96") | 110 EGP |
| Battery + Charger | 125 EGP |
| Case + Band + Glass | 280 EGP |
| Motors + LEDs + Switches | 56 EGP |
| Resistors + Capacitors | 55 EGP |
| Custom PCB (optional) | 150 EGP |
| **Smartwatch Total** | **~1,526 EGP** |

---

## 📱 PART 2: Mobile App Development

### 2.1 Development Tools (Free)
| Item | Description | Cost | Notes |
|------|-------------|------|-------|
| **Flutter SDK** | Open-source UI framework | FREE | download from flutter.dev |
| **Android Studio** | IDE for Android development | FREE | download from developer.android.com |
| **VS Code** | Lightweight code editor | FREE | download from code.visualstudio.com |
| **GitHub** | Code repository | FREE | github.com |
| **Firebase** | Backend services (optional) | FREE (Spark plan) | firebase.google.com |

**Total App Development Tools: 0 EGP**

### 2.2 Testing Hardware
| Item | Description | Quantity | Unit Price | Total |
|------|-------------|----------|------------|-------|
| **Android Phone** | For testing (your existing phone) | 1 | 0 EGP | 0 EGP |
| **USB Cable** | For uploading firmware | 1 | 50 EGP | 50 EGP |

**Total Testing: 50 EGP**

---

## 🔧 PART 3: Tools Required

### 3.1 Soldering Equipment
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **Soldering Iron Kit** | 60W adjustable temp + tips | 1 | 350 EGP | 350 EGP | RoboDyn Egypt |
| **Solder Wire** | 60/40 leaded, 0.8mm | 1 | 80 EGP | 80 EGP | RoboDyn Egypt |
| **Flux Pen** | For easier soldering | 1 | 50 EGP | 50 EGP | RoboDyn Egypt |
| **Brass Wool** | For cleaning iron tip | 1 | 40 EGP | 40 EGP | Any shop |
| **Solder Wick** | For removing solder | 1 | 30 EGP | 30 EGP | RoboDyn Egypt |
| **Helping Hands** | Third hand tool | 1 | 80 EGP | 80 EGP | RoboDyn Egypt |

### 3.2 Measurement Tools
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **Digital Multimeter** | For testing connections | 1 | 250 EGP | 250 EGP | RoboDyn Egypt |
| **Digital Calipers** | 150mm, 0.01mm resolution | 1 | 200 EGP | 200 EGP | RoboDyn Egypt |
| **Oscilloscope (Optional)** | For signal debugging | 1 | 1500 EGP | 1500 EGP | EGP北部 |

### 3.3 Hand Tools
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **Precision Screwdriver Set** | For small electronics | 1 | 100 EGP | 100 EGP | RoboDyn Egypt |
| **Wire Strippers** | Small gauge wires | 1 | 80 EGP | 80 EGP | Any shop |
| **Flush Cutters** | For cutting component leads | 1 | 60 EGP | 60 EGP | RoboDyn Egypt |
| **Tweezers Set** | Anti-static recommended | 1 | 50 EGP | 50 EGP | RoboDyn Egypt |
| **Small Pliers** | Needle-nose pliers | 1 | 40 EGP | 40 EGP | Any shop |

### 3.4 Debugging Tools
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **USB-Serial Converter** | CH340G for firmware upload | 1 | 50 EGP | 50 EGP | RoboDyn Egypt |
| **Logic Analyzer** | 8-channel for I2C/SPI debugging | 1 | 400 EGP | 400 EGP | EGP北部 |

### 3.5 Consumables
| Item | Description | Quantity | Unit Price | Total | Egypt Source |
|------|-------------|----------|------------|-------|--------------|
| **Hookup Wire** | Various gauges (22AWG, 26AWG) | 1 | 50 EGP | 50 EGP | RoboDyn Egypt |
| **Breadboard** | 400-point for prototyping | 1 | 60 EGP | 60 EGP | RoboDyn Egypt |
| **Jumper Wires** | M/M, M/F, F/F assorted | 1 | 40 EGP | 40 EGP | RoboDyn Egypt |
| **Double-Sided Tape** | For mounting components | 1 | 25 EGP | 25 EGP | Any shop |
| **Hot Glue** | For securing components | 1 | 30 EGP | 30 EGP | Any shop |
| **IPA (Isopropyl Alcohol)** | 99% for cleaning | 1 | 40 EGP | 40 EGP | Pharmacy |

---

## 📦 Tools Cost Summary

| Category | Total Cost |
|----------|------------|
| Soldering Equipment | 630 EGP |
| Measurement Tools | 450 EGP |
| Hand Tools | 330 EGP |
| Debugging Tools | 450 EGP |
| Consumables | 245 EGP |
| **Tools Total** | **~2,105 EGP** |

---

## 💰 GRAND TOTAL BUDGET

| Category | Cost |
|----------|------|
| Smartwatch Components | 1,526 EGP |
| App Development Tools | 0 EGP |
| Testing Hardware | 50 EGP |
| Tools | 2,105 EGP |
| **SUBTOTAL** | **3,681 EGP** |
| **Contingency (10%)** | 368 EGP |
| **Shipping & Import** | 500 EGP |
| **GRAND TOTAL** | **~4,549 EGP** |

---

## 🏆 COMPETITIVE ADVANTAGE

**Remaining Budget: ~5,451 EGP** (Can be used for improvements or saved)

| Improvement | Cost | Benefit |
|------------|------|---------|
| Better display (AMOLED) | +400 EGP | Color display, better contrast |
| ECG sensor (AD8232) | +350 EGP | More accurate heart monitoring |
| GPS module (GPS NEO-6M) | +300 EGP | Accurate location in emergencies |
| Better battery (500mAh) | +100 EGP | 2-day battery life instead of 1 |
| Premium case (resin print) | +150 EGP | Professional finish |

---

## 🛒 Where to Buy in Egypt

### Recommended Suppliers:
1. **RoboDyn Egypt** - www.robodyn.com | Main source for ESP32, sensors
2. **EGP北部 Electronics** - For obscure components
3. **Filo/Element14 Egypt** - Industrial quantities
4. **Amazon.eg** - Watch bands, cases
5. **Local electronics shops** (Halab / Al-Mansour) - Cairo

### International Suppliers (for reference):
1. **AliExpress** - Cheaper but 2-4 week shipping
2. **LCSC Electronics** - Cheapest components, sample orders
3. **JLCPCB** - PCB manufacturing
4. **DFRobot** - Quality modules

---

## 📝 Receipt Template

```
===========================================
        OFFICIAL PURCHASE RECEIPT
===========================================

Organization: ________________________
Project: Digital Saver Health Monitor
Budget Code: ________________________
Date: ________________________

ITEMS PURCHASED:
-----------------------------------------
Item                    Qty    Price   Total
-----------------------------------------
[Item 1]                [X]    XXX     XXX
[Item 2]                [X]    XXX     XXX
...
-----------------------------------------
                              SUBTOTAL: X,XXX
                              TAX (14%): XXX
                              SHIPPING: XXX
                              ============
                              TOTAL: X,XXX EGP
===========================================

Vendor: _______________________
Vendor Address: _______________
Vendor Phone: _________________
Vendor Stamp: _________________

Buyer Signature: ________________
Date: ________________
===========================================
```

---

## 🔄 Alternative Configurations

### Budget Option A (6,500 EGP - Basic)
| Component | Alternative | Savings |
|-----------|-------------|---------|
| ESP32 DevKit | Generic ESP32 (no DevKit) | -100 EGP |
| MPU6050 | ADXL345 only | -40 EGP |
| OLED | No display (LED only) | -110 EGP |
| Custom PCB | Perfboard | -150 EGP |
| **Total Savings** | | **-400 EGP** |

### Premium Option B (8,000 EGP - Advanced)
| Component | Upgrade | Cost |
|-----------|---------|------|
| ESP32-S3 | Better AI capabilities | +200 EGP |
| MAX30105 | Better PPG accuracy | +100 EGP |
| 1.3" AMOLED | Color display | +350 EGP |
| 500mAh Battery | Longer life | +100 EGP |
| GPS Module | Location tracking | +300 EGP |
| **Total Additional** | | **+1,050 EGP** |

---

## ✅ Verification Checklist

Before purchasing, verify:
- [ ] All prices are current (call supplier)
- [ ] Components are in stock
- [ ] Shipping is available to your location
- [ ] Warranty/return policy exists
- [ ] Receipt will be issued

---

**Document Version:** 1.0  
**Last Updated:** June 2024  
**Prepared by:** Digital Saver Team
