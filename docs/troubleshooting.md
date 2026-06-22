# Troubleshooting Guide - Digital Saver Smartwatch

## Common Issues and Solutions

### Watch Issues

#### Watch won't turn on
**Symptoms:**
- No display response
- No LED indicators

**Solutions:**
1. Charge the watch for at least 30 minutes
2. Check the charging cable and port
3. Try a different USB cable
4. Press and hold the button for 5 seconds
5. If still not working, check battery connection

#### Watch restarts randomly
**Symptoms:**
- Display flickers
- Watch reboots without warning

**Solutions:**
1. Check battery level - low battery can cause instability
2. Ensure battery is properly connected
3. Check for loose connections on PCB
4. Verify power supply provides stable 3.3V
5. Add a larger capacitor (100µF) near ESP32 power pins

---

### Sensor Issues

#### PPG sensor not reading
**Symptoms:**
- Heart rate shows "--" or "0"
- Irregular readings

**Solutions:**
1. Ensure sensor is in contact with skin
2. Wear watch snugly (but not too tight)
3. Clean sensor with soft cloth
4. Check I2C connection (run I2C scanner)
5. Verify MAX30102 address (0x57)
6. Try repositioning the watch

#### Inaccurate heart rate
**Symptoms:**
- BPM varies wildly
- Impossible values (200+ or 30-)

**Solutions:**
1. Wait 30 seconds for stable reading
2. Avoid movement during measurement
3. Ensure good skin contact
4. Clean sensor window
5. Check ambient light (direct sunlight affects PPG)

#### Accelerometer not working
**Symptoms:**
- Fall detection not triggering
- No motion data

**Solutions:**
1. Check I2C connection
2. Verify MPU6050 address (0x68)
3. Ensure proper initialization in code
4. Check interrupt pin connection (GPIO 34)

---

### Bluetooth Issues

#### Can't find watch in app
**Symptoms:**
- Watch doesn't appear in device list
- App says "Searching..."

**Solutions:**
1. Ensure watch is powered on and not in deep sleep
2. Move phone closer to watch
3. Enable Bluetooth on phone
4. Enable location permissions (required for BLE on Android)
5. Check if watch is already connected to another device
6. Restart Bluetooth on phone
7. Power cycle the watch

#### Watch disconnects frequently
**Symptoms:**
- Connection drops repeatedly
- "Disconnected" message

**Solutions:**
1. Move phone closer to watch
2. Minimize interference (other BLE devices, WiFi)
3. Reduce sensor sampling rate
4. Check battery level (low power affects BLE)
5. Update firmware to latest version
6. Check for obstacles between watch and phone

#### Connection but no data
**Symptoms:**
- Watch shows "Connected"
- App shows no readings

**Solutions:**
1. Ensure the correct service is selected
2. Check that notifications are enabled for the BLE characteristic
3. Restart the app
4. Re-pair the devices
5. Check for code errors in BLE handlers

---

### Display Issues

#### No display / Blank screen
**Symptoms:**
- Watch powers on but no display
- Screen is black

**Solutions:**
1. Check OLED connections (SDA=GPIO21, SCL=GPIO22)
2. Verify OLED address (0x3C)
3. Check 3.3V power to OLED
4. Try adjusting contrast in code
5. Run I2C scanner to verify OLED responds
6. Replace OLED module if faulty

#### Display flicker
**Symptoms:**
- Screen blinks or flashes

**Solutions:**
1. Check wire connections
2. Add pull-up resistors to I2C lines
3. Reduce I2C speed
4. Check for power supply issues
5. Add capacitor near display

---

### Alert Issues

#### Emergency alert not sending
**Symptoms:**
- Alert triggered but contacts not notified

**Solutions:**
1. Verify emergency contacts are configured
2. Check phone permissions (SMS, Phone, Location)
3. Ensure phone has cellular service
4. Check SMS inbox for blocked messages
5. Verify contact phone numbers are correct
6. Test SMS function manually

#### False fall detections
**Symptoms:**
- Alerts trigger during normal activity

**Solutions:**
1. Adjust fall detection threshold in code
2. Increase free-fall duration requirement
3. Add confirmation period before alert
4. Test with different movement patterns
5. Adjust MPU6050 sensitivity

#### No alert when should trigger
**Symptoms:**
- Anomaly detected but no alert

**Solutions:**
1. Check alert thresholds are configured
2. Verify alert functions are called correctly
3. Check BLE notification is enabled
4. Ensure battery is not critically low
5. Add debug output to track alert flow

---

### Battery Issues

#### Battery drains quickly
**Symptoms:**
- Watch only lasts a few hours
- Battery indicator drops rapidly

**Solutions:**
1. Reduce sensor sampling rate
2. Enable deep sleep when idle
3. Reduce display brightness
4. Disable unnecessary features
5. Check for software bugs causing high current draw
6. Verify no short circuits

#### Battery won't charge
**Symptoms:**
- Charger connected but no charging indicator
- Battery level doesn't increase

**Solutions:**
1. Check USB cable and power source
2. Verify TP4056 connections
3. Check battery voltage with multimeter
4. Try a different battery
5. Check for damaged charging port

---

### App Issues

#### App crashes on startup
**Symptoms:**
- App closes immediately
- Force close message

**Solutions:**
1. Update the app to latest version
2. Clear app cache and data
3. Restart the phone
4. Check for OS compatibility
5. Reinstall the app

#### App stuck on loading
**Symptoms:**
- App hangs at splash screen
- Progress indicator doesn't move

**Solutions:**
1. Check Bluetooth is enabled
2. Ensure location permission is granted
3. Restart the app
4. Check phone's BLE stack
5. Try reinstalling the app

---

### Build/Programming Issues

#### PlatformIO upload fails
**Symptoms:**
- Error during firmware upload
- "Failed to connect" message

**Solutions:**
1. Check USB cable supports data transfer
2. Hold BOOT button during upload
3. Install ESP32 board package
4. Select correct COM port
5. Update USB drivers
6. Try different USB port

#### Library compilation errors
**Symptoms:**
- Missing header files
- Undefined reference errors

**Solutions:**
1. Run `pio lib install` for all dependencies
2. Update platform and libraries
3. Clean build folder (`pio run --target clean`)
4. Verify library versions are compatible

---

## Diagnostic Checklist

Run through this checklist if experiencing issues:

### Power Check
- [ ] Battery voltage > 3.5V
- [ ] 3.3V rail stable
- [ ] No short circuits
- [ ] Power LED indicator on

### I2C Check
- [ ] I2C scanner finds all devices
- [ ] Pull-up resistors present
- [ ] No loose connections

### BLE Check
- [ ] Device advertises correctly
- [ ] Phone discovers device
- [ ] Connection establishes
- [ ] Data transmits

### Sensor Check
- [ ] MAX30102 LED visible glow
- [ ] MPU6050 returns stable values
- [ ] PPG readings are reasonable

### Alert Check
- [ ] Thresholds configured
- [ ] Contacts saved
- [ ] Phone permissions granted
- [ ] SMS/Call function works

---

## Debug Mode

Enable debug output in the firmware:

```cpp
// In platformio.ini or Arduino setup
Serial.begin(115200);
Serial.println("Debug Mode Enabled");
```

Monitor output with:
```bash
pio device monitor
# or
screen /dev/ttyUSB0 115200
```

---

## Getting Help

If issues persist:

1. **Check existing issues** on GitHub
2. **Create a new issue** with:
   - Description of problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Error messages (if any)
   - Code changes (if any)
   - Hardware details

3. **Community support**:
   - Open a discussion on GitHub
   - Check documentation updates

---

## Known Limitations

1. **Blood Pressure**: PPG-based estimation has ±15-20 mmHg accuracy. For clinical use, a calibrated medical device is required.

2. **Heart Rate**: Accuracy may decrease during high-motion activities.

3. **Fall Detection**: May not detect all falls. Test thoroughly before relying on this feature.

4. **Battery Life**: Actual battery life varies based on usage patterns and environmental conditions.

5. **BLE Range**: Maximum range ~10m. Walls and obstacles reduce range.

---

**Last Updated**: 2024
**Version**: 1.0.0
