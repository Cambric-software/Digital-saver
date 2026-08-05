/*
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                    DIGITAL SAVER ONYX SMARTWATCH                         ║
 * ║                         MAIN FIRMWARE v1.0                              ║
 * ║                                                                          ║
 * ║  © 2026 Cambric. All Rights Reserved.                                   ║
 * ║  Egyptian Government Funded Project - Digital Egypt Initiative           ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 * 
 * Features:
 * - Real-time Heart Rate Monitoring (MAX30102)
 * - Blood Oxygen (SpO2) Detection
 * - Blood Pressure Estimation (PTT Method)
 * - Fall & LOC Detection (MPU6050)
 * - Activity Tracking (Steps, Calories, Distance)
 * - Sleep Quality Analysis
 * - Emergency SMS & Call Alerts
 * - BLE Communication with Mobile App
 * - Smart AI (8x Enhanced On-Device)
 * - OLED Display (SSD1306 128x64)
 * 
 * Hardware:
 * - ESP32-WROOM-32 (240MHz, 4MB Flash, 520KB SRAM)
 * - MAX30102 Heart Rate + SpO2 Sensor
 * - MPU6050 6-Axis Accelerometer
 * - SSD1306 OLED Display 0.96"
 * - 350mAh LiPo Battery
 * 
 * Author: Cambric Development Team
 * License: MIT
 */

// ═══════════════════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════════════════

#include <Arduino.h>
#include <Wire.h>
#include <SPI.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>
#include <esp_sleep.h>
#include <driver/rtc_io.h>

// Sensors
#include "sensors/MAX30102_sensor.h"
#include "sensors/MPU6050_sensor.h"
#include "sensors/Battery_sensor.h"

// BLE Communication
#include "ble/BLECommunication.h"

// Display
#include "display/SSD1306_display.h"
#include "display/WatchFaces.h"
#include "display/HealthScreens.h"

// Emergency System
#include "emergency/EmergencySystem.h"
#include "emergency/FallDetector.h"
#include "emergency/SOSHandler.h"

// Smart AI (8x Enhanced)
#include "ai/OnyxSmartAI.h"
#include "ai/HealthPredictor.h"
#include "ai/PatternAnalyzer.h"

// Utilities
#include "utils/ConfigManager.h"
#include "utils/HealthCalculations.h"
#include "utils/SleepTracker.h"
#include "utils/ActivityTracker.h"

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL CONFIGURATION
// ═══════════════════════════════════════════════════════════════════════════

#define FIRMWARE_VERSION "1.0.0"
#define BUILD_DATE __DATE__

// Pin Definitions
namespace Pins {
    // I2C
    constexpr int I2C_SDA = 21;
    constexpr int I2C_SCL = 22;
    
    // Sensors
    constexpr int MAX30102_INT = 25;
    constexpr int MPU6050_INT = 27;
    
    // LEDs
    constexpr int LED_RED = 4;
    constexpr int LED_GREEN = 16;
    
    // Buttons
    constexpr int BUTTON_MODE = 17;
    constexpr int BUTTON_SOS = 34;
    constexpr int BUTTON_BACK = 35;
    
    // Power
    constexpr int BATTERY_ADC = 33;
    constexpr int CHARGE_STATUS = 32;
}

// Timing
namespace Timing {
    constexpr unsigned long MAIN_LOOP_INTERVAL = 100;      // 100ms
    constexpr unsigned long SENSOR_READ_INTERVAL = 1000;    // 1s
    constexpr unsigned long DISPLAY_UPDATE_INTERVAL = 100;   // 100ms
    constexpr unsigned long BLE_SEND_INTERVAL = 5000;       // 5s
    constexpr unsigned long AI_UPDATE_INTERVAL = 1000;       // 1s
    constexpr unsigned long SLEEP_CHECK_INTERVAL = 30000;    // 30s
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL OBJECTS
// ═══════════════════════════════════════════════════════════════════════════

// Sensors
MAX30102Sensor heartSensor;
MPU6050Sensor motionSensor;
BatterySensor batterySensor;

// Communication
BLECommunication ble;
SSD1306Display display;
WatchFaces watchFaces;
HealthScreens healthScreens;

// Emergency
EmergencySystem emergencySystem;
FallDetector fallDetector;
SOSHandler sosHandler;

// Smart AI (8x Enhanced)
OnyxSmartAI smartAI;
HealthPredictor healthPredictor;
PatternAnalyzer patternAnalyzer;

// Utilities
ConfigManager config;
HealthCalculations healthCalc;
SleepTracker sleepTracker;
ActivityTracker activityTracker;

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL STATE
// ═══════════════════════════════════════════════════════════════════════════

namespace State {
    // System State
    bool isInitialized = false;
    bool isSleepMode = false;
    bool isStealthMode = false;
    unsigned long lastActivityTime = 0;
    
    // Current Screen
    int currentScreen = 0;
    int totalScreens = 8;
    
    // User Profile (loaded from flash)
    struct UserProfile {
        char name[30] = "User";
        int age = 30;
        int weightKg = 70;
        int heightCm = 170;
        char gender = 'M';
        char bloodType[4] = "O+";
        bool hasHeartCondition = false;
        bool hasDiabetes = false;
        bool hasHypertension = false;
        bool hasAsthma = false;
        bool hasAllergies[10] = {false};
        char emergencyContactName[50] = "";
        char emergencyContactPhone[20] = "";
    } userProfile;
    
    // Current Health Data
    struct HealthData {
        int heartRate = 0;
        int spO2 = 0;
        int hrv = 0;  // RMSSD in ms
        int sdnn = 0;
        int pnn50 = 0;
        int systolic = 0;
        int diastolic = 0;
        int confidence = 0;
        bool irregularBeat = false;
        bool lowOxygen = false;
        unsigned long lastUpdate = 0;
    } currentHealth;
    
    // Activity Data
    struct ActivityData {
        int steps = 0;
        int goalSteps = 10000;
        float calories = 0;
        float distanceKm = 0;
        int activeMinutes = 0;
        unsigned long lastStepTime = 0;
    } currentActivity;
    
    // Battery
    struct BatteryInfo {
        int percentage = 100;
        bool isCharging = false;
        unsigned long lastUpdate = 0;
    } battery;
    
    // Time
    struct TimeInfo {
        int hour = 0;
        int minute = 0;
        int second = 0;
        int day = 1;
        int month = 1;
        int year = 2026;
    } timeInfo;
}

// ═══════════════════════════════════════════════════════════════════════════
// FUNCTION PROTOTYPES
// ═══════════════════════════════════════════════════════════════════════════

void initializeSystem();
void initializeSensors();
void initializeBLE();
void initializeDisplay();
void initializeAI();
void initializeStorage();

void mainLoop();
void readSensors();
void updateAI();
void updateDisplay();
void sendBLEData();
void checkSleepMode();
void handleButtons();
void handleEmergency();

void loadUserProfile();
void saveUserProfile();
void updateBatteryStatus();

void enterSleepMode();
void exitSleepMode();

// Screen navigation
void nextScreen();
void previousScreen();
void showScreen(int screenIndex);

// ═══════════════════════════════════════════════════════════════════════════
// SETUP FUNCTION
// ═══════════════════════════════════════════════════════════════════════════

void setup() {
    Serial.begin(115200);
    Serial.println();
    Serial.println("╔═══════════════════════════════════════════════════════════╗");
    Serial.println("║        DIGITAL SAVER ONYX SMARTWATCH v" FIRMWARE_VERSION "          ║");
    Serial.println("║             © 2026 Cambric - Digital Egypt               ║");
    Serial.println("╚═══════════════════════════════════════════════════════════╝");
    
    // Initialize Wire (I2C)
    Wire.begin(Pins::I2C_SDA, Pins::I2C_SCL);
    Wire.setClock(400000); // 400kHz Fast Mode
    
    // Initialize all systems
    initializeSystem();
    
    Serial.println("[MAIN] Setup complete!");
    Serial.printf("[MAIN] Free heap: %d bytes\n", ESP.getFreeHeap());
}

void initializeSystem() {
    Serial.println("[INIT] Starting system initialization...");
    
    // Initialize GPIO pins
    pinMode(Pins::LED_RED, OUTPUT);
    pinMode(Pins::LED_GREEN, OUTPUT);
    pinMode(Pins::BUTTON_MODE, INPUT_PULLUP);
    pinMode(Pins::BUTTON_SOS, INPUT_PULLUP);
    pinMode(Pins::BUTTON_BACK, INPUT_PULLUP);
    
    // LEDs off initially
    digitalWrite(Pins::LED_RED, LOW);
    digitalWrite(Pins::LED_GREEN, LOW);
    
    // Initialize storage
    initializeStorage();
    
    // Initialize sensors
    initializeSensors();
    
    // Initialize display
    initializeDisplay();
    
    // Initialize BLE
    initializeBLE();
    
    // Initialize AI
    initializeAI();
    
    // Load user profile
    loadUserProfile();
    
    // Configure AI with user data
    smartAI.setUserProfile(
        State::userProfile.age,
        State::userProfile.weightKg,
        State::userProfile.heightCm,
        State::userProfile.gender,
        State::userProfile.bloodType
    );
    smartAI.setMedicalConditions(
        State::userProfile.hasHeartCondition,
        State::userProfile.hasDiabetes,
        State::userProfile.hasHypertension,
        State::userProfile.hasAsthma
    );
    
    // Emergency system
    emergencySystem.begin(
        State::userProfile.emergencyContactName,
        State::userProfile.emergencyContactPhone
    );
    
    State::isInitialized = true;
    Serial.println("[INIT] System initialization complete!");
}

void initializeSensors() {
    Serial.println("[INIT] Initializing sensors...");
    
    // Initialize MAX30102 Heart Rate Sensor
    if (heartSensor.begin()) {
        Serial.println("[INIT] MAX30102 initialized successfully");
        heartSensor.configure(
            60,    // LED brightness
            4,     // Sample average
            2,     // LED mode (Red + IR)
            400,   // Sample rate
            69,    // Pulse width
            4096   // ADC range
        );
    } else {
        Serial.println("[ERROR] MAX30102 not found!");
        // Continue anyway - might be in simulation mode
    }
    
    // Initialize MPU6050 Accelerometer
    if (motionSensor.begin()) {
        Serial.println("[INIT] MPU6050 initialized successfully");
        motionSensor.configure(
            MPU6050_RANGE_8G,      // Accelerometer range
            MPU6050_RANGE_500_DEG,  // Gyro range
            MPU6050_BAND_21_HZ      // Filter bandwidth
        );
    } else {
        Serial.println("[ERROR] MPU6050 not found!");
    }
    
    // Initialize battery monitoring
    batterySensor.begin(Pins::BATTERY_ADC, Pins::CHARGE_STATUS);
    
    Serial.println("[INIT] All sensors initialized");
}

void initializeBLE() {
    Serial.println("[INIT] Initializing BLE...");
    ble.begin("Onyx-" + String((uint32_t)ESP.getEfuseMAC()));
    Serial.println("[INIT] BLE initialized");
}

void initializeDisplay() {
    Serial.println("[INIT] Initializing display...");
    if (display.begin()) {
        Serial.println("[INIT] Display initialized");
        display.clear();
        display.showLogo();
        delay(1500);
    } else {
        Serial.println("[ERROR] Display not found!");
    }
}

void initializeAI() {
    Serial.println("[INIT] Initializing Smart AI (8x Enhanced)...");
    smartAI.begin();
    healthPredictor.begin();
    patternAnalyzer.begin();
    Serial.println("[INIT] Smart AI ready");
}

void initializeStorage() {
    Serial.println("[INIT] Initializing storage...");
    config.begin();
    Serial.println("[INIT] Storage initialized");
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN LOOP
// ═══════════════════════════════════════════════════════════════════════════

unsigned long lastSensorRead = 0;
unsigned long lastDisplayUpdate = 0;
unsigned long lastBLESend = 0;
unsigned long lastAIUpdate = 0;
unsigned long lastSleepCheck = 0;

void loop() {
    unsigned long now = millis();
    
    // Guard: don't run if not initialized
    if (!State::isInitialized) {
        delay(100);
        return;
    }
    
    // Main loop timing
    if (now - lastSensorRead >= Timing::SENSOR_READ_INTERVAL) {
        lastSensorRead = now;
        readSensors();
        handleEmergency();
    }
    
    // AI Analysis
    if (now - lastAIUpdate >= Timing::AI_UPDATE_INTERVAL) {
        lastAIUpdate = now;
        updateAI();
    }
    
    // Display Update
    if (now - lastDisplayUpdate >= Timing::DISPLAY_UPDATE_INTERVAL) {
        lastDisplayUpdate = now;
        updateDisplay();
    }
    
    // BLE Data Send
    if (now - lastBLESend >= Timing::BLE_SEND_INTERVAL) {
        lastBLESend = now;
        sendBLEData();
    }
    
    // Sleep Mode Check
    if (now - lastSleepCheck >= Timing::SLEEP_CHECK_INTERVAL) {
        lastSleepCheck = now;
        checkSleepMode();
    }
    
    // Button Handling
    handleButtons();
    
    // Small delay to prevent watchdog
    delay(10);
}

// ═══════════════════════════════════════════════════════════════════════════
// SENSOR READING
// ═══════════════════════════════════════════════════════════════════════════

void readSensors() {
    // Read heart rate and SpO2
    heartSensor.update();
    State::currentHealth.heartRate = heartSensor.getHeartRate();
    State::currentHealth.spO2 = heartSensor.getSpO2();
    State::currentHealth.hrv = heartSensor.getHRV();
    State::currentHealth.confidence = heartSensor.getConfidence();
    State::currentHealth.irregularBeat = heartSensor.isIrregularBeat();
    State::currentHealth.lastUpdate = millis();
    
    // Read motion (for fall detection and activity)
    motionSensor.update();
    
    // Activity tracking
    activityTracker.update(
        motionSensor.getAccelerationMagnitude(),
        State::currentHealth.heartRate,
        millis()
    );
    State::currentActivity.steps = activityTracker.getSteps();
    State::currentActivity.calories = activityTracker.getCalories(
        State::userProfile.weightKg,
        State::userProfile.heightCm
    );
    State::currentActivity.distanceKm = activityTracker.getDistanceKm(State::userProfile.heightCm);
    
    // Fall detection
    if (fallDetector.update(
        motionSensor.getAccelerationX(),
        motionSensor.getAccelerationY(),
        motionSensor.getAccelerationZ(),
        motionSensor.getGyroX(),
        motionSensor.getGyroY(),
        motionSensor.getGyroZ()
    )) {
        Serial.println("[ALERT] Fall detected!");
        emergencySystem.triggerFallAlert(
            State::currentHealth.heartRate,
            State::currentHealth.spO2,
            activityTracker.getSteps()
        );
    }
    
    // Blood pressure estimation (PTT method)
    if (State::currentHealth.heartRate > 50 && State::currentHealth.hrv > 0) {
        auto bp = healthCalc.estimateBloodPressure(
            State::currentHealth.heartRate,
            State::currentHealth.hrv,
            State::userProfile.age,
            State::userProfile.hasHypertension
        );
        State::currentHealth.systolic = bp.systolic;
        State::currentHealth.diastolic = bp.diastolic;
    }
    
    // Low oxygen alert
    if (State::currentHealth.spO2 < 90) {
        State::currentHealth.lowOxygen = true;
        if (!State::isStealthMode) {
            digitalWrite(Pins::LED_RED, HIGH);
        }
    } else {
        State::currentHealth.lowOxygen = false;
    }
    
    // Update battery
    updateBatteryStatus();
    
    // Update time
    updateTimeInfo();
    
    State::lastActivityTime = millis();
}

void updateBatteryStatus() {
    batterySensor.update();
    State::battery.percentage = batterySensor.getPercentage();
    State::battery.isCharging = batterySensor.isCharging();
    State::battery.lastUpdate = millis();
    
    // Low battery warning
    if (State::battery.percentage < 10 && !State::battery.isCharging) {
        // Flash red LED
        digitalWrite(Pins::LED_RED, (millis() / 500) % 2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// AI PROCESSING (8X ENHANCED)
// ═══════════════════════════════════════════════════════════════════════════

void updateAI() {
    // Create current reading for AI
    HealthReading reading;
    reading.timestamp = millis();
    reading.heartRate = State::currentHealth.heartRate;
    reading.spO2 = State::currentHealth.spO2;
    reading.hrv = State::currentHealth.hrv;
    reading.accelerometerMagnitude = motionSensor.getAccelerationMagnitude();
    reading.irregularBeat = State::currentHealth.irregularBeat;
    
    // Run 8x AI analysis
    smartAI.analyze(reading);
    
    // Health prediction
    healthPredictor.update(
        reading,
        activityTracker.getDailyHistory(),
        sleepTracker.getWeeklyHistory()
    );
    
    // Pattern analysis
    patternAnalyzer.update(
        reading,
        smartAI.getCurrentPatterns(),
        smartAI.getRiskScore()
    );
    
    // Check if AI recommends alert
    if (smartAI.shouldAlert()) {
        int riskScore = smartAI.getRiskScore();
        Serial.printf("[AI] Alert recommendation: Risk %d%%\n", riskScore);
        
        if (riskScore > 85) {
            emergencySystem.triggerAIAlert(
                riskScore,
                smartAI.getActivePatterns(),
                State::currentHealth.heartRate,
                State::currentHealth.spO2
            );
        }
    }
    
    // Green LED shows good health
    if (smartAI.getRiskScore() < 30 && !State::isStealthMode) {
        digitalWrite(Pins::LED_GREEN, HIGH);
    } else {
        digitalWrite(Pins::LED_GREEN, LOW);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DISPLAY MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════

void updateDisplay() {
    if (State::isSleepMode) {
        // Minimal display in sleep mode
        return;
    }
    
    display.clear();
    
    switch (State::currentScreen) {
        case 0: // Watch Face
            watchFaces.showMainWatchFace(
                State::timeInfo.hour,
                State::timeInfo.minute,
                State::timeInfo.day,
                State::timeInfo.month,
                State::currentActivity.steps,
                State::currentActivity.goalSteps,
                State::battery.percentage,
                State::battery.isCharging
            );
            break;
            
        case 1: // Heart Rate
            healthScreens.showHeartRateScreen(
                State::currentHealth.heartRate,
                State::currentHealth.hrv,
                State::currentHealth.confidence,
                State::currentHealth.irregularBeat,
                smartAI.getRiskScore()
            );
            break;
            
        case 2: // SpO2
            healthScreens.showSpO2Screen(
                State::currentHealth.spO2,
                smartAI.getRiskScore()
            );
            break;
            
        case 3: // Blood Pressure
            healthScreens.showBloodPressureScreen(
                State::currentHealth.systolic,
                State::currentHealth.diastolic,
                healthCalc.getMAP(State::currentHealth.systolic, State::currentHealth.diastolic),
                smartAI.getRiskScore()
            );
            break;
            
        case 4: // Activity
            healthScreens.showActivityScreen(
                State::currentActivity.steps,
                State::currentActivity.goalSteps,
                State::currentActivity.calories,
                State::currentActivity.distanceKm,
                activityTracker.getActiveMinutes()
            );
            break;
            
        case 5: // Sleep
            healthScreens.showSleepScreen(
                sleepTracker.getLastNightHours(),
                sleepTracker.getQualityScore(),
                sleepTracker.getDeepSleepMinutes(),
                sleepTracker.getREMMINUTES()
            );
            break;
            
        case 6: // AI Dashboard
            healthScreens.showAIDashboard(
                smartAI.getRiskScore(),
                smartAI.getPatternCount(),
                smartAI.getActivePatterns(),
                healthPredictor.getNextPrediction()
            );
            break;
            
        case 7: // Settings
            healthScreens.showSettingsScreen(
                State::battery.percentage,
                smartAI.isEnabled(),
                State::isStealthMode
            );
            break;
    }
    
    display.update();
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN NAVIGATION
// ═══════════════════════════════════════════════════════════════════════════

void handleButtons() {
    static bool lastModeState = HIGH;
    static bool lastSOSState = HIGH;
    static bool lastBackState = HIGH;
    
    int modeState = digitalRead(Pins::BUTTON_MODE);
    int sosState = digitalRead(Pins::BUTTON_SOS);
    int backState = digitalRead(Pins::BUTTON_BACK);
    
    // Mode button - advance screen
    if (lastModeState == HIGH && modeState == LOW) {
        nextScreen();
        State::lastActivityTime = millis();
        if (!State::isSleepMode) exitSleepMode();
    }
    
    // SOS button - emergency
    if (lastSOSState == HIGH && sosState == LOW) {
        Serial.println("[SOS] Emergency triggered!");
        sosHandler.trigger();
        emergencySystem.triggerSOS(
            State::currentHealth.heartRate,
            State::currentHealth.spO2,
            activityTracker.getSteps()
        );
    }
    
    // Back button - previous screen
    if (lastBackState == HIGH && backState == LOW) {
        previousScreen();
        State::lastActivityTime = millis();
    }
    
    lastModeState = modeState;
    lastSOSState = sosState;
    lastBackState = backState;
}

void nextScreen() {
    State::currentScreen = (State::currentScreen + 1) % State::totalScreens;
    display.showTransition();
}

void previousScreen() {
    State::currentScreen = (State::currentScreen - 1 + State::totalScreens) % State::totalScreens;
    display.showTransition();
}

// ═══════════════════════════════════════════════════════════════════════════
// SLEEP MODE
// ═══════════════════════════════════════════════════════════════════════════

unsigned long sleepTimeout = 60000; // 1 minute default

void checkSleepMode() {
    unsigned long inactiveTime = millis() - State::lastActivityTime;
    
    // Enter sleep mode after inactivity
    if (!State::isSleepMode && inactiveTime > sleepTimeout) {
        enterSleepMode();
    }
    
    // Exit sleep mode on button press (handled in handleButtons)
}

void enterSleepMode() {
    if (State::isSleepMode) return;
    
    Serial.println("[SLEEP] Entering sleep mode");
    State::isSleepMode = true;
    
    // Dim the display
    display.setContrast(10);
    
    // Enable motion interrupt for wake-up
    motionSensor.enableWakeOnMotion();
    
    // Light sleep
    esp_sleep_enable_gpio_wakeup(GPIO_NUM_17, ESP_GPIO_WAKEUP_GPIO_HIGH);
    esp_deep_sleep_start();
}

void exitSleepMode() {
    if (!State::isSleepMode) return;
    
    Serial.println("[SLEEP] Exiting sleep mode");
    State::isSleepMode = false;
    
    // Restore display
    display.setContrast(255);
    
    // Disable motion interrupt
    motionSensor.disableWakeOnMotion();
    
    State::lastActivityTime = millis();
}

// ═══════════════════════════════════════════════════════════════════════════
// EMERGENCY HANDLING
// ═══════════════════════════════════════════════════════════════════════════

void handleEmergency() {
    // Check for critical conditions
    if (State::currentHealth.heartRate > 180 || State::currentHealth.heartRate < 40) {
        if (!State::isStealthMode) {
            digitalWrite(Pins::LED_RED, HIGH);
            // Vibration pattern
            // TODO: Add vibration motor control
        }
    }
    
    // SpO2 critical
    if (State::currentHealth.spO2 < 85) {
        emergencySystem.triggerLowOxygenAlert(State::currentHealth.spO2);
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// BLE COMMUNICATION
// ═══════════════════════════════════════════════════════════════════════════

void sendBLEData() {
    if (!ble.isConnected()) return;
    
    // Create BLE packet
    BLEDataPacket packet;
    packet.type = DATA_TYPE_HEALTH;
    packet.timestamp = millis();
    
    // Health data
    packet.heartRate = State::currentHealth.heartRate;
    packet.spO2 = State::currentHealth.spO2;
    packet.systolic = State::currentHealth.systolic;
    packet.diastolic = State::currentHealth.diastolic;
    packet.hrv = State::currentHealth.hrv;
    packet.confidence = State::currentHealth.confidence;
    
    // Activity
    packet.steps = State::currentActivity.steps;
    packet.calories = (uint16_t)State::currentActivity.calories;
    
    // AI
    packet.aiRiskScore = smartAI.getRiskScore();
    packet.aiPatternCount = smartAI.getPatternCount();
    
    // Battery
    packet.batteryLevel = State::battery.percentage;
    
    ble.sendPacket(packet);
}

// ═══════════════════════════════════════════════════════════════════════════
// STORAGE (FLASH/EEPROM)
// ═══════════════════════════════════════════════════════════════════════════

void loadUserProfile() {
    config.loadProfile(
        State::userProfile.name,
        &State::userProfile.age,
        &State::userProfile.weightKg,
        &State::userProfile.heightCm,
        &State::userProfile.gender,
        State::userProfile.bloodType,
        &State::userProfile.hasHeartCondition,
        &State::userProfile.hasDiabetes,
        &State::userProfile.hasHypertension,
        &State::userProfile.hasAsthma,
        State::userProfile.emergencyContactName,
        State::userProfile.emergencyContactPhone
    );
    
    // Load settings
    State::isStealthMode = config.getStealthMode();
    sleepTimeout = config.getSleepTimeout();
    
    Serial.printf("[PROFILE] Loaded: %s, Age: %d\n", State::userProfile.name, State::userProfile.age);
}

void saveUserProfile() {
    config.saveProfile(
        State::userProfile.name,
        State::userProfile.age,
        State::userProfile.weightKg,
        State::userProfile.heightCm,
        State::userProfile.gender,
        State::userProfile.bloodType,
        State::userProfile.hasHeartCondition,
        State::userProfile.hasDiabetes,
        State::userProfile.hasHypertension,
        State::userProfile.hasAsthma,
        State::userProfile.emergencyContactName,
        State::userProfile.emergencyContactPhone
    );
    
    config.setStealthMode(State::isStealthMode);
    config.setSleepTimeout(sleepTimeout);
    
    Serial.println("[PROFILE] Saved");
}

// ═══════════════════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

void updateTimeInfo() {
    time_t now = time(nullptr);
    struct tm* timeinfo = localtime(&now);
    
    State::timeInfo.hour = timeinfo->tm_hour;
    State::timeInfo.minute = timeinfo->tm_min;
    State::timeInfo.second = timeinfo->tm_sec;
    State::timeInfo.day = timeinfo->tm_mday;
    State::timeInfo.month = timeinfo->tm_mon + 1;
    State::timeInfo.year = timeinfo->tm_year + 1900;
}
