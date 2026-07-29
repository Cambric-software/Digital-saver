# DIGITAL SAVER ONYX WATCH - COMPLETE FIRMWARE DOCUMENTATION

**Version:** 3.2.0  
**Last Updated:** July 2026  
**Company:** Cambric

---

# TABLE OF CONTENTS

1. [What's New in v3.2.0](#whats-new-in-v320)
2. [User Profile System](#user-profile-system)
3. [Advanced Health AI Engine](#advanced-health-ai-engine)
4. [All Watch Modes](#all-watch-modes)
5. [All BLE Commands](#all-ble-commands)
6. [Code Structure](#code-structure)
7. [Settings Screen](#settings-screen)
8. [Troubleshooting](#troubleshooting)

---

# WHATS NEW IN V3.2.0

## v3.2.0 New Features

### 1. USER PROFILE SYSTEM (NEW!)
Set your personal information for personalized health tracking:
- Name, Age, Weight, Height, Gender
- Daily step goal, Sleep goal
- Custom max/min heart rate limits

### 2. ADVANCED HEALTH AI (NEW!)
Smart health analysis that runs on the watch:
- Overall Health Score (0-100)
- Cardiovascular Risk Assessment
- Arrhythmia Detection
- Hypoxia (Low Oxygen) Detection
- Stress Level Analysis
- Activity State Detection
- Calorie Burn Calculation
- Health Insights & Recommendations

### 3. Improved Settings Screen
Now shows:
- User Profile status
- Health AI scores
- Risk indicators
- Activity state
- Calories burned

---

# USER PROFILE SYSTEM

## What Is It?

The watch stores YOUR personal health information to give you better health analysis.

## UserProfile Data Structure

```cpp
struct UserProfile {
    String name;            // Your name
    int age;                // Your age in years
    int weightKg;          // Weight in kilograms
    int heightCm;          // Height in centimeters
    String gender;          // "male" or "female"
    int targetSteps;        // Daily step goal
    int targetSleepHours;   // Sleep goal (hours)
    float maxHeartRate;     // Your personal max HR
    float minHeartRate;     // Your personal min HR
    bool profileSet;        // Has profile been set?
};
```

## Set Profile via BLE

Send this command from the app:

```
PROFILE:name,age,weight,height,gender,steps
```

### Example

```
PROFILE:John,30,75,175,male,10000
```

### Breakdown
| Part | Value | Meaning |
|------|-------|---------|
| name | John | User's name |
| age | 30 | 30 years old |
| weight | 75 | 75 kg |
| height | 175 | 175 cm |
| gender | male | Male |
| steps | 10000 | 10,000 daily step goal |

### Response

Watch will respond with:
```
PROFILE:OK John 30y
```

## Auto-Calculated Values

When you set profile, the watch automatically calculates:

| Value | Formula | Example (age 30) |
|-------|---------|------------------|
| maxHeartRate | 220 - age | 190 BPM |
| minHeartRate | Fixed | 50 BPM |
| BMR | Mifflin-St Jeor | ~1750 kcal/day |

### BMR Calculation (Basal Metabolic Rate)

**For males:**
```
BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age + 5
```

**For females:**
```
BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
```

## Why Is Profile Important?

Without profile, watch uses generic values:
- Default BMR: 1500 kcal
- Default max HR: 180 BPM
- Default step goal: 10,000

With profile, the AI gives YOU personalized analysis!

---

# ADVANCED HEALTH AI ENGINE

## Overview

The watch now has a built-in AI that continuously analyzes your health data and provides:
- Health scores (0-100)
- Risk assessments
- Activity state detection
- Health insights
- Recommendations

## HealthAI Data Structure

```cpp
struct HealthAI {
    // Health Scores (0-100)
    float overallScore;      // Combined health score
    float heartScore;        // Heart health score
    float activityScore;      // Activity level score
    float sleepScore;        // Sleep quality score
    float stressScore;        // Stress level (0=no stress, 100=very stressed)
    
    // Risk Levels (0-4)
    // 0 = None, 1 = Low, 2 = Medium, 3 = High, 4 = Critical
    int cardiovascularRisk;   // Blood pressure risk
    int arrhythmiaRisk;       // Irregular heartbeat risk
    int hypoxiaRisk;         // Low oxygen risk
    int overexertionRisk;    // Too much exercise risk
    int dehydrationRisk;     // Dehydration risk
    
    // AI Insights
    String healthInsight;     // What's happening with your health
    String recommendation;   // What you should do
    String warningMessage;   // Alert if something is wrong!
    
    // Activity Detection
    String activityState;     // "SLEEPING", "RESTING", "WALKING", "EXERCISING", "INTENSE"
    
    // Calories
    float caloriesBurned;    // Total calories burned today
    float bmr;              // Basal Metabolic Rate
    float activeCalories;    // Calories from activity
    
    // Blood Pressure
    String bpCategory;       // "NORMAL", "ELEVATED", "HIGH_STAGE1", "HIGH_STAGE2", "CRISIS"
    
    // Fatigue
    float fatigueLevel;     // 0-100 (0=energized, 100=exhausted)
    int recoveryMinutes;     // Minutes until recovered
};
```

## How The AI Works

The AI runs `runHealthAI()` every measurement cycle and performs these analyses:

### 1. Blood Pressure Analysis

| Category | Systolic | Diastolic | Risk Level |
|----------|----------|-----------|------------|
| NORMAL | < 120 | < 80 | 0 (None) |
| ELEVATED | 120-129 | < 80 | 1 (Low) |
| HIGH_STAGE1 | 130-139 | 80-89 | 2 (Medium) |
| HIGH_STAGE2 | >= 140 | >= 90 | 3 (High) |
| CRISIS | > 180 | > 120 | 4 (Critical) |

### 2. Arrhythmia Detection

The AI watches for irregular heart rate patterns:
- If HR changes by more than 30 BPM suddenly
- If this happens 3+ times
- **Warning:** "POSSIBLE ARRHYTHMIA DETECTED!"

### 3. Hypoxia Detection (Low Blood Oxygen)

| SpO2 Level | Risk | Message |
|------------|------|---------|
| >= 96% | 0 | Normal |
| 94-95% | 2 | Medium |
| 90-93% | 3 | High |
| < 90% | 4 | **CRITICAL!** |

### 4. Overexertion Detection

Compares current HR to your max HR:
| HR vs Max | Risk |
|-----------|------|
| < 85% | 0 (Normal) |
| 85-95% | 2 (Medium) |
| 95-100% | 3 (High) |
| > 100% | 4 (CRITICAL) |

### 5. Activity State Detection

Based on heart rate and step rate:

| State | HR Range | Step Rate | Description |
|-------|----------|-----------|-------------|
| SLEEPING | < 60 BPM | Any | Resting/sleeping |
| RESTING | 60-80 BPM | < 5 spm | Sitting/relaxing |
| WALKING | 80-100 BPM | 5-30 spm | Light walking |
| EXERCISING | 100-140 BPM | 30-60 spm | Moderate exercise |
| INTENSE | >= 140 BPM | Any | Heavy exercise |
| ACTIVE | Any | > 60 spm | Very active |

### 6. Stress Level Detection

Based on HRV (Heart Rate Variability):

| HRV (RMSSD) | Stress Score | Level |
|-------------|--------------|-------|
| > 40ms | 20-50 | LOW |
| 20-40ms | 50-80 | MODERATE |
| < 20ms | 80-100 | HIGH |

### 7. Calorie Calculation

Based on activity state:

| Activity State | Calories Multiplier |
|----------------|---------------------|
| SLEEPING | 0.05 × BMR/1440 |
| RESTING | 0.1 × BMR/1440 |
| WALKING | 0.5 × BMR/1440 |
| EXERCISING | 1.0 × BMR/1440 |
| INTENSE | 1.5 × BMR/1440 |

## Overall Score Calculation

```
Overall = (HeartScore × 0.35) + 
          (ActivityScore × 0.25) + 
          ((100 - StressScore) × 0.20) + 
          (SpO2 × 0.20)
```

## Health Insights Generated

The AI generates these insights based on your current state:

| Condition | Insight | Recommendation |
|-----------|---------|----------------|
| BP Risk >= 3 | "High blood pressure detected" | "Reduce sodium, exercise more" |
| Arrhythmia >= 3 | "Irregular heartbeat pattern" | "Consider consulting cardiologist" |
| Hypoxia >= 3 | "Low blood oxygen levels" | "Deep breathing exercises recommended" |
| RESTING | "You're resting well" | "Time for a short walk?" |
| EXERCISING | "Great workout session!" | "Keep up the good pace" |
| Stress > 70 | "Elevated stress detected" | "Try deep breathing for 5 minutes" |
| Default | "All vitals looking good!" | "Stay hydrated and active" |

## AI Functions List

```cpp
void calculateBMR();           // Calculate basal metabolic rate
void analyzeBloodPressure();   // Categorize BP
void detectArrhythmia();       // Watch for irregular HR
void checkHypoxiaRisk();       // Check SpO2 levels
void checkOverexertionRisk(); // Check HR vs max
void calculateActivityState(); // Detect current activity
void generateHealthInsight();  // Create insight + recommendation
void runHealthAI();            // Main AI function (runs all above)
```

---

# ALL WATCH MODES

## Mode List (8 Modes)

| Mode ID | Name | Description |
|---------|------|-------------|
| 0 | MODE_CLOCK | Time, date, basic status |
| 1 | MODE_HEART_RATE | HR, SpO2, HRV display |
| 2 | MODE_BLOOD_PRESSURE | Systolic/Diastolic display |
| 3 | MODE_ACTIVITY | Steps, calories, activity |
| 4 | MODE_SLEEP | Sleep tracking display |
| 5 | MODE_WEATHER | Temperature, humidity, weather |
| 6 | MODE_STEALTH | Looks like normal watch |
| 7 | MODE_SETTINGS | Profile, Health AI, Status |

## Switch Modes via BLE

```
MODE:0  - Switch to Clock
MODE:1  - Switch to Heart Rate
MODE:2  - Switch to Blood Pressure
MODE:3  - Switch to Activity
MODE:4  - Switch to Sleep
MODE:5  - Switch to Weather
MODE:6  - Switch to STEALTH
MODE:7  - Switch to Settings
```

---

# ALL BLE COMMANDS

## Complete Command Reference

### Mode Commands
```
MODE:0         → Clock mode
MODE:1         → Heart rate mode
MODE:2         → Blood pressure mode
MODE:3         → Activity mode
MODE:4         → Sleep mode
MODE:5         → Weather mode
MODE:6         → STEALTH mode
MODE:7         → Settings mode
```

### Theme Commands
```
THEME:0         → Default (white on black)
THEME:1         → Inverted (black on white)
THEME:2         → High contrast
THEME:3         → Night mode (red)
THEME:4         → Minimal (binary dots)
```

### WiFi Commands
```
WIFI:ON          → Connect to WiFi
WIFI:OFF         → Disconnect WiFi
WEATHER:REFRESH  → Get new weather data
```

### Profile Commands (NEW!)
```
PROFILE:name,age,weight,height,gender,steps
                  → Set user profile
                  
Example: PROFILE:John,30,75,175,male,10000
```

### Health AI Commands (NEW!)
```
HEALTHAI:STATUS  → Get AI status
                  → Response: AI:85,CVD:0,ARR:0,HYP:0,STRESS:30,INSIGHT:All vitals looking good!
```

### Status Commands
```
PING            → Test connection (response: PONG)
STATUS          → Get full status
```

---

# CODE STRUCTURE

## File Organization

```
DigitalSaverWatch.ino
├── HEADER & INCLUDES
├── CONFIGURATION
│   ├── BLE Settings
│   ├── WiFi Settings (v3.1.0)
│   ├── Theme Settings
│   └── Mode Settings
├── DATA STRUCTURES
│   ├── HealthData
│   ├── RawSensorData
│   ├── WeatherData (v3.1.0)
│   ├── UserProfile (v3.2.0)
│   └── HealthAI (v3.2.0) ★ NEW!
├── STATE VARIABLES
│   ├── WatchMode
│   ├── WatchTheme
│   ├── HealthAI instance (v3.2.0)
│   └── UserProfile instance (v3.2.0)
├── SETUP FUNCTION
│   ├── initGPIO()
│   ├── initDisplay()
│   ├── initSensors()
│   ├── initBLE()
│   └── initWiFi() (v3.1.0)
├── MAIN LOOP
│   ├── handleButtonPress()
│   ├── Update sensors
│   ├── runHealthAI() (v3.2.0) ★ NEW!
│   ├── sendBLEData()
│   └── updateDisplay()
├── WiFi & Internet Functions (v3.1.0)
│   ├── initWiFi()
│   └── fetchWeather()
├── Health AI Functions (v3.2.0) ★ NEW!
│   ├── calculateBMR()
│   ├── analyzeBloodPressure()
│   ├── detectArrhythmia()
│   ├── checkHypoxiaRisk()
│   ├── checkOverexertionRisk()
│   ├── calculateActivityState()
│   ├── generateHealthInsight()
│   └── runHealthAI()
├── BLE Callbacks
│   ├── BLEServerCallbacks
│   └── BLECommandCallbacks (includes PROFILE, HEALTHAI commands)
├── Display Functions
│   ├── updateDisplay()
│   ├── showClockDisplay()
│   ├── showHeartRateDisplay()
│   ├── showBloodPressureDisplay()
│   ├── showActivityDisplay()
│   ├── showSleepDisplay()
│   ├── showWeatherDisplay() (v3.1.0)
│   ├── showStealthDisplay() (v3.1.0)
│   └── showSettingsDisplay() (v3.2.0) ★ UPDATED!
└── Utility Functions
    ├── formatTime()
    ├── formatDate()
    ├── vibrate()
    └── triggerEmergency()
```

## Key Line Numbers

| Function | Line | Version |
|----------|------|---------|
| Header | 1 | - |
| HealthAI struct | 181 | v3.2.0 |
| UserProfile struct | 157 | v3.2.0 |
| initWiFi() | 469 | v3.1.0 |
| fetchWeather() | 495 | v3.1.0 |
| calculateBMR() | 618 | v3.2.0 |
| analyzeBloodPressure() | 633 | v3.2.0 |
| detectArrhythmia() | 658 | v3.2.0 |
| checkHypoxiaRisk() | 732 | v3.2.0 |
| calculateActivityState() | 692 | v3.2.0 |
| generateHealthInsight() | 763 | v3.2.0 |
| runHealthAI() | 817 | v3.2.0 |
| showSettingsDisplay() | 1628 | v3.2.0 |

---

# SETTINGS SCREEN

## What It Shows

When you switch to MODE_SETTINGS (or press MODE button 7 times):

```
+------------------------------------------------+
| PROFILE:                                       |
| John | 30y | 75kg                             |
|                                                 |
| HEALTH AI SCORE:                               |
| Overall:85/100 | EXERCISING                   |
|                                                 |
| Risks:                                         |
| CVD:0 ARR:0 HYP:0                              |
|                                                 |
| State:WALKING CAL:285                         |
|                                                 |
| WiFi:ON BLE:ON v3.2.0                        |
+------------------------------------------------+
```

## If Profile Not Set

```
+------------------------------------------------+
| PROFILE:                                       |
| Not Set - Send PROFILE via BLE                 |
|                                                 |
| HEALTH AI SCORE:                               |
| Overall:78/100 | RESTING                      |
|                                                 |
| Risks:                                         |
| CVD:0 ARR:0 HYP:0                              |
|                                                 |
| State:RESTING CAL:142                          |
|                                                 |
| WiFi:OFF BLE:ON v3.2.0                        |
+------------------------------------------------+
```

---

# TROUBLESHOOTING

## Profile Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Profile not saved | Wrong format | Use: PROFILE:name,age,weight,height,gender,steps |
| Profile not working | Special chars | Use simple name like "John" not "John-Smith" |
| Age shows 0 | Wrong position | Check: PROFILE:Name,AGE,weight,height,gender,steps |

## Health AI Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| AI shows 0/100 | Profile not set | Set profile first |
| Wrong activity state | Sensor issue | Check MAX30102 |
| Risk always 0 | AI not running | Ensure runHealthAI() in loop |

## Settings Screen Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| No profile shown | Not set via BLE | Send PROFILE command |
| WiFi shows OFF | Not connected | Send WIFI:ON |

---

# VERSION HISTORY

| Version | Date | Major Changes |
|---------|------|--------------|
| 3.2.0 | July 2026 | **User Profile + Health AI** |
| 3.1.0 | July 2026 | WiFi, Weather, STEALTH Mode |
| 3.0.3 | July 2026 | 5 Display Themes |
| 3.0.0 | July 2026 | Major rewrite |
| 1.x | 2025 | Initial release |

---

# QUICK REFERENCE

## Watch Modes (0-7)
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

## Themes (0-4)
```
0 = Default
1 = Inverted
2 = High Contrast
3 = Night (Red)
4 = Minimal
```

## Risk Levels (0-4)
```
0 = None
1 = Low
2 = Medium
3 = High
4 = Critical
```

## Important Commands
```
PROFILE:John,30,75,175,male,10000    Set profile
HEALTHAI:STATUS                       Get AI status
MODE:7                                Go to Settings
```

---

# END OF DOCUMENT

Copyright 2026 Cambric. All Rights Reserved.
