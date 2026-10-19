# Digital Saver & Veyro: Developer & Operator Guide
*Practical Setup, Assembly, Flashing & Troubleshooting Manual*

---

## 1. Quickstart Checklist

Follow these steps to get your Digital Saver / Veyro development environment running from scratch:



---

## 2. Hardware Assembly & Bench Wiring

### 2.1 Prototype Bench Wiring Table (ESP32-WROOM-32)

| Component | Pin on Sensor/Display | Connected to ESP32 Pin | Notes |
| :--- | :--- | :--- | :--- |
| **SSD1306 OLED (128x64)** | VCC / GND | 3.3V / GND | I2C Address  |
| | SDA / SCL | GPIO 21 / GPIO 22 | 4.7k pull-up resistors recommended |
| **MAX30102 Pulse Oximeter** | VIN / GND | 3.3V / GND | Common 3.3V power rail |
| | SDA / SCL | GPIO 21 / GPIO 22 | Shared I2C bus |
| **MPU6050 6-DOF IMU** | VCC / GND | 3.3V / GND | I2C Address  |
| | SDA / SCL | GPIO 21 / GPIO 22 | Shared I2C bus |
| **Mode Button** | Pin 1 / Pin 2 | GPIO 17 / GND | Active Low (Internal Pullup) |
| **SOS Button** | Pin 1 / Pin 2 | GPIO 32 / GND | Active Low (Hold 2s for emergency trigger) |
| **Vibration Motor** | Gate / Base of Transistor | GPIO 25 | Drive through 2N2222 NPN or MOSFET with flyback diode |
| **Status LEDs** | Anodes (via 220R) | GPIO 4 (Red), GPIO 16 (Green) | Cathodes to GND |
| **Battery Voltage Divider** | Center junction | GPIO 34 (ADC1) | 100k to BAT+, 100k to GND (ADC input only) |

### 2.2 LiPo Safety Protocols
- **Always disconnect the battery** before plugging the ESP32 into a computer USB port.
- Never use a swollen, punctured, or overheating battery.
- Ensure the charging controller (TP4056 or BQ24074) is configured for the correct battery capacity (default charging current <= 0.5C).

---

## 3. Firmware Flashing & Verification

### 3.1 Flashing ESP32-S3 Flagship
1. Open terminal in .
2. Inspect  to ensure target environment matches your board revision.
3. Execute:
   
4. If upload fails to start, hold the board's **BOOT** button, tap **RESET**, and release **BOOT** once writing begins.
5. Launch the serial monitor:
   
   *Expected boot output:*
   

### 3.2 Flashing ESP32-WROOM Evaluation Prototype
1. Open terminal in .
2. Run:
   
3. Check the SSD1306 screen: it should display the Veyro logo, battery percentage, and live pulse oximeter prompts.

---

## 4. Mobile Companion App Setup & Testing

1. Navigate to the  directory:
   
2. Run on a physical Android or iOS device (Bluetooth cannot be tested inside standard desktop simulators without hardware pass-through):
   
3. **Permissions**:
   - Grant **Nearby Devices / Bluetooth Scan & Connect** permissions.
   - Grant **Location** permission (required by Android OS for BLE beacon scanning).
4. Tap **Scan for Devices** on the Dashboard:
   - Select your watch when "Veyro Watch" or "DigitalSaver" appears.
   - The app will automatically establish GATT connection, synchronize real-time clock, and start receiving live vitals.
5. **Testing Without Hardware**:
   - Enable **Demo Mode** in the app settings to test charts, sleep analysis, and Gemini AI health summaries using realistic synthetic data streams.

---

## 5. Daily Development & Extension Recipes

### 5.1 How to Add a New Watchface (ESP32-S3)
1. Open  and increase the watchface enum count.
2. In , add your LVGL layout function:
   
3. Map the new index to the crown cycle handler in .
4. Update the companion app's  to expose the new face option in the mobile UI.

### 5.2 How to Tune Step Detection Sensitivity
1. Open  or .
2. Locate the acceleration threshold  (default: ~1.25g - 1.45g) and debounce timing ().
3. Adjust thresholds based on bench wrist-shaking tests.

---

## 6. Troubleshooting & Diagnostics

| Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| **Serial Upload Timeout** | USB cable is charge-only or wrong COM port | Use known-good data cable; verify port with . |
| **Screen is Blank** | Wrong I2C/SPI pins or missing backlight power | Check wiring: ESP32-S3 backlight GPIO 21 must be driven HIGH; check I2C address (). |
| **PPG=0 / Sensor Fail at Boot** | Missing 3.3V rail or I2C bus collision | Verify sensor voltage with multimeter; ensure pullup resistors are present on SDA/SCL. |
| **App Cannot Find Watch** | BLE permission denied or watch not advertising | Check Android BLE permissions in app settings; reboot watch to confirm advertising in serial monitor. |
| **Corrupted Flash / Boot Loop** | Corrupted LittleFS partition or bad flash write | Run  to wipe flash, then re-upload firmware and partition tables. |

---

## 7. Legal & Licensing Notice

This software and hardware documentation is released under the **Cambric Source-Available Commercial-Restricted License 1.0 (2026)**. You are free to inspect, evaluate, and modify this project for personal and educational purposes. Commercial manufacturing, sale, and distribution without explicit license from Cambric Software are strictly prohibited.
