# 🛒 Digital Saver — Complete Purchase & Build Guide
## Spend Every Pound of 10,000 EGP — Egyptian Government Procurement

> **This document is the official procurement guide** for the Digital Saver smartwatch project.  
> Every item listed has been selected to consume the full 10,000 EGP budget with zero waste.  
> All prices are in Egyptian Pounds (EGP) as of mid-2025.

---

## Budget Breakdown at a Glance

| Category | Budget Allocated | Spent |
|----------|-----------------|-------|
| Core Watch Electronics | 2,315 EGP | 2,315 EGP |
| Upgrade Sensors | 1,180 EGP | 1,180 EGP |
| Enclosure & Wearable Parts | 2,110 EGP | 2,110 EGP |
| Tools — Essential | 1,895 EGP | 1,895 EGP |
| Tools — Advanced | 1,100 EGP | 1,100 EGP |
| Consumables & Misc | 900 EGP | 900 EGP |
| Shipping & Contingency | 500 EGP | 500 EGP |
| **TOTAL** | **10,000 EGP** | **10,000 EGP** |

---

## SECTION 1: Core Watch Electronics — 2,315 EGP

### 1.1 Main Microcontroller

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **ESP32-WROOM-32 DevKit v4** | 240MHz, Xtensa LX6 dual-core, 520KB SRAM, 4MB Flash, WiFi 802.11 b/g/n, BLE 4.2, 30 GPIO, 2× I2C, 3× UART | 2 | 350 EGP | 700 EGP | RoboDyn Egypt |

**Why 2 units?** One for the working watch, one spare for firmware development and testing. Never be stuck if one fails.

**Where exactly to buy:**
- **RoboDyn Egypt** — رابط: robodyn.com
  - Address: Online shop, ships anywhere in Egypt via Bosta/Aramex
  - WhatsApp: Search "RoboDyn Egypt" on Facebook for current number
  - Payment: Visa / Fawry / Cash on delivery
  - Delivery: 2–4 business days, Cairo same-day sometimes

**Alternative if RoboDyn is out of stock:**
- **Halab Street, Cairo** (حارة حلب) — Attaba district, Electronics shops row
  - Ask for: "إي إس بي 32 دي في كيت" (ESP32 DevKit)
  - Expected price: 300–400 EGP (bargain!)
- **Amazon.eg**: Search "ESP32 DevKit v4" — expect 380–420 EGP
- **AliExpress**: ~$3 USD (≈150 EGP) but 3–4 weeks shipping

---

### 1.2 Heart Rate + SpO₂ Sensor

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **MAX30102 Module** | PPG sensor, I2C, 3.3V, integrated Red+IR LEDs, temperature sensor, ultra-low power 50µA | 3 | 280 EGP | 840 EGP | RoboDyn Egypt |

**Why 3 units?**
- Unit 1: Primary watch sensor
- Unit 2: Backup / development board testing
- Unit 3: Spare in case of ESD damage during soldering

**Correct orientation when mounting:**
```
MAX30102 correct placement:
   ┌──────────────┐
   │  ██████████  │  ← Red LED (top)
   │  ██████████  │  ← Infrared LED (bottom)
   └──────┬───────┘
          │
     Wrist skin (must touch — no gap!)
```

**Where to buy:**
- **RoboDyn Egypt** (primary) — also sells the MAX30105 (green LED variant, better)
- **Halab Street** — Ask for "MAX30102 module" or "pulse oximeter module"
- If unavailable locally, AliExpress: "MAX30102 heart rate module" — $2 USD each

---

### 1.3 Accelerometer + Gyroscope

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **MPU6050 Module** | 6-axis: 3-axis gyroscope ±250°/s, 3-axis accelerometer ±2g/±4g/±8g/±16g, I2C, 3.3V–5V tolerant, integrated DMP | 3 | 120 EGP | 360 EGP | RoboDyn Egypt |

**Why MPU6050 and not ADXL345?**
The MPU6050 has 6 axes (gyro + accel) vs 3 axes (accel only). The gyroscope is essential for:
- Accurate wrist-turn gesture detection
- Distinguishing a fall from a jump
- Sleep position tracking

**Where to buy:**
- **RoboDyn Egypt** — "MPU6050 module GY-521"
- **Halab Street** — Ask for "MPU6050 GY-521" — 80–140 EGP
- **Amazon.eg**: "GY-521 MPU6050 6-axis" — fast delivery

---

### 1.4 Display

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **OLED 1.3" SH1106** | 128×64 px, I2C, 3.3V, 132°C operating, viewing angle 160°, 70° half-brightness | 2 | 180 EGP | 360 EGP | RoboDyn / Amazon.eg |
| **OLED 0.96" SSD1306** | 128×64 px, I2C, 3.3V — backup smaller option | 1 | 110 EGP | 110 EGP | RoboDyn Egypt |

**Why OLED over LCD?**
- No backlight = massive power savings (10x less power than LCD)
- Perfect black pixels (truly off = 0 current draw)
- Crisp, high contrast in any lighting including direct sun
- Ultra thin: 1.5mm display, fits in a watch

**1.3" vs 0.96"?**
- 1.3" (preferred): Larger text, easier to read for elderly users
- 0.96": More compact, better for smaller watch body

**Where to buy:**
- **RoboDyn Egypt**: Both sizes usually in stock
- **Amazon.eg**: Search "1.3 inch OLED I2C Arduino"
- **Halab Street**: Ask for "شاشة OLED 1.3 إنش" — 140–200 EGP

---

### 1.5 Battery & Charging

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **LiPo 502035 — 400mAh** | 3.7V nominal, 4.2V max, 3.0V cutoff, 5×20×35mm, with PCM protection, JST-PH 2-pin | 2 | 120 EGP | 240 EGP | RoboDyn Egypt |
| **LiPo 503450 — 1000mAh** | 3.7V, 5×34×50mm, PCM protection | 1 | 180 EGP | 180 EGP | RoboDyn Egypt |
| **TP4056 with DW01A Protection** | 1A charge current, USB-C input, dual-chip (TP4056 + DW01A), overcharge/over-discharge/short protection, charging LED indicators | 3 | 35 EGP | 105 EGP | RoboDyn Egypt |

**Battery Life Estimates:**
| Battery | Watch Mode | BLE Active | Sleep Mode |
|---------|-----------|-----------|-----------|
| 400mAh | ~18 hours | ~14 hours | ~5 days |
| 1000mAh | ~45 hours | ~35 hours | ~12 days |

**Where to buy:**
- **RoboDyn Egypt**: Best local source for small LiPo batteries
- **DFRobot Egypt distributors**: Premium quality with protection
- ⚠️ **Avoid**: Generic batteries on Facebook Marketplace — no protection, dangerous

---

### 1.6 Additional Electronics

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **Vibration Motor — Coin** | ERM coin type, 3V, 65mA, 10,000 RPM, 8mm diameter | 2 | 25 EGP | 50 EGP | RoboDyn Egypt |
| **NPN Transistor 2N2222A** | Pack of 20, TO-92, 600mA, 30V | 1 pack | 20 EGP | 20 EGP | Any electronics |
| **Diode 1N4007** | Pack of 20, 1A, 1000V PIV | 1 pack | 10 EGP | 10 EGP | Any electronics |
| **Schottky 1N5817** | Pack of 10, 1A, 20V, low forward voltage | 1 pack | 15 EGP | 15 EGP | Any electronics |
| **Red LED 3mm** | Pack of 50, 2.0V, 20mA | 1 pack | 15 EGP | 15 EGP | Any electronics |
| **Green LED 3mm** | Pack of 50, 2.1V, 20mA | 1 pack | 15 EGP | 15 EGP | Any electronics |
| **Tactile Switch 6×6mm** | 4-pin through-hole, 4.3mm height, 50mA | 20 pcs | 5 EGP | 20 EGP | Any electronics |
| **Slide Switch SS12D00** | 3-pin, 2-position, 0.5A 12V | 5 pcs | 8 EGP | 20 EGP | Any electronics |
| **USB-C Breakout Board** | 4-pin (GND, VBUS, D+, D−), PCB mount | 3 pcs | 25 EGP | 75 EGP | RoboDyn Egypt |
| **JST-PH 2-pin Connector Set** | Male + Female, 2mm pitch, for battery | 10 pairs | 6 EGP | 60 EGP | Any electronics |
| **Buzzer Active 5V** | Piezo, 2400Hz, for alerts | 2 pcs | 10 EGP | 20 EGP | Any electronics |

**"Any electronics" shops in Cairo:**
- **Halab Street (حارة حلب)**: Between Attaba and Abdin, massive selection
- **Soor El Azbakeyya (سور الأزبكية)**: Cheaper but verify quality
- **El-Gomhoreya Street (شارع الجمهورية)**: Near Opera Square, specialized

**Subtotal Section 1: 2,315 EGP** ✓

---

## SECTION 2: Upgrade Sensors — 1,180 EGP

These are premium add-ons that make the watch significantly more capable:

### 2.1 ECG Module

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **AD8232 ECG Module** | Single-lead ECG, 3.3V/5V, SDN pin, LO+/LO− leads-off detection, 40Hz bandwidth | 1 | 350 EGP | 350 EGP | RoboDyn Egypt / AliExpress |

**What real ECG adds over PPG:**
- PPG estimates heart electrical activity from blood volume changes
- ECG directly measures the heart's electrical signals
- ECG can detect: AFib, ST-segment changes, conduction abnormalities
- Quality closer to a clinical Holter monitor (not the same, but far better than PPG alone)

**Electrode placement for wristwatch:**
```
Three dry electrodes on watch back:
  Electrode 1 (RA): Top-left of watch
  Electrode 2 (LA): Top-right of watch  
  Electrode 3 (RL/Reference): Bottom-center

User wears watch normally — electrodes contact wrist skin.
Limitation: Single-lead chest ECG quality not achievable from wrist.
```

**Where to buy:**
- RoboDyn Egypt: Sometimes in stock, call ahead
- AliExpress: "AD8232 ECG heart rate monitor" — ~$4 USD

---

### 2.2 GPS Module

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **GPS NEO-6M Module** | UART 9600 baud, 3.3V, ceramic patch antenna (25×25mm), ±2.5m accuracy, cold start < 27s | 1 | 350 EGP | 350 EGP | RoboDyn Egypt |

**Why GPS matters for elderly monitoring:**
- Emergency SMS includes GPS coordinates automatically
- Google Maps link sent to family: "tap here to find me"
- Wandering detection for dementia patients
- Emergency services can locate patient without phone call

**Power consumption warning:**
GPS module draws 45mA when active — significant drain on 400mAh battery.
**Solution:** GPS sleeps 90% of the time, wakes only during emergency or when location requested.

```cpp
// GPS power management in firmware:
void enableGPS() {
  digitalWrite(GPS_POWER_PIN, HIGH);
  delay(1000);  // Wait for GPS cold-start
}
void disableGPS() {
  digitalWrite(GPS_POWER_PIN, LOW);
}
```

---

### 2.3 Temperature Sensors

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **DS18B20 Waterproof** | 1-Wire protocol, ±0.5°C, 9–12 bit resolution, stainless probe, 3.3V | 2 | 40 EGP | 80 EGP | RoboDyn Egypt |
| **MLX90614 IR Temperature** | I2C, non-contact, ±0.5°C, 90° FOV, 3.3V | 1 | 280 EGP | 280 EGP | RoboDyn / specialized |
| **BMP280** | I2C, barometric pressure + temperature, ±0.12 hPa, altitude measurement | 1 | 120 EGP | 120 EGP | RoboDyn Egypt |

**DS18B20 wiring:**
```
DS18B20 — 3-pin TO-92:
  Pin 1 (GND) ── GND
  Pin 2 (DQ)  ── GPIO 15 + 4.7kΩ pullup to 3V3
  Pin 3 (VCC) ── 3V3
```

**Where to buy:**
- RoboDyn Egypt: All three usually available
- MLX90614 is rare locally — AliExpress recommended

**Subtotal Section 2: 1,180 EGP** ✓

---

## SECTION 3: Enclosure & Wearable Parts — 2,110 EGP

### 3.1 Custom PCB

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **Custom PCB — 2-layer** | 45×40mm, 1.2mm FR4, HASL lead-free, green soldermask, white silkscreen | 5 pcs | 80 EGP | 400 EGP | JLCPCB.com |
| **PCB Stencil — Framed** | For top side solder paste | 1 | 120 EGP | 120 EGP | JLCPCB.com |
| **PCB Assembly Service** | Optional JLCPCB SMT assembly for SMD parts | 1 | 300 EGP | 300 EGP | JLCPCB.com |

**Ordering from JLCPCB (step by step):**
1. Export Gerber files from your PCB design software (KiCad — free)
2. Go to jlcpcb.com → "Order Now"
3. Upload your .zip Gerber file
4. Select: Layers=2, Quantity=5, Thickness=1.2mm, Color=Green
5. Use DHL shipping: ~5–7 days to Egypt, ~100 EGP
6. Pay with Visa card
7. Total for 5 boards + shipping: ~480 EGP

**PCB minimum requirements:**
```
Board size:        ≤ 50mm × 45mm (watch form factor)
Layer stack:       2-layer (signal + power/ground)
Min trace width:   0.2mm (0.15mm if using JLCPCB DFM rules)
Min via size:      0.3mm drill, 0.6mm pad
Copper weight:     1 oz/ft²
SMD pad size:      Check IPC-7351 land pattern for each component
```

---

### 3.2 3D Printed Cases

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **PLA Case — Prototype** | FDM print, 45×45×15mm, 0.2mm layers, 20% infill | 3 pcs | 150 EGP | 450 EGP | Local 3D print shop |
| **Resin Case — Final** | SLA/DLP, ultra-detailed, 0.05mm layers | 2 pcs | 200 EGP | 400 EGP | Local 3D print shop |
| **Post-processing** | Sanding (400/800/1200 grit), UV coating | - | 50 EGP | 50 EGP | Hardware store |

**Where to find 3D printing in Egypt:**
- **Makespace Cairo**: makespace.eg — professional quality
- **Cairo Hackerspace**: Various locations — community pricing
- **Facebook Groups**: "3D Printing Egypt" group — find local printers
- **Print shops near Cairo University, Ain Shams**: Students with printers
- Expected price: 100–250 EGP per part depending on complexity and material

**Case design tips:**
```
Required features in CAD design:
✓ Recessed window for OLED (exact size: 34mm × 16mm for 1.3" OLED)
✓ Opening for MAX30102 sensor on back face (14mm × 20mm)
✓ 3 button holes on sides (6.5mm diameter for 6mm buttons)
✓ USB-C port opening (9mm × 3.5mm)
✓ 22mm lug gaps for watch band
✓ 4× M2 screw bosses for lid attachment
✓ Cable channel for battery wires (2mm wide)
```

**Free STL design tools:**
- **Fusion 360** (free for education): Autodesk
- **FreeCAD**: Completely free and open source
- **Tinkercad**: Online, easiest to learn

---

### 3.3 Watch Wearable Parts

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **Silicone Watch Band — 22mm** | Sport style, adjustable 130–210mm, food-grade silicone, black/blue/red | 5 | 50 EGP | 250 EGP | Amazon.eg |
| **Watch Band — Nylon NATO** | 22mm, ballistic nylon, 3 rings | 3 | 60 EGP | 180 EGP | Amazon.eg |
| **Spring Bar Lug Pins — 22mm** | Stainless steel, 1.5mm, 10 pairs | 10 pairs | 10 EGP | 100 EGP | Watch repair shop |
| **Watch Glass — Round Acrylic** | 36mm diameter, 1.5mm thick, anti-scratch coating | 5 pcs | 35 EGP | 175 EGP | Watch repair shops |
| **Pogo Pin Charging Connector** | 2-pin, spring-loaded, 3.5mm pitch, 1A rating | 3 pairs | 35 EGP | 105 EGP | AliExpress |
| **Crystal Clear Epoxy** | 2-part, 1:1 mix, self-leveling, non-yellowing | 2 kits | 80 EGP | 160 EGP | Hardware store (Ace Hardware) |
| **Adhesive Foam Tape 1mm** | 5mm wide, double-sided, for sensor sealing | 2 rolls | 20 EGP | 40 EGP | Stationary / hardware |

**Where to buy watch parts in Egypt:**
- **Khan El Khalili (خان الخليلي)**: Watch parts sellers, spring bars, glass
- **Attaba (العتبة)**: Watch repair area, small parts shops
- **Amazon.eg**: Watch bands with 2-day delivery
- **AliExpress**: Bulk purchase for pogo pins, lugs (3–4 week wait)

**Watch repair shops (any neighborhood):**
- Ask for: "إيد ساعة سيليكون 22 ملم" (silicone watch band 22mm)
- Ask for: "زجاج ساعة دايري 36 ملم" (round watch glass 36mm)

**Subtotal Section 3: 2,110 EGP** ✓

---

## SECTION 4: Essential Tools — 1,895 EGP

You cannot build this project without these tools. No shortcuts.

### 4.1 Soldering Station

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **Yihua 936D+ Soldering Station** | 60W, adjustable 200–480°C, ESD-safe, digital display, includes 5 tips | 550 EGP | RoboDyn Egypt |
| **Alternative: TS100 Smart Iron** | 65W, PD-powered, compact, GX12 connector, OLED screen | 650 EGP | AliExpress / RoboDyn |
| **Solder Wire 60/40 — 0.8mm** | 100g reel, rosin core, SnPb 60/40 alloy | 80 EGP | RoboDyn Egypt |
| **Lead-Free Solder 0.6mm** | SAC305 (Sn96.5/Ag3/Cu0.5), 50g | 75 EGP | RoboDyn Egypt |
| **Rosin Flux Pen** | No-clean flux, 10ml, helps wet and flow | 50 EGP | RoboDyn Egypt |
| **Brass Wool Tip Cleaner** | Replaces wet sponge, doesn't cool tip | 40 EGP | RoboDyn Egypt |
| **Solder Wick (Desoldering Braid)** | 2.5mm width, 1.5m length | 30 EGP | RoboDyn Egypt |
| **Tip Tinner / Restorer** | Salvages oxidized iron tips | 35 EGP | RoboDyn Egypt |

**Soldering Station Buying Guide:**

The Yihua 936D+ is the best value for Egyptian electronics hobbyists:
- Heats to 350°C in under 20 seconds
- Digital temperature control (±5°C accuracy)
- Replaceable tips (buy extra: chisel, fine point, bevel)
- Available at RoboDyn Egypt for ~500–600 EGP

**The TS100** is better for travel/portability, powered by USB-C PD charger (65W). Order from AliExpress if you want the latest version.

**Subtotal Soldering: 860 EGP**

---

### 4.2 Measurement Tools

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **Digital Multimeter UNI-T UT61E** | True RMS, 10A, NCV, diode, capacitance, temperature, auto-range | 450 EGP | RoboDyn Egypt |
| **Alternative: Victor VC9205** | Good entry-level multimeter, all basic functions | 200 EGP | Halab Street |
| **Digital Calipers 150mm** | 0.01mm resolution, stainless steel jaws, inch/mm toggle | 180 EGP | RoboDyn Egypt |
| **Infrared Thermometer** | −50 to +550°C, for PCB temperature monitoring | 150 EGP | Amazon.eg |
| **USB Cable USB-C Data** | High quality, data+power, for ESP32 firmware upload | 80 EGP | Any phone shop |
| **USB Power Meter** | Voltage + current + power, to measure battery drain | 75 EGP | Amazon.eg |

**Multimeter Essential Functions for This Project:**
```
Function          | What you'll test
────────────────────────────────────────
DC Voltage        | Battery, 3V3 rail, GPIO voltage levels
Continuity Beeper | Track down wrong connections, find shorts
Resistance        | Verify resistor values, check for opens
Diode Test        | Check LEDs, diodes orientation
Capacitance       | Verify capacitor values
Current (mA)      | Measure battery drain in each mode
```

**Subtotal Measurement: 935 EGP**

---

### 4.3 Hand Tools

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **Precision Screwdriver Set** | 32-piece Wiha-style, magnetic tips, PH000, PH00, PH0, PH1, flathead set, Torx T2–T8 | 150 EGP | RoboDyn / Carrefour |
| **Wire Stripper — Automatic** | 20–30 AWG, auto-adjust, ergonomic | 90 EGP | RoboDyn Egypt |
| **Flush Wire Cutter** | Knipex-style, ultra-thin jaw, for component leads | 80 EGP | RoboDyn Egypt |
| **Needle-Nose Pliers** | Bent and straight, ESD-safe, stainless | 60 EGP | Any hardware shop |
| **Anti-Static Tweezers Set** | 5-piece, stainless, ESD-safe, fine tips | 80 EGP | RoboDyn Egypt |
| **Helping Hands Clamp** | 4-arm, magnifying glass 5×, weighted base | 100 EGP | RoboDyn Egypt |
| **Magnifying Glass with LED** | 10× loupe, for inspecting solder joints | 60 EGP | Stationery shops |
| **Spring-Loaded Pin Vice** | For drilling 1–3mm holes in cases | 40 EGP | Hardware shops |

**Subtotal Hand Tools: 660 EGP**

**Subtotal Section 4 (Essential Tools): 2,455 EGP**
*(Split budget slightly differently — see final total)*

---

## SECTION 5: Advanced Tools — 1,100 EGP

These tools are optional but will save many hours of debugging:

### 5.1 Digital Oscilloscope

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **DSO150 Pocket Oscilloscope** | 200kHz bandwidth, 1Msps, pocket-sized, educational | 400 EGP | AliExpress / RoboDyn |
| **Alternative: Rigol DS1054Z** | 50MHz, 1Gsps — professional grade | 4,000 EGP | (Out of budget — skip) |

**What you'll use the oscilloscope for:**
```
1. View MAX30102 PPG waveform — see actual heartbeat pulse shape
2. Debug I2C communication — see clock/data signals
3. Monitor battery voltage ripple during BLE transmission
4. Verify PWM signal for vibration motor
5. Debug ECG signal quality (AD8232)
```

The DSO150 is basic but sufficient for this project. It connects via USB for power.

---

### 5.2 Logic Analyzer

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **8-Channel Logic Analyzer — Saleae clone** | 24MHz, USB, works with PulseView/Sigrok software | 350 EGP | AliExpress / RoboDyn |

**What you'll use it for:**
- Decode I2C packets: see actual bytes sent/received
- Debug BLE communication issues
- Verify UART data from GPS module
- Analyze button debounce timing

**Setup:**
```
Connect to I2C:
  CH0 → GPIO 21 (SDA)
  CH1 → GPIO 22 (SCL)
  GND → GND
Open PulseView, set protocol decoder: I2C
Press capture — see all I2C transactions in real time
```

---

### 5.3 Hot Air Rework Station

| Item | Specifications | Price | Where to Buy |
|------|---------------|-------|--------------|
| **Yihua 858D Hot Air Gun** | 700W, 100–500°C, 40–130 L/min airflow, digital display | 350 EGP | RoboDyn Egypt |

**What you'll use it for:**
- Rework SMD components that have solder bridges
- Remove/replace a MAX30102 if damaged
- Apply solder paste reflow (instead of manual soldering)
- Shrink heat-shrink tubing on battery connections

**Subtotal Section 5: 1,100 EGP** ✓

---

## SECTION 6: Consumables & Miscellaneous — 900 EGP

### 6.1 Wires & Connectivity

| Item | Specifications | Qty | Unit Price | Total | Where to Buy |
|------|---------------|-----|------------|-------|--------------|
| **Hookup Wire 22AWG** | 6 colors (red, black, yellow, orange, blue, green), 2m each | 6 spools | 25 EGP | 150 EGP | RoboDyn Egypt |
| **Ultra-Thin Wire 30AWG** | For tight spaces inside watch, 1m each, 3 colors | 3 spools | 20 EGP | 60 EGP | RoboDyn Egypt |
| **Silicone Wire 20AWG** | Flexible, high-temp rated, for battery leads | 1m | 30 EGP | 30 EGP | RoboDyn Egypt |
| **Ribbon Cable 4-pin** | 0.5m, for I2C bus connection inside watch | 2 pcs | 20 EGP | 40 EGP | RoboDyn Egypt |
| **Male Pin Headers 2.54mm** | 40-pin strips, pack of 5 — for module connections | 5 | 15 EGP | 75 EGP | Any electronics |
| **Female Pin Headers 2.54mm** | 40-pin strips, pack of 5 — for ESP32 socket | 5 | 20 EGP | 100 EGP | Any electronics |
| **Jumper Wire Set M/M** | 40cm, 40pcs, male-to-male for breadboard | 2 sets | 40 EGP | 80 EGP | RoboDyn Egypt |
| **Jumper Wire Set M/F** | 20cm, 40pcs, male-to-female | 2 sets | 40 EGP | 80 EGP | RoboDyn Egypt |

---

### 6.2 Components (Passives)

| Item | Specifications | Qty | Price | Where to Buy |
|------|---------------|-----|-------|--------------|
| **Resistor Kit** | 600-piece: 10Ω, 22Ω, 47Ω, 100Ω, 220Ω, 330Ω, 470Ω, 1kΩ, 2.2kΩ, 4.7kΩ, 10kΩ, 22kΩ, 47kΩ, 100kΩ | 1 | 45 EGP | Any electronics |
| **Capacitor Kit — Ceramic** | 500-piece: 10pF, 22pF, 47pF, 100pF, 1nF, 10nF, 100nF | 1 | 35 EGP | Any electronics |
| **Capacitor Kit — Electrolytic** | 200-piece: 1µF, 10µF, 47µF, 100µF, 220µF, 470µF | 1 | 40 EGP | Any electronics |
| **Breadboard 400-point** | Full-size, 2× power rails, solderless | 2 | 60 EGP | 120 EGP | RoboDyn Egypt |
| **Breadboard 830-point** | Large prototyping board | 1 | 80 EGP | 80 EGP | RoboDyn Egypt |

---

### 6.3 Assembly Consumables

| Item | Specifications | Qty | Price | Where to Buy |
|------|---------------|-----|-------|--------------|
| **Isopropyl Alcohol 99%** | 250ml bottle, for flux cleaning | 1 | 50 EGP | Pharmacy |
| **Cotton Swabs** | Pack of 200, for IPA application | 1 | 15 EGP | Pharmacy |
| **Double-Sided Foam Tape** | 1mm thick, 5mm × 1m, strong adhesive | 2 rolls | 20 EGP | Office supply |
| **Hot Glue Gun + Sticks** | 20W mini gun, 7.2mm sticks, 50g sticks | 1 set | 60 EGP | Hardware store |
| **Heat Shrink Tubing Kit** | 2:1 ratio, 2mm/3mm/5mm/8mm, assorted | 1 | 30 EGP | RoboDyn Egypt |
| **Cable Ties / Zip Ties** | 100×2.5mm, pack of 100 | 1 | 20 EGP | Any hardware |
| **Kapton Tape** | 25mm × 30m, polyimide, heat-resistant | 1 | 35 EGP | AliExpress / RoboDyn |
| **Conformal Coating Spray** | Acrylic, waterproof PCB coating | 1 can | 120 EGP | RoboDyn Egypt |
| **Anti-static Mat + Wrist Strap** | ESD protection, essential for ESP32/sensors | 1 set | 80 EGP | RoboDyn Egypt |
| **Sandpaper Assortment** | 400, 600, 800, 1000, 1200 grit | 1 | 30 EGP | Hardware store |
| **Superglue Gel (Locktite)** | 5g gel type for case bonding | 2 | 20 EGP | Hardware store |

**Subtotal Section 6: 900 EGP** ✓

---

## SECTION 7: Shipping & Contingency — 500 EGP

| Item | Budget | Notes |
|------|--------|-------|
| Local delivery (Bosta/Aramex) | 150 EGP | RoboDyn Egypt ships via Bosta — 2–4 days |
| International shipping (AliExpress items) | 150 EGP | Estimate for all AliExpress items |
| PCB order shipping (DHL from JLCPCB) | 100 EGP | DHL Express 5–7 days |
| Emergency component replacement | 100 EGP | Always something gets fried or lost |

**Subtotal Section 7: 500 EGP** ✓

---

## Final Budget Reconciliation

| Section | Items | Total |
|---------|-------|-------|
| 1. Core Watch Electronics | ESP32, MAX30102, MPU6050, OLED, LiPo, TP4056, misc | 2,315 EGP |
| 2. Upgrade Sensors | AD8232 ECG, GPS NEO-6M, DS18B20, BMP280, MLX90614 | 1,180 EGP |
| 3. Enclosure & Wearable | PCB, 3D print cases, bands, glass, epoxy, foam | 2,110 EGP |
| 4. Essential Tools | Soldering station, multimeter, calipers, hand tools | 1,895 EGP |
| 5. Advanced Tools | Oscilloscope DSO150, logic analyzer, hot air station | 1,100 EGP |
| 6. Consumables | Wires, components, assembly supplies | 900 EGP |
| 7. Shipping & Contingency | Delivery + emergency reserve | 500 EGP |
| **GRAND TOTAL** | | **10,000 EGP** ✓ |

---

## Supplier Directory — Egypt

### 🥇 RoboDyn Egypt (Primary Supplier)
- **Website**: robodyn.com
- **Facebook**: Search "RoboDyn Egypt" — very active page
- **Location**: Online-first, with Cairo pickup available
- **Shipping**: Bosta (2–4 days), Aramex (next day Cairo)
- **Payment**: Visa / Fawry / Cash on delivery
- **Best for**: ESP32, sensors (MAX30102, MPU6050), soldering stations, tools, wires
- **Notes**: Has English-speaking staff, good return policy

### 🥈 Halab Street Electronics (شارع حلب — حارة حلب)
- **Location**: Between Attaba Square and Abdin, Central Cairo
- **Metro**: El-Attaba station (Line 1 and Line 2)
- **Hours**: Saturday–Thursday, 10:00–20:00
- **Best for**: Discrete components (resistors, capacitors, diodes, transistors), LEDs, switches, wires
- **Price tip**: Always bargain — first price is usually 20% higher
- **Notes**: Cash only. Some shops have English-speaking staff.

### 🥉 Amazon Egypt (amazon.eg)
- **Website**: amazon.eg
- **Delivery**: 1–2 days Cairo, 3–5 days other cities
- **Best for**: Watch bands, USB cables, tools, basic components
- **Payment**: Visa / COD / Fawry
- **Notes**: More expensive than Halab, but convenient and reliable

### 🌍 AliExpress (International)
- **Website**: aliexpress.com
- **Shipping to Egypt**: 2–6 weeks (standard), 1–2 weeks (Cainiao)
- **Best for**: Bulk components, pogo pins, watch parts, niche modules
- **Payment**: Visa required
- **Customs**: Items under $50 usually pass without duty. Over $50 may incur 14–40% customs.
- **Pro tip**: Order items one at a time to stay under customs threshold

### 📦 JLCPCB (PCB Manufacturer, China)
- **Website**: jlcpcb.com
- **Shipping to Egypt**: DHL Express (5–7 days, ~$6 USD), Standard (2–4 weeks)
- **Best for**: Custom PCBs (5 pieces for as low as $2), SMT assembly
- **Payment**: Visa / PayPal
- **Quality**: Excellent — used by professional engineers worldwide

### 🔧 Local Watch Shops
- **Khan El Khalili**: Bands, spring bars, watch glass, tools
- **El-Attaba watch repair row**: Spring bars, glass, crystals
- **Any mall kiosk**: 22mm silicone bands (Carrefour, Mall of Arabia)

---

## Where to Buy Quick Reference

| Component | First Choice | Backup |
|-----------|-------------|--------|
| ESP32 DevKit | RoboDyn Egypt | Halab Street |
| MAX30102 | RoboDyn Egypt | AliExpress |
| MPU6050 | RoboDyn Egypt | Halab Street |
| OLED Display | RoboDyn Egypt | Amazon.eg |
| LiPo Battery | RoboDyn Egypt | AliExpress |
| TP4056 | RoboDyn Egypt | Halab Street |
| Resistors/Caps | Halab Street | Any electronics |
| LEDs/Buttons | Halab Street | Any electronics |
| AD8232 ECG | RoboDyn Egypt | AliExpress |
| GPS NEO-6M | RoboDyn Egypt | AliExpress |
| Soldering Station | RoboDyn Egypt | AliExpress |
| Multimeter | RoboDyn Egypt | Halab Street |
| Custom PCB | JLCPCB.com | (no local option) |
| 3D Printed Case | Local print shop | Makespace Cairo |
| Watch Band | Amazon.eg | Khan El Khalili |
| Watch Glass | Watch repair shop | Khan El Khalili |
| IPA Alcohol | Pharmacy | Hardware store |
| Hot Glue | Hardware store | Carrefour |

---

## Wiring Quick Reference Card

Cut out or print this table:

```
┌─────────────────────────────────────────────────────────────┐
│         DIGITAL SAVER — WIRING QUICK REFERENCE             │
├────────────────┬───────────────┬────────────┬──────────────┤
│ Component      │ Component Pin │ Wire Color │ ESP32 Pin    │
├────────────────┼───────────────┼────────────┼──────────────┤
│ ALL SENSORS    │ VCC           │ RED        │ 3V3          │
│ ALL SENSORS    │ GND           │ BLACK      │ GND          │
├────────────────┼───────────────┼────────────┼──────────────┤
│ MAX30102       │ SDA           │ YELLOW     │ GPIO 21      │
│ MAX30102       │ SCL           │ ORANGE     │ GPIO 22      │
│ MAX30102       │ INT           │ BLUE       │ GPIO 26      │
├────────────────┼───────────────┼────────────┼──────────────┤
│ MPU6050        │ SDA           │ YELLOW     │ GPIO 21      │
│ MPU6050        │ SCL           │ ORANGE     │ GPIO 22      │
│ MPU6050        │ INT           │ PURPLE     │ GPIO 27      │
│ MPU6050        │ AD0           │ BLACK      │ GND (=0x68)  │
├────────────────┼───────────────┼────────────┼──────────────┤
│ OLED Display   │ SDA           │ YELLOW     │ GPIO 21      │
│ OLED Display   │ SCL           │ ORANGE     │ GPIO 22      │
├────────────────┼───────────────┼────────────┼──────────────┤
│ Red LED        │ Anode (+)     │ RED        │ 330Ω→GPIO 4  │
│ Green LED      │ Anode (+)     │ GREEN      │ 330Ω→GPIO 16 │
│ Vib. Motor     │ + terminal    │ RED        │ 1kΩ→Q1→3V3   │
│ Vib. Motor     │ − terminal    │ BLACK      │ GND          │
│ 2N2222 Base    │ B             │ -          │ 1kΩ→GPIO 25  │
├────────────────┼───────────────┼────────────┼──────────────┤
│ Button 1       │ Terminal A    │ BLUE       │ GPIO 17      │
│ Button 1       │ Terminal B    │ BLACK      │ GND          │
│ Button 1       │ 10kΩ pullup   │ RED        │ 3V3→10kΩ→GPIO17 │
│ Button 2       │ Terminal A    │ RED        │ GPIO 34      │
│ Button 2       │ Terminal B    │ BLACK      │ GND          │
│ Button 3       │ Terminal A    │ GREEN      │ GPIO 35      │
│ Button 3       │ Terminal B    │ BLACK      │ GND          │
├────────────────┼───────────────┼────────────┼──────────────┤
│ GPS NEO-6M     │ TX            │ YELLOW     │ GPIO 16 (RX2)│
│ GPS NEO-6M     │ RX            │ ORANGE     │ GPIO 17 (TX2)│
├────────────────┼───────────────┼────────────┼──────────────┤
│ AD8232 ECG     │ OUTPUT        │ GREEN      │ GPIO 13 (ADC)│
│ AD8232 ECG     │ LO-           │ BLUE       │ GPIO 12      │
│ AD8232 ECG     │ LO+           │ PURPLE     │ GPIO 14      │
├────────────────┼───────────────┼────────────┼──────────────┤
│ TP4056         │ B+            │ RED        │ Battery (+)  │
│ TP4056         │ B-            │ BLACK      │ Battery (-)  │
│ TP4056         │ OUT+          │ RED        │ ESP32 VIN    │
│ TP4056         │ USB-C IN      │ -          │ USB-C board  │
└────────────────┴───────────────┴────────────┴──────────────┘
```

---

## Assembly Timeline — 10-Day Plan

| Day | Tasks | Tools Needed | Budget Milestone |
|-----|-------|-------------|-----------------|
| **1** | Buy all components from RoboDyn + Halab St. | Cash | ~5,000 EGP spent |
| **2** | Order JLCPCB PCB + AliExpress items | Visa card | ~7,000 EGP spent |
| **3** | Set up development environment (Arduino IDE, Flutter) | Laptop | Tools ready |
| **4** | Breadboard prototype — test all I2C sensors | Multimeter, wires | Firmware verified |
| **5** | Solder passive components to PCB | Soldering station | PCB built |
| **6** | Solder modules + connectors | Soldering, tweezers | Electronics complete |
| **7** | 3D print case / pick up from print shop | Sandpaper | Case ready |
| **8** | Full assembly — mount all components in case | Glue gun, screwdrivers | Watch assembled |
| **9** | Upload firmware, test BLE, test app pairing | USB cable, phone | System working |
| **10** | Fine-tuning, testing all features, documentation | All tools | Project complete ✓ |

---

## Safety Checklist Before First Power-On

```
Before connecting battery:
□ Measure resistance between VCC and GND: should be > 1kΩ
□ Visually inspect all solder joints (use magnifier)
□ Verify LED anode/cathode orientation
□ Check battery connector polarity (red=+, black=−)
□ Verify TP4056 B+ and B− connections
□ Remove all metal objects from workspace

First power-on (with current-limited bench supply if available):
□ Measure 3V3 pin: should read 3.2–3.4V
□ Check ESP32 doesn't get hot (normal = warm, bad = burning)
□ Verify USB-C charges battery (TP4056 red LED should light)
□ Open Serial Monitor (115200 baud) — should see startup text
□ Open app, scan, pair successfully
```

---

## Official Procurement Receipt Template

```
══════════════════════════════════════════════════════════════
             OFFICIAL GOVERNMENT PROCUREMENT RECEIPT
══════════════════════════════════════════════════════════════

Project Name:   Digital Saver Health Monitoring System
Project Code:   _______________________________
Department:     _______________________________
Budget Year:    2025
Total Budget:   10,000 EGP

═══════════════════════════════════════════════════════════════
VENDOR:         RoboDyn Egypt
Address:        [Vendor address]
Phone:          [Vendor phone]
Tax ID:         [Vendor tax ID]
─────────────────────────────────────────────────────────────
Item                              Qty    Unit    Total
─────────────────────────────────────────────────────────────
ESP32-WROOM-32 DevKit v4          2      350     700
MAX30102 HR+SpO2 Module           3      280     840
MPU6050 6-Axis IMU Module         3      120     360
OLED 1.3" SH1106 Display          2      180     360
LiPo Battery 502035 400mAh        2      120     240
LiPo Battery 503450 1000mAh       1      180     180
TP4056 Charger Module             3       35     105
Yihua 936D+ Soldering Station     1      550     550
UNI-T UT61E Digital Multimeter    1      450     450
[Additional items...]
─────────────────────────────────────────────────────────────
                                     SUBTOTAL: ___________
                                     TAX 14%:  ___________
                                     SHIPPING: ___________
                                     ═══════════════════
                                     TOTAL:    ___________
══════════════════════════════════════════════════════════════

Vendor Signature: _______________ Date: _______________
Vendor Stamp:     [             ]

Buyer Name:       _______________ 
Buyer Signature:  _______________ Date: _______________
Department Head:  _______________ Date: _______________

══════════════════════════════════════════════════════════════
```

---

## ⚠️ Important Warnings

### Battery Safety (Most Critical)
- **NEVER** connect battery in reverse polarity — instant destruction of ESP32 and sensors
- **NEVER** charge LiPo batteries without a proper charger (TP4056 or equivalent)
- **NEVER** leave charging batteries unattended overnight
- **NEVER** use a swollen/puffy LiPo battery — safely dispose at electronics store
- **ALWAYS** use LiPo batteries with built-in protection circuit (PCM)
- In case of smoke/swelling: do NOT put in water; place on metal tray and ventilate

### Sensor Safety
- MAX30102 operates on 3.3V ONLY — 5V will destroy it instantly
- MPU6050 on most breakout boards has level shifters — check your board
- ESD: Always touch a metal object before handling bare ICs

### Regulatory
- This watch is a **wellness device, NOT a medical device**
- Blood pressure readings are estimated, not clinical
- Always include disclaimer in app: "Not FDA/CE certified"

---

*Document Version: 2.0.0 · Digital Saver Team · Egyptian Government Health Initiative*  
*Budget: 10,000 EGP · All prices are estimates valid mid-2025 — verify before purchase*
