# DIGITAL SAVER ONYX WATCH - FIRMWARE v3.1.0

> Version 3.1.0 - July 2026
> Includes: WiFi Internet, Weather, STEALTH Mode

---

# NEW FEATURES IN v3.1.0

## 1. WiFi & Internet Connection

The watch now connects to WiFi to get weather data from the internet!

### How It Works

```
Watch (ESP32) ----WiFi----> Router ----Internet----> Weather Server
                                    |
                                    v
                            OpenWeatherMap API
                            (api.openweathermap.org)
```

### Setup

Edit these lines in the firmware (DigitalSaverWatch.ino):

```cpp
// Line 67-70
#define WIFI_SSID "YourWiFiName"           // Your WiFi name
#define WIFI_PASSWORD "YourWiFiPassword"     // Your WiFi password
#define WEATHER_API_KEY "YOUR_API_KEY"     // Get from openweathermap.org
#define WEATHER_API_URL "http://api.openweathermap.org/data/2.5/weather"
```

### Get Weather API Key

1. Go to: https://openweathermap.org/api
2. Sign up (free tier = 1000 calls/day)
3. Copy your API key
4. Paste it in the code

### WiFi Status

| Status | Meaning |
|--------|---------|
| wifiConnected = true | WiFi is connected |
| wifiEnabled = true | WiFi is turned on |

### WiFi Commands (via BLE)

| Command | What It Does |
|---------|--------------|
| WIFI:ON | Turn on WiFi and connect |
| WIFI:OFF | Turn off WiFi |
| WEATHER:REFRESH | Fetch new weather data |

---

## 2. Weather Display

The watch shows weather on the screen!

### Weather Screen

```
+------------------------+
| SUN           [icon]   |  <- Weather condition
|                        |
|    32 C               |  <- Temperature
|                        |
| HUM: 65%  WIND: 5m/s  |  <- Humidity & wind
+------------------------+
```

### Weather Data Fields

| Field | Example | Description |
|-------|---------|-------------|
| temperature | 32.5 | Temperature in Celsius |
| humidity | 65 | Humidity percentage |
| condition | "Clear" | Weather condition |
| icon | "01d" | Icon code from API |
| windSpeed | 5 | Wind speed in m/s |
| updated | true | Has data been fetched |

### Weather Codes

| Code | Condition | Display |
|------|----------|---------|
| 01d, 01n | Clear | SUN |
| 02d, 02n | Few clouds | CLO |
| 03d, 03n | Clouds | CLO |
| 04d, 04n | Overcast | CLO |
| 09d, 09n | Rain | RAIN |
| 10d, 10n | Light rain | RAIN |
| 11d, 11n | Thunderstorm | STORM |
| 50d, 50n | Mist/Fog | FOG |

### Auto-Update

Weather updates every 30 minutes automatically:

```cpp
#define WEATHER_UPDATE_INTERVAL 1800000  // 30 minutes in milliseconds
```

---

## 3. STEALTH Mode (NEW!)

The watch looks like a normal analog watch!

### What Is STEALTH Mode?

In STEALTH mode, the watch shows ONLY:
- The time (large, plain digits)
- The date (small, at bottom)

NO:
- NO heart icons
- NO health stats
- NO weird symbols
- NO indication it's a smart watch

### Perfect For

- Business meetings
- Job interviews
- When you don't want people to know it's a smart watch
- Looking professional

### STEALTH Display

```
+------------------------+
|                        |
|                        |
|        12:45           |  <- JUST THE TIME (big digits)
|                        |
|                        |
|      Jul 27            |  <- Small date (looks like engraving)
+------------------------+
```

### Code For STEALTH Mode

```cpp
void showStealthDisplay() {
    // STEALTH MODE: Watch looks like a normal analog watch!
    // Shows ONLY time as regular digits, no health icons
    
    display.setTextSize(4);  // Big digits
    display.setCursor(8, 18);
    display.print(formatTime());  // Just show time!
    
    // Small date at bottom
    display.setTextSize(1);
    display.setCursor(25, 52);
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
        char dateStr[20];
        strftime(dateStr, sizeof(dateStr), "%b %d", &timeinfo);
        display.print(dateStr);
    }
    
    // Tiny BLE dot (barely visible)
    if (deviceConnected) {
        display.drawPixel(124, 2, SSD1306_WHITE);
    }
}
```

---

## 4. All Watch Modes

The watch has 8 modes:

| Mode ID | Mode Name | What It Shows |
|---------|-----------|---------------|
| 0 | MODE_CLOCK | Time, date, status |
| 1 | MODE_HEART_RATE | HR, SpO2, HRV |
| 2 | MODE_BLOOD_PRESSURE | Systolic, diastolic |
| 3 | MODE_ACTIVITY | Steps, calories |
| 4 | MODE_SLEEP | Sleep score |
| 5 | MODE_WEATHER | Temperature, humidity |
| 6 | MODE_STEALTH | Looks like normal watch! |
| 7 | MODE_SETTINGS | Settings |

---

## 5. All BLE Commands

### Mode Commands

| Command | Example | Response |
|---------|---------|----------|
| MODE:0 | MODE:0 | Switch to Clock |
| MODE:1 | MODE:1 | Switch to Heart Rate |
| MODE:2 | MODE:2 | Switch to Blood Pressure |
| MODE:3 | MODE:3 | Switch to Activity |
| MODE:4 | MODE:4 | Switch to Sleep |
| MODE:5 | MODE:5 | Switch to Weather |
| MODE:6 | MODE:6 | Switch to STEALTH |
| MODE:7 | MODE:7 | Switch to Settings |

### Theme Commands

| Command | Example | Result |
|---------|---------|--------|
| THEME:0 | THEME:0 | Default (white on black) |
| THEME:1 | THEME:1 | Inverted (black on white) |
| THEME:2 | THEME:2 | High Contrast |
| THEME:3 | THEME:3 | Night Mode (red) |
| THEME:4 | THEME:4 | Minimal (binary dots) |

### WiFi Commands

| Command | Example | Result |
|---------|---------|--------|
| WIFI:ON | WIFI:ON | Connect to WiFi |
| WIFI:OFF | WIFI:OFF | Disconnect WiFi |
| WEATHER:REFRESH | WEATHER:REFRESH | Get new weather |

### Status Commands

| Command | Example | Response |
|---------|---------|----------|
| PING | PING | PONG |
| STATUS | STATUS | THEME:0,MODE:0,BATT:85,WIFI:1 |

---

## 6. Code Structure

### File: DigitalSaverWatch.ino

```cpp
/***************************************************************************
 * SECTION 1: HEADER & INCLUDES
 * - Version info, libraries
 * NEW: Added WiFi.h, HTTPClient.h, ArduinoJson.h
 ***************************************************************************/

/***************************************************************************
 * SECTION 2: CONFIGURATION  
 * - WiFi settings (line 66-73)
 * - BLE UUIDs
 * - Sensor thresholds
 ***************************************************************************/

/***************************************************************************
 * SECTION 3: DATA STRUCTURES
 * - HealthData
 * - RawSensorData
 * - WeatherData (NEW!)
 ***************************************************************************/

/***************************************************************************
 * SECTION 4: STATE VARIABLES
 * - WatchMode currentMode
 * - WatchTheme currentTheme
 * - wifiConnected, wifiEnabled (NEW!)
 * - currentWeather (NEW!)
 ***************************************************************************/

/***************************************************************************
 * SECTION 5: WiFi & INTERNET FUNCTIONS (NEW!)
 * - initWiFi() - Connect to WiFi
 * - fetchWeather() - Get weather from API
 ***************************************************************************/

/***************************************************************************
 * SECTION 6: BLE FUNCTIONS
 * - initBLE()
 * - BLECommandCallbacks - handles all commands
 * NEW: WiFi commands, Weather refresh
 ***************************************************************************/

/***************************************************************************
 * SECTION 7: DISPLAY FUNCTIONS
 * - showClockDisplay()
 * - showHeartRateDisplay()
 * - showWeatherDisplay() (NEW!)
 * - showStealthDisplay() (NEW!)
 ***************************************************************************/

/***************************************************************************
 * SECTION 8: SENSOR FUNCTIONS
 * - readMAX30102()
 * - readMPU6050()
 * - calculateHeartRate()
 ***************************************************************************/
```

---

## 7. Libraries Needed

Update platformio.ini with these libraries:

```ini
[env:esp32dev]
platform = espressif32@6.4.0
board = esp32dev
framework = arduino

lib_deps = 
    ; Display
    adafruit/Adafruit GFX Library@^1.11.9
    adafruit/Adafruit SSD1306@^2.12.3
    
    ; Sensors
    sparkfun/SparkFun MAX3010x Pulse and Proximity Sensor Library@^1.1.2
    adafruit/Adafruit MPU6050@^2.2.6
    
    ; BLE
    h2zero/NimBLE-Arduino@^1.4.1
    
    ; WiFi & Internet (NEW!)
    WiFi
    HTTPClient
    ArduinoJson@^6.21.3
```

---

## 8. Android App (Google Play Store)

### App Name
**Digital Saver**

### Download
Available on Google Play Store: https://play.google.com/store/apps/details?id=com.cambric.digitalsaver

### App Features
- Connect to watch via BLE
- View health data from watch
- Change watch themes
- Change watch modes
- Receive emergency alerts
- View health history

### Minimum Requirements
- Android 8.0 (API 26) or higher
- Bluetooth 4.0 or higher
- GPS for location (for weather)

---

## 9. Troubleshooting

### WiFi Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Can't connect | Wrong password | Check WIFI_PASSWORD |
| Can't connect | Wrong SSID | Check WIFI_SSID |
| Weather shows "--" | No WiFi | Connect WiFi first |
| Weather shows "--" | Wrong API key | Check WEATHER_API_KEY |
| Weather old | Not updated | Send WEATHER:REFRESH |

### Weather Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Shows "?" | Unknown weather | API may be down |
| Shows "--" | WiFi not connected | Send WIFI:ON |
| Never updates | Update interval | Wait 30 min or send WEATHER:REFRESH |

### STEALTH Mode Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Still shows health | Wrong mode | Send MODE:6 |
| Shows too much | Theme issue | Send THEME:0 first |

---

## 10. Quick Reference

### Watch Modes (0-7)
```
0 = Clock
1 = Heart Rate  
2 = Blood Pressure
3 = Activity
4 = Sleep
5 = Weather
6 = STEALTH
7 = Settings
```

### Themes (0-4)
```
0 = Default (white on black)
1 = Inverted (black on white)
2 = High Contrast
3 = Night Mode (red)
4 = Minimal (dots)
```

### WiFi Commands
```
WIFI:ON        - Connect
WIFI:OFF       - Disconnect
WEATHER:REFRESH - Get new weather
```

### Important Lines In Code
```
Line 67:  #define WIFI_SSID
Line 68:  #define WIFI_PASSWORD
Line 69:  #define WEATHER_API_KEY
Line 70:  #define WEATHER_API_URL
Line 165: enum WatchMode (includes MODE_WEATHER, MODE_STEALTH)
Line 177: enum WatchTheme
Line 244: void showWeatherDisplay()
Line 245: void showStealthDisplay()
Line 469: void initWiFi()
Line 495: void fetchWeather()
```

---

## 11. Version History

| Version | Date | Changes |
|---------|------|---------|
| 3.1.0 | July 2026 | Added WiFi, Weather, STEALTH Mode! |
| 3.0.3 | July 2026 | Added 5 display themes |
| 3.0.0 | July 2026 | Major rewrite |
| 1.x | 2025 | Initial release |

---

# END OF DOCUMENT

Copyright 2026 Cambric. All Rights Reserved.
