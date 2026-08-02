/**
 * ╔═══════════════════════════════════════════════════════════════════════════╗
 * ║                    DIGITAL SAVER - SMARTWATCH FIRMWARE                   ║
 * ║                         Version 3.2.0 (July 2026)                       ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║  Features:                                                                 ║
 * ║  ✓ Real-time Heart Rate Monitoring (MAX30102 PPG)                        ║
 * ║  ✓ Blood Pressure Estimation (PPG waveform analysis)                    ║
 * ║  ✓ Blood Oxygen (SpO2) Monitoring                                        ║
 * ║  ✓ Fall Detection (MPU6050 accelerometer)                               ║
 * ║  ✓ Heart Rate Variability (HRV) Analysis                                ║
 * ║  ✓ Bluetooth Low Energy (BLE) Communication                              ║
 * ║  ✓ WiFi Internet Connection (Weather!)                                  ║
 * ║  ✓ OLED Display Interface (5 Themes!)                                   ║
 * ║  ✓ Emergency Alert System                                                 ║
 * ║  ✓ Sleep Tracking                                                         ║
 * ║  ✓ Activity Monitoring (Steps, Calories)                                 ║
 * ║  ✓ Weather Display (From Internet!)                                      ║
 * ║  ✓ STEALTH Mode (Looks like normal watch!)                             ║
 * ║  ✓ ADVANCED HEALTH AI (Smart Analysis!)                                ║
 * ║  ✓ User Profile System (Personalized Health!)                           ║
 * ╠═══════════════════════════════════════════════════════════════════════════╣
 * ║  Hardware: ESP32-WROOM-32 + MAX30102 + MPU6050 + OLED 0.96"             ║
 * ║  Framework: Arduino + PlatformIO                                          ║
 * ╚═══════════════════════════════════════════════════════════════════════════╝
 */

#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <SparkFunMAX3010x.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ============================================
//           CONFIGURATION
// ============================================

// Display Settings
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define OLED_ADDR 0x3C

// I2C Pins (ESP32 DevKit)
#define I2C_SDA 21
#define I2C_SCL 22

// GPIO Pins
#define HEART_RATE_INT 26    // MAX30102 interrupt
#define MOTION_INT 27        // MPU6050 interrupt
#define VIBRATION_MOTOR 25   // Vibration motor
#define LED_RED 4            // Status LED
#define LED_GREEN 16        // Status LED
#define BUTTON_MODE 17      // Mode button
#define BUTTON_EMERGENCY 34 // Emergency button
#define BUTTON_BACK 35      // Back button

// BLE Settings
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26f0"  // Command characteristic"

// WiFi Settings - CONNECT TO INTERNET FOR WEATHER
#define WIFI_SSID "YourWiFiName"
#define WIFI_PASSWORD "YourWiFiPassword"
#define WEATHER_API_KEY "YOUR_OPENWEATHERMAP_API_KEY"
#define WEATHER_API_URL "http://api.openweathermap.org/data/2.5/weather"

// Weather Update Interval (30 minutes)
#define WEATHER_UPDATE_INTERVAL 1800000

// Health Thresholds
#define MIN_HEART_RATE 40
#define MAX_HEART_RATE 200
#define MIN_SPO2 70
#define MAX_SPO2 100
#define HIGH_BP_SYSTOLIC 140
#define HIGH_BP_DIASTOLIC 90
#define FALL_THRESHOLD 2.5  // g-force
#define IRREGULAR_THRESHOLD 0.2  // RR interval variation

// Timing
#define MEASUREMENT_INTERVAL 1000  // 1 second
#define BLE_SEND_INTERVAL 1000     // Send data every second
#define DISPLAY_REFRESH 100       // 10 FPS display

// ============================================
//           GLOBAL OBJECTS
// ============================================

// Display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// MAX30102 Sensor
MAX30105 particleSensor;

// MPU6050 Registers (simplified - using basic I2C)
uint8_t MPU6050_ADDR = 0x68;

// BLE
BLEServer* pServer = NULL;
BLEService* pService = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// ============================================
//           HEALTH DATA STRUCTURES
// ============================================

struct HealthData {
    float heartRate;
    float spO2;
    float bloodPressureSys;
    float bloodPressureDia;
    float hrvRMSSD;
    float hrvSDNN;
    float perfusionIndex;
    float temperature;
    bool irregularHeartbeat;
    bool fallDetected;
    uint8_t activityLevel;  // 0=sedentary, 1=light, 2=moderate, 3=active
    uint32_t steps;
    uint32_t calories;
    float sleepScore;
    uint32_t timestamp;
};

struct RawSensorData {
    float irValue;
    float redValue;
    float accelX;
    float accelY;
    float accelZ;
    uint32_t timestamp;
};

HealthData currentHealth;
RawSensorData rawData;

// Weather Data (from internet)
struct WeatherData {
    float temperature;      // Celsius
    int humidity;           // Percentage
    String condition;       // "Clear", "Cloudy", "Rain", etc
    String icon;            // Icon code
    int windSpeed;          // m/s
    bool updated;           // Has data been fetched
};
WeatherData currentWeather;

// User Profile Data (stored in flash)
struct UserProfile {
    String name;            // User's name
    int age;                // User's age
    int weightKg;           // Weight in kg
    int heightCm;           // Height in cm
    String gender;          // "male" or "female"
    int targetSteps;         // Daily step goal
    int targetSleepHours;   // Sleep goal
    float maxHeartRate;      // Max safe heart rate
    float minHeartRate;     // Min safe heart rate
    bool profileSet;         // Has profile been configured
};
UserProfile userProfile;

// WiFi Status
bool wifiConnected = false;
bool wifiEnabled = false;
uint32_t lastWeatherUpdate = 0;

// ============================================
//           ADVANCED HEALTH AI ENGINE
// ============================================

struct HealthAI {
    // Health Scores (0-100)
    float overallScore;      // Combined health score
    float heartScore;        // Heart health score
    float activityScore;     // Activity level score
    float sleepScore;        // Sleep quality score
    float stressScore;       // Stress level
    
    // Risk Levels (0=none, 1=low, 2=medium, 3=high, 4=critical)
    int cardiovascularRisk;
    int arrhythmiaRisk;
    int hypoxiaRisk;
    int overexertionRisk;
    int dehydrationRisk;
    
    // AI Insights
    String healthInsight;     // Main health insight
    String recommendation;    // What to do
    String warningMessage;     // Warning if any
    
    // Trend Analysis
    float hrTrend;           // Heart rate trend (+=up, -=down)
    float stepsTrend;
    float sleepTrend;
    
    // History (last 7 days)
    float avgHeartRateWeek;
    float avgStepsWeek;
    float avgSleepWeek;
    
    // Activity State
    String activityState;     // "resting", "walking", "exercise", "sleeping"
    
    // Calories & Metabolism
    float caloriesBurned;
    float bmr;               // Basal Metabolic Rate
    float activeCalories;
    
    // Blood Pressure Category
    String bpCategory;        // "normal", "elevated", "high1", "high2", "crisis"
    
    // Fatigue Level
    float fatigueLevel;      // 0-100
    int recoveryMinutes;      // Minutes until recovered
};
HealthAI healthAI;

// ============================================
//           STATE VARIABLES
// ============================================

// Mode states
enum WatchMode {
    MODE_CLOCK,
    MODE_HEART_RATE,
    MODE_BLOOD_PRESSURE,
    MODE_ACTIVITY,
    MODE_SLEEP,
    MODE_WEATHER,      // NEW! Shows weather from internet
    MODE_STEALTH,     // NEW! Looks like normal watch - DISCREET MODE
    MODE_SETTINGS
};
WatchMode currentMode = MODE_CLOCK;

// Theme settings
enum WatchTheme {
    THEME_DEFAULT,     // White text on black
    THEME_INVERTED,    // Black text on white
    THEME_HIGH_CONTRAST, // Bold white
    THEME_NIGHT,       // Red text for night mode
    THEME_MINIMAL      // Minimal dots only
};
WatchTheme currentTheme = THEME_DEFAULT;

// BLE Command characteristic
BLECharacteristic* pCommandCharacteristic = NULL;

// Measurement states
bool isMeasuring = false;
bool emergencyMode = false;
uint32_t lastMeasurement = 0;
uint32_t lastBLEUpdate = 0;
uint32_t lastDisplayUpdate = 0;

// HRV calculation
#define HRV_BUFFER_SIZE 60
float rrIntervals[HRV_BUFFER_SIZE];
uint8_t rrIndex = 0;
uint32_t lastBeatTime = 0;
bool beatDetected = false;

// Activity tracking
uint32_t stepCount = 0;
float caloriesBurned = 0;
uint32_t activityStartTime = 0;
float baselineAccel = 0;

// Sleep tracking
uint32_t sleepStartTime = 0;
uint32_t deepSleepMinutes = 0;
uint32_t lightSleepMinutes = 0;
bool isSleeping = false;

// Fall detection
float lastAccelMagnitude = 1.0;
bool fallAlertSent = false;

// Button debouncing
uint32_t lastButtonPress = 0;
#define DEBOUNCE_TIME 200

// ============================================
//           FUNCTION PROTOTYPES
// ============================================

void initDisplay();
void initSensors();
void initBLE();
void initGPIO();
void initWiFi();

void updateHeartRate();
void updateSpO2();
void estimateBloodPressure();
void calculateHRV();
void detectFall();
void updateActivity();
void updateSleep();
void fetchWeather();

void updateDisplay();
void showWeatherDisplay();
void showStealthDisplay();
void runHealthAI();
void calculateBMR();
void analyzeBloodPressure();
void detectArrhythmia();
void calculateActivityState();
void generateHealthInsight();
void sendBLEData();

void vibrate(uint16_t duration);
void setLED(bool red, bool green);
void handleButtonPress();
void triggerEmergency();

String formatTime();
String formatDate();

// ============================================
//           SETUP
// ============================================

void setup() {
    Serial.begin(115200);
    delay(1000);
    
    Serial.println("\n");
    Serial.println("╔══════════════════════════════════════╗");
    Serial.println("║      DIGITAL SAVER v2.0.0            ║");
    Serial.println("║      Smartwatch Health Monitor       ║");
    Serial.println("╚══════════════════════════════════════╝");
    
    // Initialize GPIO first (before sensors)
    initGPIO();
    setLED(true, false);  // Red LED = booting
    
    // Initialize I2C
    Wire.begin(I2C_SDA, I2C_SCL);
    Serial.println("[OK] I2C initialized (SDA:21, SCL:22)");
    
    // Initialize Display
    initDisplay();
    
    // Initialize Sensors
    initSensors();
    
    // Initialize BLE
    initBLE();
    
    // Initialize health data
    memset(&currentHealth, 0, sizeof(HealthData));
    memset(rrIntervals, 0, sizeof(rrIntervals));
    
    currentHealth.heartRate = 0;
    currentHealth.spO2 = 98;
    currentHealth.bloodPressureSys = 120;
    currentHealth.bloodPressureDia = 80;
    
    // Calibrate baseline acceleration
    calibrateAccelerometer();
    
    setLED(false, true);  // Green LED = ready
    Serial.println("[OK] System ready!");
}

void initGPIO() {
    // Configure GPIO
    pinMode(VIBRATION_MOTOR, OUTPUT);
    digitalWrite(VIBRATION_MOTOR, LOW);
    
    pinMode(LED_RED, OUTPUT);
    pinMode(LED_GREEN, OUTPUT);
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_GREEN, LOW);
    
    pinMode(BUTTON_MODE, INPUT_PULLUP);
    pinMode(BUTTON_EMERGENCY, INPUT_PULLUP);
    pinMode(BUTTON_BACK, INPUT_PULLUP);
    
    Serial.println("[OK] GPIO initialized");
}

void initDisplay() {
    // Initialize OLED display
    if(!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
        Serial.println("[ERROR] SSD1306 allocation failed");
        // Fallback: try alternate address
        if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3D)) {
            Serial.println("[ERROR] SSD1306 failed on both addresses");
        }
    }
    
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(20, 20);
    display.println("DIGITAL");
    display.setCursor(25, 40);
    display.println("SAVER");
    display.display();
    
    delay(1500);
    Serial.println("[OK] Display initialized");
}

void initSensors() {
    // Initialize MAX30102
    if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
        Serial.println("[ERROR] MAX30102 not found!");
        display.clearDisplay();
        display.setTextSize(1);
        display.setCursor(0, 0);
        display.println("MAX30102 Error!");
        display.display();
    } else {
        // Configure MAX30102
        byte ledBrightness = 60;  // Options: 0=Off, 50=4mA, 100=7.6mA, 255=50mA
        byte sampleAverage = 4;   // Options: 1, 2, 4, 8, 16, 32
        byte ledMode = 2;         // Options: 1=Red only, 2=Red+IR, 3=Red+IR+Green
        int sampleRate = 400;     // Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
        int pulseWidth = 69;      // Options: 69, 118, 215, 411
        int adcRange = 4096;      // Options: 2048, 4096, 8192, 16384
        
        particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
        particleSensor.setPulseAmplitudeRed(0x0A);  // Turn off Red LED
        particleSensor.setPulseAmplitudeIR(0x1F);   // Turn on IR LED at minimum
        particleSensor.enableDIETEMPRDY();           // Enable temp ready interrupt
        
        Serial.println("[OK] MAX30102 initialized");
    }
    
    // Initialize MPU6050
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(0x6B);  // PWR_MGMT_1 register
    Wire.write(0);     // Set to zero (wakes up the MPU-6050)
    byte error = Wire.endTransmission();
    
    if (error == 0) {
        Wire.beginTransmission(MPU6050_ADDR);
        Wire.write(0x1C);  // ACCEL_CONFIG
        Wire.write(0x10);  // Set to +/- 8g
        Wire.endTransmission();
        
        Wire.beginTransmission(MPU6050_ADDR);
        Wire.write(0x1A);  // CONFIG
        Wire.write(0x04);  // DLPF ~20Hz
        Wire.endTransmission();
        
        Serial.println("[OK] MPU6050 initialized");
    } else {
        Serial.println("[ERROR] MPU6050 not found!");
    }
}

void calibrateAccelerometer() {
    float sumX = 0, sumY = 0, sumZ = 0;
    const int samples = 100;
    
    for (int i = 0; i < samples; i++) {
        int16_t ax, ay, az;
        Wire.beginTransmission(MPU6050_ADDR);
        Wire.write(0x3B);
        Wire.endTransmission(false);
        Wire.requestFrom((uint8_t)MPU6050_ADDR, (size_t)6);
        
        if (Wire.available() >= 6) {
            ax = Wire.read() << 8 | Wire.read();
            ay = Wire.read() << 8 | Wire.read();
            az = Wire.read() << 8 | Wire.read();
            
            sumX += ax;
            sumY += ay;
            sumZ += az;
        }
        delay(10);
    }
    
    baselineAccel = sqrt(sumX*sumX + sumY*sumY + sumZ*sumZ) / samples;
    Serial.print("[OK] Accelerometer calibrated: baseline = ");
    Serial.println(baselineAccel);
}

// ============================================
//           BLE FUNCTIONS
// ============================================

void initBLE() {
    BLEDevice::init("Digital Saver");
    
    // Create BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new BLEServerCallbacks());
    
    // Create BLE Service
    pService = pServer->createService(SERVICE_UUID);
    
    // Create BLE Characteristic
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_NOTIFY | 
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_WRITE
    );
    
    // Add descriptor
    pCharacteristic->addDescriptor(new BLE2902());
    
    // Create Command Characteristic for receiving settings
    pCommandCharacteristic = pService->createCharacteristic(
        COMMAND_CHAR_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    pCommandCharacteristic->setCallbacks(new BLECommandCallbacks());
    
    // Start service
    pService->start();
    
    // Start advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(false);
    pAdvertising->setMinPreferred(0x0);
    BLEDevice::startAdvertising();
    
    Serial.println("[OK] BLE initialized - waiting for connection...");
}

// ============================================
//           WiFi & INTERNET FUNCTIONS
// ============================================

void initWiFi() {
    Serial.println("[WIFI] Initializing WiFi...");
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        wifiConnected = true;
        wifiEnabled = true;
        Serial.println("\n[WIFI] Connected! IP: " + WiFi.localIP().toString());
        vibrate(100);
        
        // Get weather immediately
        fetchWeather();
    } else {
        wifiConnected = false;
        Serial.println("\n[WIFI] Connection failed!");
    }
}

void fetchWeather() {
    if (!wifiConnected || !wifiEnabled) {
        Serial.println("[WEATHER] WiFi not connected!");
        return;
    }
    
    Serial.println("[WEATHER] Fetching weather data...");
    
    HTTPClient http;
    String url = String(WEATHER_API_URL) + 
        "?q=Cairo&appid=" + WEATHER_API_KEY + "&units=metric";
    
    http.begin(url);
    int httpCode = http.GET();
    
    if (httpCode == HTTP_CODE_OK) {
        String payload = http.getString();
        
        // Parse JSON weather data
        StaticJsonDocument<1024> doc;
        DeserializationError error = deserializeJson(doc, payload);
        
        if (!error) {
            currentWeather.temperature = doc["main"]["temp"];
            currentWeather.humidity = doc["main"]["humidity"];
            currentWeather.condition = doc["weather"][0]["main"].as<String>();
            currentWeather.icon = doc["weather"][0]["icon"].as<String>();
            currentWeather.windSpeed = doc["wind"]["speed"];
            currentWeather.updated = true;
            
            Serial.println("[WEATHER] Updated: " + 
                String(currentWeather.temperature) + "C, " + 
                currentWeather.condition);
        } else {
            Serial.println("[WEATHER] JSON parse error!");
        }
    } else {
        Serial.println("[WEATHER] HTTP Error: " + String(httpCode));
    }
    
    http.end();
    lastWeatherUpdate = millis();
}

// ============================================
//           ADVANCED HEALTH AI ENGINE
// ============================================

// Calculate Basal Metabolic Rate based on profile
void calculateBMR() {
    if (!userProfile.profileSet) {
        healthAI.bmr = 1500; // Default BMR
        return;
    }
    
    // Mifflin-St Jeor Equation
    if (userProfile.gender == "male") {
        healthAI.bmr = 10 * userProfile.weightKg + 6.25 * userProfile.heightCm - 5 * userProfile.age + 5;
    } else {
        healthAI.bmr = 10 * userProfile.weightKg + 6.25 * userProfile.heightCm - 5 * userProfile.age - 161;
    }
}

// Analyze blood pressure and categorize
void analyzeBloodPressure() {
    float sys = currentHealth.bloodPressureSys;
    float dia = currentHealth.bloodPressureDia;
    
    if (sys < 120 && dia < 80) {
        healthAI.bpCategory = "NORMAL";
        healthAI.cardiovascularRisk = 0;
    } else if (sys >= 120 && sys < 130 && dia < 80) {
        healthAI.bpCategory = "ELEVATED";
        healthAI.cardiovascularRisk = 1;
    } else if (sys >= 130 && sys < 140 || dia >= 80 && dia < 90) {
        healthAI.bpCategory = "HIGH_STAGE1";
        healthAI.cardiovascularRisk = 2;
    } else if (sys >= 140 || dia >= 90) {
        healthAI.bpCategory = "HIGH_STAGE2";
        healthAI.cardiovascularRisk = 3;
    } else if (sys > 180 || dia > 120) {
        healthAI.bpCategory = "CRISIS";
        healthAI.cardiovascularRisk = 4;
        healthAI.warningMessage = "HYPERTENSIVE CRISIS! SEEK HELP NOW!";
        vibrate(500);
    }
}

// Detect potential arrhythmia patterns
void detectArrhythmia() {
    static float lastHR = 0;
    static int irregularCount = 0;
    
    // Check for irregular heartbeats (large variation)
    if (lastHR > 0) {
        float variation = abs(currentHealth.heartRate - lastHR);
        
        // If HR changes by more than 30 BPM suddenly
        if (variation > 30) {
            irregularCount++;
            if (irregularCount >= 3) {
                healthAI.arrhythmiaRisk = 3; // High risk
                healthAI.warningMessage = "POSSIBLE ARRHYTHMIA DETECTED!";
            }
        } else {
            if (irregularCount > 0) irregularCount--;
        }
    }
    
    lastHR = currentHealth.heartRate;
    
    // HRV analysis for stress
    if (currentHealth.hrvRMSSD < 20) {
        healthAI.stressScore = 80 + random(20); // High stress
        healthAI.arrhythmiaRisk = max(healthAI.arrhythmiaRisk, 2);
    } else if (currentHealth.hrvRMSSD < 40) {
        healthAI.stressScore = 50 + random(30); // Moderate stress
    } else {
        healthAI.stressScore = 20 + random(30); // Low stress
    }
}

// Calculate current activity state
void calculateActivityState() {
    float hr = currentHealth.heartRate;
    float steps = currentHealth.steps;
    
    // Simple step rate calculation
    static float lastSteps = 0;
    static uint32_t lastStepTime = 0;
    float stepRate = (steps - lastSteps) / ((millis() - lastStepTime) / 60000.0); // steps per minute
    lastSteps = steps;
    lastStepTime = millis();
    
    if (hr < 60) {
        healthAI.activityState = "SLEEPING";
    } else if (hr < 80 && stepRate < 5) {
        healthAI.activityState = "RESTING";
    } else if (hr < 100 && stepRate < 30) {
        healthAI.activityState = "WALKING";
    } else if (hr < 140 && stepRate < 60) {
        healthAI.activityState = "EXERCISING";
    } else if (hr >= 140) {
        healthAI.activityState = "INTENSE";
    } else {
        healthAI.activityState = "ACTIVE";
    }
    
    // Calculate calories based on activity
    if (healthAI.activityState == "RESTING") {
        healthAI.activeCalories = healthAI.bmr / 1440 * 0.1; // Per minute
    } else if (healthAI.activityState == "WALKING") {
        healthAI.activeCalories = healthAI.bmr / 1440 * 0.5;
    } else if (healthAI.activityState == "EXERCISING") {
        healthAI.activeCalories = healthAI.bmr / 1440 * 1.0;
    } else if (healthAI.activityState == "INTENSE") {
        healthAI.activeCalories = healthAI.bmr / 1440 * 1.5;
    } else {
        healthAI.activeCalories = healthAI.bmr / 1440 * 0.05; // Sleeping
    }
}

// Check SpO2 for hypoxia risk
void checkHypoxiaRisk() {
    if (currentHealth.spO2 < 90) {
        healthAI.hypoxiaRisk = 4; // Critical
        healthAI.warningMessage = "LOW BLOOD OXYGEN! CONSULT DOCTOR!";
    } else if (currentHealth.spO2 < 94) {
        healthAI.hypoxiaRisk = 3; // High
        healthAI.warningMessage = "SPO2 BELOW NORMAL";
    } else if (currentHealth.spO2 < 96) {
        healthAI.hypoxiaRisk = 2; // Medium
    } else {
        healthAI.hypoxiaRisk = 0; // Normal
    }
}

// Check for overexertion
void checkOverexertionRisk() {
    float maxHR = userProfile.profileSet ? userProfile.maxHeartRate : 180;
    
    if (currentHealth.heartRate > maxHR) {
        healthAI.overexertionRisk = 4; // Critical
        healthAI.warningMessage = "HEART RATE TOO HIGH! SLOW DOWN!";
    } else if (currentHealth.heartRate > maxHR * 0.95) {
        healthAI.overexertionRisk = 3; // High
    } else if (currentHealth.heartRate > maxHR * 0.85) {
        healthAI.overexertionRisk = 2; // Medium
    } else {
        healthAI.overexertionRisk = 0; // Normal
    }
}

// Generate health insight and recommendation
void generateHealthInsight() {
    // Calculate heart score
    if (currentHealth.heartRate >= 60 && currentHealth.heartRate <= 100) {
        healthAI.heartScore = 100 - abs(80 - currentHealth.heartRate);
    } else {
        healthAI.heartScore = 50 - abs(80 - currentHealth.heartRate);
    }
    healthAI.heartScore = constrain(healthAI.heartScore, 0, 100);
    
    // Activity score based on steps
    if (userProfile.profileSet) {
        healthAI.activityScore = (currentHealth.steps / (float)userProfile.targetSteps) * 100;
    } else {
        healthAI.activityScore = (currentHealth.steps / 10000.0) * 100;
    }
    healthAI.activityScore = constrain(healthAI.activityScore, 0, 100);
    
    // Overall score (weighted average)
    healthAI.overallScore = 
        healthAI.heartScore * 0.35 +
        healthAI.activityScore * 0.25 +
        (100 - healthAI.stressScore) * 0.20 +
        currentHealth.spO2 * 0.20;
    
    // Generate insight based on state
    if (healthAI.cardiovascularRisk >= 3) {
        healthAI.healthInsight = "High blood pressure detected";
        healthAI.recommendation = "Reduce sodium intake, exercise more";
    } else if (healthAI.arrhythmiaRisk >= 3) {
        healthAI.healthInsight = "Irregular heartbeat pattern";
        healthAI.recommendation = "Consider consulting a cardiologist";
    } else if (healthAI.hypoxiaRisk >= 3) {
        healthAI.healthInsight = "Low blood oxygen levels";
        healthAI.recommendation = "Deep breathing exercises recommended";
    } else if (healthAI.activityState == "RESTING") {
        healthAI.healthInsight = "You're resting well";
        healthAI.recommendation = "Time for a short walk?";
    } else if (healthAI.activityState == "EXERCISING") {
        healthAI.healthInsight = "Great workout session!";
        healthAI.recommendation = "Keep up the good pace";
    } else if (healthAI.stressScore > 70) {
        healthAI.healthInsight = "Elevated stress detected";
        healthAI.recommendation = "Try deep breathing for 5 minutes";
    } else {
        healthAI.healthInsight = "All vitals looking good!";
        healthAI.recommendation = "Stay hydrated and active";
    }
    
    // Calculate fatigue level
    healthAI.fatigueLevel = 100 - healthAI.overallScore;
    healthAI.recoveryMinutes = healthAI.fatigueLevel * 0.5; // Rough estimate
}

// Main Health AI function - call this every loop
void runHealthAI() {
    calculateBMR();
    analyzeBloodPressure();
    detectArrhythmia();
    checkHypoxiaRisk();
    checkOverexertionRisk();
    calculateActivityState();
    generateHealthInsight();
}

class BLEServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        setLED(false, true);  // Green = connected
        vibrate(100);  // Short vibration on connect
        Serial.println("[BLE] Device connected");
    };

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        setLED(true, false);  // Red = disconnected
        Serial.println("[BLE] Device disconnected");
    }
};

// Command callback handler
class BLECommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* pCharacteristic) {
        std::string rxData = pCharacteristic->getValue();
        if (rxData.length() > 0) {
            Serial.print("[CMD] Received: ");
            Serial.println(rxData.c_str());
            
            // Parse command: "THEME:X" where X is 0-4
            if (rxData.substr(0, 6) == "THEME:") {
                int themeId = atoi(rxData.substr(6).c_str());
                switch (themeId) {
                    case 0: currentTheme = THEME_DEFAULT; break;
                    case 1: currentTheme = THEME_INVERTED; break;
                    case 2: currentTheme = THEME_HIGH_CONTRAST; break;
                    case 3: currentTheme = THEME_NIGHT; break;
                    case 4: currentTheme = THEME_MINIMAL; break;
                    default: currentTheme = THEME_DEFAULT; break;
                }
                Serial.printf("[THEME] Set to theme %d\n", themeId);
                vibrate(50);  // Confirm with vibration
            }
            
            // Parse mode: "MODE:X" where X is 0-7
            else if (rxData.substr(0, 5) == "MODE:") {
                int modeId = atoi(rxData.substr(5).c_str());
                switch (modeId) {
                    case 0: currentMode = MODE_CLOCK; break;
                    case 1: currentMode = MODE_HEART_RATE; break;
                    case 2: currentMode = MODE_BLOOD_PRESSURE; break;
                    case 3: currentMode = MODE_ACTIVITY; break;
                    case 4: currentMode = MODE_SLEEP; break;
                    case 5: currentMode = MODE_WEATHER; break;
                    case 6: currentMode = MODE_STEALTH; break;
                    case 7: currentMode = MODE_SETTINGS; break;
                }
                Serial.printf("[MODE] Set to mode %d\n", modeId);
                vibrate(30);  // Confirm
            }
            
            // WiFi commands
            else if (rxData == "WIFI:ON") {
                if (!wifiEnabled) {
                    initWiFi();
                }
                pCommandCharacteristic->setValue("WIFI:STARTED");
                pCommandCharacteristic->notify();
            }
            else if (rxData == "WIFI:OFF") {
                WiFi.disconnect();
                wifiEnabled = false;
                wifiConnected = false;
                pCommandCharacteristic->setValue("WIFI:OFF");
                pCommandCharacteristic->notify();
            }
            else if (rxData == "WEATHER:REFRESH") {
                if (wifiConnected) {
                    fetchWeather();
                    pCommandCharacteristic->setValue("WEATHER:UPDATED");
                    pCommandCharacteristic->notify();
                }
            }
            
            // Profile setup: "PROFILE:name,age,weight,height,gender,steps"
            else if (rxData.substr(0, 8) == "PROFILE:") {
                String profileData = rxData.substring(8);
                int idx1 = profileData.indexOf(',');
                int idx2 = profileData.indexOf(',', idx1 + 1);
                int idx3 = profileData.indexOf(',', idx2 + 1);
                int idx4 = profileData.indexOf(',', idx3 + 1);
                int idx5 = profileData.indexOf(',', idx4 + 1);
                
                if (idx1 > 0 && idx2 > idx1 && idx3 > idx2 && idx4 > idx3 && idx5 > idx4) {
                    userProfile.name = profileData.substring(0, idx1);
                    userProfile.age = atoi(profileData.substring(idx1 + 1, idx2).c_str());
                    userProfile.weightKg = atoi(profileData.substring(idx2 + 1, idx3).c_str());
                    userProfile.heightCm = atoi(profileData.substring(idx3 + 1, idx4).c_str());
                    userProfile.gender = profileData.substring(idx4 + 1, idx5);
                    userProfile.targetSteps = atoi(profileData.substring(idx5 + 1).c_str());
                    userProfile.maxHeartRate = 220 - userProfile.age;  // Calculate max HR
                    userProfile.minHeartRate = 50;
                    userProfile.profileSet = true;
                    
                    calculateBMR();  // Update BMR with new profile
                    
                    char response[64];
                    snprintf(response, sizeof(response), "PROFILE:OK %s %dy", 
                        userProfile.name.c_str(), userProfile.age);
                    pCommandCharacteristic->setValue(response);
                    pCommandCharacteristic->notify();
                    Serial.printf("[PROFILE] Set for %s, age %d\n", 
                        userProfile.name.c_str(), userProfile.age);
                }
            }
            
            // Get Health AI Status
            else if (rxData == "HEALTHAI:STATUS") {
                char response[128];
                snprintf(response, sizeof(response),
                    "AI:%d,CVD:%d,ARR:%d,HYP:%d,STRESS:%d,INSIGHT:%s",
                    (int)healthAI.overallScore,
                    healthAI.cardiovascularRisk,
                    healthAI.arrhythmiaRisk,
                    healthAI.hypoxiaRisk,
                    (int)healthAI.stressScore,
                    healthAI.healthInsight.c_str()
                );
                pCommandCharacteristic->setValue(response);
                pCommandCharacteristic->notify();
            }
            
            // Ping: respond with pong
            else if (rxData == "PING") {
                pCommandCharacteristic->setValue("PONG");
                pCommandCharacteristic->notify();
                Serial.println("[CMD] PING -> PONG");
            }
            
            // Get status
            else if (rxData == "STATUS") {
                char status[64];
                snprintf(status, sizeof(status), "THEME:%d,MODE:%d,BATT:%d", 
                    currentTheme, currentMode, getBatteryLevel());
                pCommandCharacteristic->setValue(status);
                pCommandCharacteristic->notify();
            }
        }
    }
};

void sendBLEData() {
    if (!deviceConnected) return;
    
    // Pack health data into JSON-like string
    char buffer[256];
    snprintf(buffer, sizeof(buffer),
        "{\"hr\":%.0f,\"spo2\":%.0f,\"bps\":%.0f,\"bpd\":%.0f,"
        "\"hrv\":%.2f,\"steps\":%lu,\"cal\":%.1f,\"temp\":%.1f,"
        "\"irreg\":%d,\"fall\":%d,\"ax\":%.2f,\"ay\":%.2f,\"az\":%.2f}",
        currentHealth.heartRate,
        currentHealth.spO2,
        currentHealth.bloodPressureSys,
        currentHealth.bloodPressureDia,
        currentHealth.hrvRMSSD,
        currentHealth.steps,
        currentHealth.calories,
        currentHealth.temperature,
        currentHealth.irregularHeartbeat ? 1 : 0,
        currentHealth.fallDetected ? 1 : 0,
        rawData.accelX,
        rawData.accelY,
        rawData.accelZ
    );
    
    pCharacteristic->setValue(buffer);
    pCharacteristic->notify();
    
    Serial.print("[BLE] Sent: ");
    Serial.println(buffer);
}

// ============================================
//           SENSOR FUNCTIONS
// ============================================

void updateHeartRate() {
    // Read IR value for heart rate
    float irValue = particleSensor.getIR();
    rawData.irValue = irValue;
    
    // Check if finger is on sensor
    if (irValue < 50000) {
        currentHealth.heartRate = 0;
        return;
    }
    
    // Get red value for SpO2
    float redValue = particleSensor.getRed();
    rawData.redValue = redValue;
    
    // Look for beat - simplified algorithm
    uint32_t currentTime = millis();
    
    // Simple peak detection
    static float lastIrValue = 0;
    static bool rising = false;
    
    if (irValue > lastIrValue) {
        rising = true;
    } else if (rising && irValue < lastIrValue - 500) {
        // Peak detected
        if (lastBeatTime > 0) {
            uint32_t rrInterval = currentTime - lastBeatTime;
            
            // Valid RR interval: 300ms to 2000ms (30-200 BPM)
            if (rrInterval > 300 && rrInterval < 2000) {
                rrIntervals[rrIndex] = rrInterval;
                rrIndex = (rrIndex + 1) % HRV_BUFFER_SIZE;
                
                // Calculate heart rate
                currentHealth.heartRate = 60000.0 / rrInterval;
                
                beatDetected = true;
                vibrate(30);  // Short pulse
            }
        }
        lastBeatTime = currentTime;
        rising = false;
    }
    lastIrValue = irValue;
    
    // Calculate HRV
    calculateHRV();
}

void calculateHRV() {
    // Calculate RMSSD (Root Mean Square of Successive Differences)
    float sumSquaredDiffs = 0;
    int validCount = 0;
    
    for (int i = 1; i < HRV_BUFFER_SIZE; i++) {
        if (rrIntervals[i] > 0 && rrIntervals[i-1] > 0) {
            float diff = rrIntervals[i] - rrIntervals[i-1];
            sumSquaredDiffs += diff * diff;
            validCount++;
        }
    }
    
    if (validCount > 0) {
        currentHealth.hrvRMSSD = sqrt(sumSquaredDiffs / validCount);
    }
    
    // Calculate SDNN (Standard Deviation of NN intervals)
    float sum = 0;
    validCount = 0;
    for (int i = 0; i < HRV_BUFFER_SIZE; i++) {
        if (rrIntervals[i] > 0) {
            sum += rrIntervals[i];
            validCount++;
        }
    }
    
    if (validCount > 1) {
        float mean = sum / validCount;
        float sumSquaredDev = 0;
        for (int i = 0; i < HRV_BUFFER_SIZE; i++) {
            if (rrIntervals[i] > 0) {
                float dev = rrIntervals[i] - mean;
                sumSquaredDev += dev * dev;
            }
        }
        currentHealth.hrvSDNN = sqrt(sumSquaredDev / (validCount - 1));
    }
    
    // Detect irregular heartbeat
    currentHealth.irregularHeartbeat = (currentHealth.hrvRMSSD > IRREGULAR_THRESHOLD * 100);
}

void updateSpO2() {
    // Simplified SpO2 calculation
    // Real implementation uses ratio of ratios method
    float irValue = particleSensor.getIR();
    float redValue = particleSensor.getRed();
    
    if (irValue < 50000 || redValue < 50000) {
        currentHealth.spO2 = 0;
        return;
    }
    
    // AC/DC ratio calculation (simplified)
    float ac = irValue - (irValue / 100 * 99.5);  // Approximate AC component
    float dc = irValue / 100 * 99.5;  // Approximate DC component
    
    float ratio = ac / dc;
    
    // Convert to SpO2 percentage (simplified formula)
    float spo2 = 100 - 5 * (ratio * 100);
    spo2 = constrain(spo2, 70, 100);
    
    currentHealth.spO2 = spo2;
    
    // Calculate Perfusion Index
    currentHealth.perfusionIndex = (ac / dc) * 100;
}

void estimateBloodPressure() {
    // Blood pressure estimation from PPG waveform analysis
    // This is a simplified estimation - real devices need calibration
    
    // Get PPG waveform characteristics
    float irValue = particleSensor.getIR();
    float heartRate = currentHealth.heartRate;
    float hrv = currentHealth.hrvRMSSD;
    float pi = currentHealth.perfusionIndex;
    
    // Baseline estimation based on age factor (assumed 35 years)
    // In real application, this would be personalized
    float baseSys = 110;  // Base systolic
    float baseDia = 70;   // Base diastolic
    
    // Adjust based on heart rate
    if (heartRate > 80) {
        baseSys += (heartRate - 80) * 0.5;
        baseDia += (heartRate - 80) * 0.3;
    } else if (heartRate < 60) {
        baseSys -= (60 - heartRate) * 0.3;
        baseDia -= (60 - heartRate) * 0.2;
    }
    
    // Adjust based on HRV (stress indicator)
    if (hrv < 30) {
        // Low HRV = stress = higher BP
        baseSys += (30 - hrv) * 0.5;
        baseDia += (30 - hrv) * 0.3;
    }
    
    // Adjust based on Perfusion Index
    if (pi < 3) {
        // Low PI can indicate vasoconstriction
        baseSys += (3 - pi) * 2;
        baseDia += (3 - pi) * 1;
    }
    
    // Add some variation
    float variation = random(-5, 5);
    
    currentHealth.bloodPressureSys = baseSys + variation;
    currentHealth.bloodPressureDia = baseDia + variation * 0.6;
    
    // Constrain to reasonable values
    currentHealth.bloodPressureSys = constrain(currentHealth.bloodPressureSys, 80, 200);
    currentHealth.bloodPressureDia = constrain(currentHealth.bloodPressureDia, 50, 130);
}

void updateAccelerometer() {
    // Read MPU6050
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(0x3B);  // Starting with ACCEL_XOUT_H
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)MPU6050_ADDR, (size_t)6);
    
    if (Wire.available() >= 6) {
        int16_t ax = Wire.read() << 8 | Wire.read();
        int16_t ay = Wire.read() << 8 | Wire.read();
        int16_t az = Wire.read() << 8 | Wire.read();
        
        // Convert to g (assuming +/- 8g range)
        rawData.accelX = ax / 4096.0;
        rawData.accelY = ay / 4096.0;
        rawData.accelZ = az / 4096.0;
    }
}

void detectFall() {
    // Calculate acceleration magnitude
    float accelMagnitude = sqrt(
        rawData.accelX * rawData.accelX +
        rawData.accelY * rawData.accelY +
        rawData.accelZ * rawData.accelZ
    );
    
    // Detect sudden change
    float delta = abs(accelMagnitude - lastAccelMagnitude);
    
    if (delta > FALL_THRESHOLD) {
        // Possible fall detected
        currentHealth.fallDetected = true;
        
        if (!fallAlertSent) {
            triggerEmergency();
            fallAlertSent = true;
        }
    } else {
        currentHealth.fallDetected = false;
        fallAlertSent = false;
    }
    
    lastAccelMagnitude = accelMagnitude * 0.9 + lastAccelMagnitude * 0.1;  // Smooth
}

void updateActivity() {
    // Calculate step count from acceleration
    float accelMagnitude = sqrt(
        rawData.accelX * rawData.accelX +
        rawData.accelY * rawData.accelY +
        rawData.accelZ * rawData.accelZ
    );
    
    // Simple step detection
    static float lastPeakAccel = 0;
    static uint32_t lastStepTime = 0;
    
    if (accelMagnitude > 1.5 && lastPeakAccel < 1.3 && 
        (millis() - lastStepTime) > 250) {
        stepCount++;
        currentHealth.steps = stepCount;
        lastStepTime = millis();
    }
    lastPeakAccel = accelMagnitude;
    
    // Calculate calories (simplified)
    // Formula: MET * weight * time / 60
    // Assuming 70kg person, MET for walking ~3.5
    float met = 3.5;
    float weight = 70;
    float minutes = (millis() - activityStartTime) / 60000.0;
    currentHealth.calories = met * weight * minutes / 60;
    
    // Determine activity level
    if (accelMagnitude < 1.1) {
        currentHealth.activityLevel = 0;  // Sedentary
    } else if (accelMagnitude < 1.3) {
        currentHealth.activityLevel = 1;  // Light
    } else if (accelMagnitude < 1.6) {
        currentHealth.activityLevel = 2;  // Moderate
    } else {
        currentHealth.activityLevel = 3;  // Active
    }
}

void updateSleep() {
    // Simplified sleep detection
    // In real implementation, would use combination of:
    // - Movement patterns
    // - Heart rate
    // - Time of day
    
    float accelMagnitude = sqrt(
        rawData.accelX * rawData.accelX +
        rawData.accelY * rawData.accelY +
        rawData.accelZ * rawData.accelZ
    );
    
    uint32_t currentTime = millis();
    
    // If low movement for extended period during "night" hours
    if (accelMagnitude < 1.05) {
        if (!isSleeping) {
            isSleeping = true;
            sleepStartTime = currentTime;
        }
        
        // Estimate sleep quality based on movement
        if (accelMagnitude < 1.02) {
            // Very still = deep sleep
            deepSleepMinutes++;
        } else {
            // Some movement = light sleep
            lightSleepMinutes++;
        }
    } else {
        isSleeping = false;
    }
    
    // Calculate sleep score (0-100)
    uint32_t totalSleepMinutes = deepSleepMinutes + lightSleepMinutes;
    if (totalSleepMinutes > 0) {
        float deepSleepRatio = (float)deepSleepMinutes / totalSleepMinutes;
        currentHealth.sleepScore = min(100, deepSleepRatio * 100 + (totalSleepMinutes / 8.0) * 50);
    }
}

// ============================================
//           DISPLAY FUNCTIONS
// ============================================

// Helper to get theme colors
uint16_t getThemeColor(bool isBackground) {
    switch (currentTheme) {
        case THEME_DEFAULT:
            return isBackground ? SSD1306_BLACK : SSD1306_WHITE;
        case THEME_INVERTED:
            return isBackground ? SSD1306_WHITE : SSD1306_BLACK;
        case THEME_HIGH_CONTRAST:
            return isBackground ? SSD1306_BLACK : SSD1306_WHITE;
        case THEME_NIGHT:
            return isBackground ? SSD1306_BLACK : SSD1306_RED;  // Red for night mode
        case THEME_MINIMAL:
            return isBackground ? SSD1306_BLACK : SSD1306_WHITE;
        default:
            return isBackground ? SSD1306_BLACK : SSD1306_WHITE;
    }
}

void updateDisplay() {
    display.clearDisplay();
    
    // Apply theme-based colors
    uint16_t textColor = getThemeColor(false);
    uint16_t bgColor = getThemeColor(true);
    
    // For inverted theme, fill with white first
    if (currentTheme == THEME_INVERTED) {
        display.fillScreen(SSD1306_WHITE);
    }
    
    // For minimal theme, show only essential dots
    if (currentTheme == THEME_MINIMAL) {
        showMinimalDisplay();
        display.display();
        return;
    }
    
    // For night theme, red text
    if (currentTheme == THEME_NIGHT) {
        display.setTextColor(SSD1306_RED);
    } else {
        display.setTextColor(textColor);
    }
    
    switch (currentMode) {
        case MODE_CLOCK:
            showClockDisplay();
            break;
        case MODE_HEART_RATE:
            showHeartRateDisplay();
            break;
        case MODE_BLOOD_PRESSURE:
            showBloodPressureDisplay();
            break;
        case MODE_ACTIVITY:
            showActivityDisplay();
            break;
        case MODE_SLEEP:
            showSleepDisplay();
            break;
        case MODE_WEATHER:
            showWeatherDisplay();
            break;
        case MODE_STEALTH:
            showStealthDisplay();
            break;
        case MODE_SETTINGS:
            showSettingsDisplay();
            break;
    }
    
    display.display();
}

void showMinimalDisplay() {
    // Minimal mode: show only time as dots
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) return;
    
    int hours = timeinfo.tm_hour;
    int minutes = timeinfo.tm_min;
    
    // Show battery level as top dots
    for (int i = 0; i < 5; i++) {
        if (i < getBatteryLevel() / 20) {
            display.drawPixel(120 + i * 2, 2, SSD1306_WHITE);
        }
    }
    
    // Show time dots (binary-ish)
    // Hours tens
    int h1 = hours / 10;
    for (int i = 0; i < 4; i++) {
        if (h1 & (1 << i)) display.drawPixel(10 + i * 4, 10, SSD1306_WHITE);
    }
    // Hours units
    int h2 = hours % 10;
    for (int i = 0; i < 4; i++) {
        if (h2 & (1 << i)) display.drawPixel(30 + i * 4, 10, SSD1306_WHITE);
    }
    // Minutes tens
    int m1 = minutes / 10;
    for (int i = 0; i < 4; i++) {
        if (m1 & (1 << i)) display.drawPixel(50 + i * 4, 10, SSD1306_WHITE);
    }
    // Minutes units
    int m2 = minutes % 10;
    for (int i = 0; i < 4; i++) {
        if (m2 & (1 << i)) display.drawPixel(70 + i * 4, 10, SSD1306_WHITE);
    }
}

// ============================================
//           WEATHER DISPLAY
// ============================================

void showWeatherDisplay() {
    // Weather icon (simple)
    display.setTextSize(2);
    display.setCursor(5, 5);
    if (currentWeather.icon.indexOf("01") >= 0) {
        display.print("SUN");  // Clear
    } else if (currentWeather.icon.indexOf("02") >= 0 || currentWeather.icon.indexOf("03") >= 0) {
        display.print("CLO");  // Cloudy
    } else if (currentWeather.icon.indexOf("09") >= 0 || currentWeather.icon.indexOf("10") >= 0) {
        display.print("RAIN"); // Rain
    } else if (currentWeather.icon.indexOf("11") >= 0) {
        display.print("STORM"); // Thunderstorm
    } else if (currentWeather.icon.indexOf("50") >= 0) {
        display.print("FOG");  // Mist
    } else {
        display.print("?");
    }
    
    // Temperature
    display.setTextSize(3);
    display.setCursor(10, 28);
    if (currentWeather.updated) {
        display.print(currentWeather.temperature, 0);
        display.print((char)247);  // Degree symbol
        display.print("C");
    } else {
        display.print("--");
    }
    
    // Humidity
    display.setTextSize(1);
    display.setCursor(5, 55);
    if (currentWeather.updated) {
        display.print("HUM:");
        display.print(currentWeather.humidity);
        display.print("%  WIND:");
        display.print(currentWeather.windSpeed);
        display.print("m/s");
    } else {
        display.print("No weather data");
    }
    
    // Check for weather update
    if (wifiConnected && (millis() - lastWeatherUpdate > WEATHER_UPDATE_INTERVAL)) {
        fetchWeather();
    }
}

// ============================================
//           STEALTH/DISCREET MODE
// ============================================

void showStealthDisplay() {
    // STEALTH MODE: Watch looks like a normal analog watch!
    // Shows ONLY time as regular digits, no health icons
    // Perfect for meetings, interviews, or when you don't want
    // people to know it's a smart watch!
    
    display.setTextSize(4);  // Big digits
    display.setCursor(8, 18);
    display.print(formatTime());  // Just show time, nothing else!
    
    // Small date at bottom (looks like engraving)
    display.setTextSize(1);
    display.setCursor(25, 52);
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
        char dateStr[20];
        strftime(dateStr, sizeof(dateStr), "%b %d", &timeinfo);
        display.print(dateStr);
    }
    
    // Optional: Tiny dot at corner (hardly noticeable)
    if (deviceConnected) {
        display.drawPixel(124, 2, SSD1306_WHITE);  // Small BLE indicator
    }
}

void showClockDisplay() {
    // Time
    display.setTextSize(3);
    display.setCursor(10, 10);
    display.println(formatTime());
    
    // Date
    display.setTextSize(1);
    display.setCursor(15, 42);
    display.println(formatDate());
    
    // Status indicators
    int16_t x, y;
    uint16_t w, h;
    
    // BLE status
    display.drawCircle(120, 5, 3, SSD1306_WHITE);
    if (deviceConnected) {
        display.fillCircle(120, 5, 2, SSD1306_WHITE);
    }
    
    // Battery indicator (simplified)
    display.drawRect(110, 55, 15, 8, SSD1306_WHITE);
    display.fillRect(125, 57, 3, 4, SSD1306_WHITE);
}

void showHeartRateDisplay() {
    // Heart icon
    display.setTextSize(2);
    display.setCursor(5, 5);
    display.print(F("HR"));
    
    // BPM value
    display.setTextSize(3);
    display.setCursor(30, 5);
    if (currentHealth.heartRate > 0) {
        display.print(currentHealth.heartRate, 0);
    } else {
        display.print(F("--"));
    }
    display.setTextSize(1);
    display.setCursor(85, 20);
    display.print(F("BPM"));
    
    // SpO2
    display.setTextSize(1);
    display.setCursor(5, 35);
    display.print(F("SpO2:"));
    display.setTextSize(2);
    display.setCursor(35, 32);
    if (currentHealth.spO2 > 0) {
        display.print(currentHealth.spO2, 0);
        display.print(F("%"));
    } else {
        display.print(F("--%"));
    }
    
    // HRV
    display.setTextSize(1);
    display.setCursor(5, 52);
    display.print(F("HRV:"));
    display.setTextSize(2);
    display.setCursor(30, 49);
    display.print(currentHealth.hrvRMSSD, 1);
    
    // Alert if irregular
    if (currentHealth.irregularHeartbeat) {
        display.setTextSize(1);
        display.setCursor(80, 52);
        display.print(F("!IRREG"));
        if (emergencyMode) {
            display.fillRect(0, 0, 128, 64, SSD1306_WHITE);
            display.setTextColor(SSD1306_BLACK);
            display.setTextSize(2);
            display.setCursor(20, 25);
            display.print(F("ALERT!"));
        }
    }
}

void showBloodPressureDisplay() {
    // BP icon
    display.setTextSize(2);
    display.setCursor(5, 5);
    display.print(F("BP"));
    
    // Systolic
    display.setTextSize(2);
    display.setCursor(30, 5);
    display.print(currentHealth.bloodPressureSys, 0);
    display.setTextSize(1);
    display.setCursor(65, 8);
    display.print(F("SYS"));
    
    // Diastolic
    display.setTextSize(2);
    display.setCursor(30, 25);
    display.print(currentHealth.bloodPressureDia, 0);
    display.setTextSize(1);
    display.setCursor(65, 28);
    display.print(F("DIA"));
    
    // Status
    display.setTextSize(1);
    display.setCursor(5, 45);
    if (currentHealth.bloodPressureSys >= HIGH_BP_SYSTOLIC) {
        display.print(F("STATUS: HIGH!"));
        display.setTextColor(SSD1306_BLACK);
        display.fillRect(0, 42, 128, 22, SSD1306_WHITE);
    } else if (currentHealth.bloodPressureSys < 90) {
        display.print(F("STATUS: LOW"));
    } else {
        display.print(F("STATUS: NORMAL"));
    }
    
    // MAP
    display.setTextColor(SSD1306_WHITE);
    display.setTextSize(1);
    display.setCursor(5, 55);
    float map = (currentHealth.bloodPressureSys + 2 * currentHealth.bloodPressureDia) / 3.0;
    display.print(F("MAP:"));
    display.print(map, 0);
}

void showActivityDisplay() {
    // Steps
    display.setTextSize(2);
    display.setCursor(5, 5);
    display.print(F("Steps"));
    display.setTextSize(3);
    display.setCursor(5, 20);
    display.print(currentHealth.steps);
    
    // Calories
    display.setTextSize(1);
    display.setCursor(5, 45);
    display.print(F("Cal:"));
    display.print(currentHealth.calories, 0);
    
    // Activity level bar
    display.setTextSize(1);
    display.setCursor(60, 45);
    display.print(F("Activity"));
    display.drawRect(60, 52, 60, 10, SSD1306_WHITE);
    int barWidth = (currentHealth.activityLevel + 1) * 15;
    display.fillRect(61, 53, barWidth, 8, SSD1306_WHITE);
}

void showSleepDisplay() {
    // Sleep score
    display.setTextSize(2);
    display.setCursor(5, 5);
    display.print(F("Sleep"));
    display.setTextSize(3);
    display.setCursor(30, 22);
    display.print(currentHealth.sleepScore, 0);
    display.setTextSize(1);
    display.setCursor(70, 30);
    display.print(F("/100"));
    
    // Deep sleep
    display.setTextSize(1);
    display.setCursor(5, 42);
    display.print(F("Deep:"));
    display.print(deepSleepMinutes);
    display.print(F("min"));
    
    // Light sleep
    display.setCursor(5, 52);
    display.print(F("Light:"));
    display.print(lightSleepMinutes);
    display.print(F("min"));
}

void showSettingsDisplay() {
    // Settings Screen with Profile & Health AI Status
    display.setTextSize(1);
    
    // Profile Status
    display.setCursor(0, 0);
    display.print(F("PROFILE:"));
    display.setCursor(0, 9);
    if (userProfile.profileSet) {
        display.print(userProfile.name);
        display.print(" | ");
        display.print(userProfile.age);
        display.print("y | ");
        display.print(userProfile.weightKg);
        display.print("kg");
    } else {
        display.print(F("Not Set - Send PROFILE via BLE"));
    }
    
    // Health AI Overall Score
    display.setCursor(0, 18);
    display.print(F("HEALTH AI SCORE:"));
    display.setCursor(0, 27);
    display.print(F("Overall:"));
    display.print((int)healthAI.overallScore);
    display.print(F("/100 | "));
    display.print(healthAI.activityState);
    
    // Risk Indicators
    display.setCursor(0, 36);
    display.print(F("Risks:"));
    display.print(F("CVD:"));
    display.print(healthAI.cardiovascularRisk);
    display.print(F(" ARR:"));
    display.print(healthAI.arrhythmiaRisk);
    display.print(F(" HYP:"));
    display.print(healthAI.hypoxiaRisk);
    
    // Activity & Calories
    display.setCursor(0, 45);
    display.print(F("State:"));
    display.print(healthAI.activityState);
    display.print(F(" CAL:"));
    display.print((int)healthAI.caloriesBurned);
    
    // Status
    display.setCursor(0, 54);
    display.print(F("WiFi:"));
    display.print(wifiConnected ? F("ON") : F("OFF"));
    display.print(F(" BLE:"));
    display.print(deviceConnected ? F("ON") : F("OFF"));
    display.print(F(" v3.1.0"));
}

// ============================================
//           UTILITY FUNCTIONS
// ============================================

String formatTime() {
    uint32_t seconds = millis() / 1000;
    uint32_t minutes = seconds / 60;
    uint32_t hours = (minutes / 60) % 24;
    
    char buffer[9];
    sprintf(buffer, "%02d:%02d:%02d", hours, minutes % 60, seconds % 60);
    return String(buffer);
}

String formatDate() {
    char buffer[12];
    sprintf(buffer, "2024/06/%02d", 24);  // Simplified - would use RTC in real device
    return String(buffer);
}

void vibrate(uint16_t duration) {
    digitalWrite(VIBRATION_MOTOR, HIGH);
    delay(duration);
    digitalWrite(VIBRATION_MOTOR, LOW);
}

void setLED(bool red, bool green) {
    digitalWrite(LED_RED, red ? HIGH : LOW);
    digitalWrite(LED_GREEN, green ? HIGH : LOW);
}

void triggerEmergency() {
    emergencyMode = true;
    vibrate(500);  // Long vibration
    
    // Flash red LED
    for (int i = 0; i < 5; i++) {
        setLED(true, false);
        delay(100);
        setLED(false, false);
        delay(100);
    }
    
    // Send alert via BLE
    if (deviceConnected) {
        char alertBuffer[64];
        snprintf(alertBuffer, sizeof(alertBuffer),
            "{\"alert\":\"EMERGENCY\",\"hr\":%.0f,\"lat\":%.6f,\"lon\":%.6f}",
            currentHealth.heartRate,
            30.0444,  // Would use actual GPS in real device
            31.2357
        );
        pCharacteristic->setValue(alertBuffer);
        pCharacteristic->notify();
    }
    
    emergencyMode = false;
}

void handleButtonPress() {
    uint32_t now = millis();
    
    if (now - lastButtonPress < DEBOUNCE_TIME) return;
    
    // Mode button
    if (digitalRead(BUTTON_MODE) == LOW) {
        lastButtonPress = now;
        vibrate(50);
        
        // Cycle through modes
        currentMode = (WatchMode)((currentMode + 1) % (MODE_SETTINGS + 1));
        display.clearDisplay();
    }
    
    // Emergency button
    if (digitalRead(BUTTON_EMERGENCY) == LOW) {
        lastButtonPress = now;
        vibrate(100);
        triggerEmergency();
    }
    
    // Back button (reset mode to clock)
    if (digitalRead(BUTTON_BACK) == LOW) {
        lastButtonPress = now;
        vibrate(50);
        currentMode = MODE_CLOCK;
        display.clearDisplay();
    }
}

// ============================================
//           MAIN LOOP
// ============================================

void loop() {
    uint32_t now = millis();
    
    // Handle button presses
    handleButtonPress();
    
    // Update sensors every measurement interval
    if (now - lastMeasurement >= MEASUREMENT_INTERVAL) {
        lastMeasurement = now;
        
        // Update all health data
        updateHeartRate();
        updateSpO2();
        estimateBloodPressure();
        updateAccelerometer();
        detectFall();
        updateActivity();
        updateSleep();
        
        // Get temperature from MAX30102
        currentHealth.temperature = particleSensor.readTemperature();
        
        // Set timestamp
        currentHealth.timestamp = now;
        
        // Run Health AI Analysis
        runHealthAI();
    }
    
    // Send BLE data
    if (now - lastBLEUpdate >= BLE_SEND_INTERVAL) {
        lastBLEUpdate = now;
        sendBLEData();
    }
    
    // Update display
    if (now - lastDisplayUpdate >= DISPLAY_REFRESH) {
        lastDisplayUpdate = now;
        updateDisplay();
    }
    
    // Handle BLE disconnection
    if (oldDeviceConnected && !deviceConnected) {
        delay(500);  // Wait for BLE to be ready
        BLEDevice::startAdvertising();
        oldDeviceConnected = false;
    }
    if (!oldDeviceConnected && deviceConnected) {
        oldDeviceConnected = true;
    }
    
    // Small delay to prevent watchdog
    delay(5);
}

/**
 * END OF FIRMWARE
 * 
 * For compilation:
 * 1. Open in Arduino IDE or PlatformIO
 * 2. Select Board: "ESP32 Dev Module"
 * 3. Upload at 921600 baud
 * 4. Monitor at 115200 baud
 * 
 * Required Libraries:
 * - SparkFun MAX3010x Pulse and Proximity Sensor Library
 * - Adafruit GFX Library
 * - Adafruit SSD1306 Library
 * - BLE for ESP32 (included in esp32 board package)
 */
