# Onyx Watch Testing Procedures

## Pre-Testing Checklist

Before starting tests:
- [ ] All soldering complete
- [ ] No shorts between pins
- [ ] Battery connected properly
- [ ] USB-C cable tested
- [ ] Firmware uploaded

---

## Test 1: Power System

### 1.1 USB Power
**Objective:** Verify USB powers the ESP32

**Steps:**
1. Connect USB-C cable
2. Check ESP32 red LED turns on
3. Open Serial Monitor (115200 baud)
4. Verify boot messages appear

**Pass Criteria:** 
- ESP32 receives power
- Serial output shows boot messages

**Fail:** No LED, no serial output
- Check USB cable
- Check 3V3 rail with multimeter

---

### 1.2 Battery Charging
**Objective:** Verify battery charges via USB

**Steps:**
1. Connect fully discharged battery
2. Connect USB-C cable
3. Check TP4056 red LED (charging)
4. After ~2 hours, check green LED (done)

**Pass Criteria:**
- Red LED during charging
- Green LED when complete

**Fail:** No LED changes
- Check TP4056 B+ and B- connections
- Verify battery voltage (~3.7V)

---

### 1.3 Battery Power (No USB)
**Objective:** Verify battery powers ESP32 without USB

**Steps:**
1. Disconnect USB cable
2. ESP32 should continue running
3. Check Serial Monitor still active

**Pass Criteria:**
- ESP32 runs on battery

**Fail:** ESP32 resets
- Check battery voltage (>3.3V required)
- Check protection circuit

---

## Test 2: Display

### 2.1 I2C Communication
**Objective:** Verify display is detected

**Steps:**
1. Upload I2C Scanner sketch
2. Check Serial Monitor
3. Look for address 0x3C

**Pass Criteria:** "Found: 0x3C" appears

**Fail:** No address found
- Check SDA (GPIO 21) connection
- Check SCL (GPIO 22) connection
- Check 3V3/GND

---

### 2.2 Display Output
**Objective:** Verify display shows content

**Steps:**
1. Upload SSD1306 test sketch
2. Display should show text or graphics

**Pass Criteria:**
- Text/graphics visible on OLED

**Fail:** Screen blank
- Check VCC connection
- Try address 0x3D instead of 0x3C

---

### 2.3 Watch Face Display
**Objective:** Verify main watch face works

**Steps:**
1. Upload full firmware
2. Watch face should appear
3. Time should update

**Pass Criteria:**
- Time displayed
- Updates every second

---

## Test 3: Sensors

### 3.1 MAX30102 Heart Rate Sensor

#### Detection Test
**Steps:**
1. Upload I2C Scanner
2. Look for address 0x57

**Pass:** "Found: 0x57"

#### Heart Rate Test
**Steps:**
1. Upload heart rate sketch
2. Place finger firmly on sensor
3. Wait 10 seconds
4. Heart rate should appear

**Pass Criteria:**
- BPM between 40-180
- "Place finger" message disappears

**Fail:** Always shows "Place finger"
- Check finger placement
- Apply firm pressure
- Check INT connection

---

### 3.2 MPU6050 Accelerometer

#### Detection Test
**Steps:**
1. Upload I2C Scanner
2. Look for address 0x68

**Pass:** "Found: 0x68"

#### Motion Detection Test
**Steps:**
1. Upload accelerometer sketch
2. Move watch
3. Values should change

**Pass Criteria:**
- X/Y/Z values change with movement
- ~0, 0, 1 at rest (gravity)

---

### 3.3 Combined Sensor Test
**Steps:**
1. Upload full firmware
2. Check all sensors in display
3. Walk around - steps should increment

**Pass:** Steps increment with walking

---

## Test 4: LEDs

### 4.1 Red LED
**Steps:**
1. Upload LED test sketch
2. Red LED should blink

**Pass:** LED blinks

**Fail:** LED off or always on
- Check 220Ω resistor
- Check polarity (+ lead to resistor)

---

### 4.2 Green LED
**Steps:**
1. Upload LED test sketch
2. Green LED should blink

---

## Test 5: Buttons

### 5.1 Mode Button (GPIO 17)
**Steps:**
1. Press mode button
2. Screen should change

**Pass:** Screen advances

---

### 5.2 SOS Button (GPIO 34)
**Steps:**
1. Press and hold SOS button (3+ seconds)
2. Emergency mode activates

**Pass:** Emergency vibration/alert

---

### 5.3 Back Button (GPIO 35)
**Steps:**
1. Press back button
2. Should return to previous screen

---

## Test 6: BLE Communication

### 6.1 BLE Visibility
**Steps:**
1. Power on watch
2. Open Digital Saver app
3. Look for "Onyx-XXXX" device

**Pass:** Device appears in list

---

### 6.2 BLE Connection
**Steps:**
1. Tap on Onyx device
2. Connection should establish
3. Status shows "Connected"

**Pass:** Connection established

---

### 6.3 Data Sync
**Steps:**
1. With watch connected
2. Take heart rate reading
3. Data appears in app

**Pass:** Health data syncs

---

## Test 7: Emergency System

### 7.1 Manual SOS
**Steps:**
1. Press and hold SOS button 5+ seconds
2. Emergency sequence starts
3. Vibration pattern plays

**Pass:** 
- Vibration motor activates
- Serial shows "EMERGENCY SOS"
- App receives alert

---

### 7.2 Low Battery Alert
**Steps:**
1. Battery < 10%
2. Check LED behavior

**Pass:** Red LED flashes slowly

---

## Test 8: AI System

### 8.1 AI Initialization
**Steps:**
1. Check Serial Monitor during boot
2. Look for "[AI] Onyx Smart AI v8 initialized"

**Pass:** AI initialization message

---

### 8.2 Risk Score Display
**Steps:**
1. Navigate to AI screen
2. Check risk score (0-100%)

**Pass:** Risk score displayed

---

## Test 9: Complete Flow

### 9.1 Full Day Simulation
**Steps:**
1. Morning: Check heart rate
2. Day: Walk 10,000 steps
3. Night: Sleep tracking
4. Check all data in app

**Pass:** All data recorded

---

### 9.2 Emergency Simulation
**Steps:**
1. Place finger on sensor
2. Hold breath for 30 seconds
3. SpO2 drops
4. Alert triggers

**Pass:** Alert fires at low SpO2

---

## Test Log

Use this template for each test:

```
═══════════════════════════════════════════════════════
TEST: [Name]
DATE: [Date]
TECHNICIAN: [Name]

STEPS:
1. [Step 1]
2. [Step 2]
3. [Step 3]

EXPECTED: [What should happen]
ACTUAL: [What happened]

PASS: □
FAIL: □

NOTES:
─────────────────────────────────────────────────────
```

---

## Acceptance Criteria

### Must Pass (Critical)
- [ ] Power system works
- [ ] Display shows content
- [ ] Heart rate sensor works
- [ ] BLE connects
- [ ] SOS button triggers emergency

### Should Pass (Important)
- [ ] All buttons work
- [ ] Step counting accurate
- [ ] Data syncs to app
- [ ] Sleep tracking works

### Nice to Pass (Desirable)
- [ ] AI risk scoring works
- [ ] Battery life > 7 days
- [ ] All watch faces work
- [ ] Stealth mode works

---

## Report Template

```
DIGITAL SAVER ONYX - TEST REPORT
═══════════════════════════════════════════════════════

Unit ID: _______________
Build Date: ___________
Tester: _______________
Firmware Version: _______

SUMMARY
─────────────────────────────────────────────────────
Total Tests: ____
Passed: ____
Failed: ____
Pass Rate: ____%

CRITICAL ISSUES:
1. _________________________________________________
2. _________________________________________________

RECOMMENDATION: □ APPROVE  □ REJECT  □ REWORK

Signatures:
Tester: ____________  Date: _______
Reviewer: ____________  Date: _______
```

---

**Good luck with testing! 🧪**
