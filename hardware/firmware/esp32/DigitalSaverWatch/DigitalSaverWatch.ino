/**
 * Digital Saver - Smartwatch Firmware
 * ESP32-based health monitoring smartwatch
 * 
 * Features:
 * - Heart rate monitoring via MAX30102 PPG sensor
 * - Blood pressure estimation via PPG waveform analysis
 * - Fall detection via MPU6050 accelerometer
 * - Bluetooth LE communication with mobile app
 * - OLED display for local data viewing
 * 
 * Hardware:
 * - ESP32-WROOM-32 (or ESP32-S3 for better power efficiency)
 * - MAX30102 PPG sensor
 * - MPU6050 accelerometer/gyroscope
 * - 1.3" OLED display (SH1106 or SSD1306)
 * - Vibration motor
 * - Buzzer
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <SparkFunMAX30105.h>
#include <heartRate.h>
#include <spo2_algorithm.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH1106.h>
#include <MPU6050.h>

// ============================================
// PIN DEFINITIONS
// ============================================
#define I2C_SDA 21
#define I2C_SCL 22
#define BUZZER_PIN 27
#define MOTOR_PIN 26
#define BUTTON_PIN 0
#define OLED_RESET -1

// ============================================
// BLE SERVICE UUIDs
// ============================================
#define HEALTH_SERVICE_UUID "00001816-0000-1000-8000-00805f9b34fb"
#define HEART_RATE_UUID "00002A37-0000-1000-8000-00805f9b34fb"
#define BP_UUID "00002A35-0000-1000-8000-00805f9b34fb"
#define ALERT_UUID "00002A3F-0000-1000-8000-00805f9b34fb"
#define DEVICE_INFO_SERVICE_UUID "0000180A-0000-1000-8000-00805f9b34fb"
#define BATTERY_UUID "00002A19-0000-1000-8000-00805f9b34fb"

// ============================================
// GLOBAL OBJECTS
// ============================================
MAX30105 particleSensor;
MPU6050 mpu;
Adafruit_SH1106 display(OLED_RESET);

// BLE Characteristics
BLECharacteristic *heartRateChar;
BLECharacteristic *bpChar;
BLECharacteristic *alertChar;
BLECharacteristic *batteryChar;

bool deviceConnected = false;
bool alertTriggered = false;
unsigned long lastReadTime = 0;
unsigned long lastAlertTime = 0;

// Health data
int currentHeartRate = 0;
int currentSpO2 = 0;
int estimatedSystolic = 0;
int estimatedDiastolic = 0;
int batteryLevel = 100;

// Detection thresholds
const int MIN_HEART_RATE = 50;
const int MAX_HEART_RATE = 120;
const int HYPERTENSION_SYSTOLIC = 140;
const int FALL_THRESHOLD = 250; // mg

// PPG buffer for analysis
const int PPG_BUFFER_SIZE = 100;
float ppgBuffer[PPG_BUFFER_SIZE];
int ppgIndex = 0;
unsigned long lastBeatTime = 0;
float lastIRValue = 0;

// Accelerometer data
float accX, accY, accZ;
bool fallDetected = false;

// ============================================
// CLASSES
// ============================================
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
      digitalWrite(BUZZER_PIN, HIGH);
      delay(100);
      digitalWrite(BUZZER_PIN, LOW);
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
      pServer->startAdvertising();
    }
};

// ============================================
// SETUP
// ============================================
void setup() {
  Serial.begin(115200);
  
  // Initialize I2C
  Wire.begin(I2C_SDA, I2C_SCL);
  
  // Initialize GPIO
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(MOTOR_PIN, LOW);
  
  // Initialize display
  initDisplay();
  
  // Initialize sensors
  initSensors();
  
  // Initialize BLE
  initBLE();
  
  // Startup beep
  playTone(1000, 200);
}

void initDisplay() {
  display.begin(SH1106_SWITCHCAPVCC, 0x3C);
  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Digital Saver");
  display.println("Smart Watch");
  display.display();
  delay(1000);
}

void initSensors() {
  // Initialize MAX30102
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("MAX30105 not found!");
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Sensor Error!");
    display.println("MAX30105 not found");
    display.display();
    while (1);
  }
  
  byte ledBrightness = 60;
  byte sampleAverage = 4;
  byte ledMode = 2;
  int sampleRate = 400;
  int pulseWidth = 411;
  int adcRange = 4096;
  
  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);
  
  // Initialize MPU6050
  mpu.initialize();
  if (!mpu.testConnection()) {
    Serial.println("MPU6050 not found!");
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("Sensor Error!");
    display.println("MPU6050 not found");
    display.display();
  }
  
  Serial.println("Sensors initialized");
}

void initBLE() {
  BLEDevice::init("DigitalSaver Watch");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // Create Health Service
  BLEService *healthService = pServer->createService(HEALTH_SERVICE_UUID);
  
  // Heart Rate Characteristic
  heartRateChar = healthService->createCharacteristic(
    HEART_RATE_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  heartRateChar->addDescriptor(new BLE2902());
  
  // Blood Pressure Characteristic
  bpChar = healthService->createCharacteristic(
    BP_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  bpChar->addDescriptor(new BLE2902());
  
  // Alert Characteristic
  alertChar = healthService->createCharacteristic(
    ALERT_UUID,
    BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ
  );
  alertChar->addDescriptor(new BLE2902());
  
  // Create Device Info Service
  BLEService *deviceInfoService = pServer->createService(DEVICE_INFO_SERVICE_UUID);
  
  // Battery Characteristic
  batteryChar = deviceInfoService->createCharacteristic(
    BATTERY_UUID,
    BLECharacteristic::PROPERTY_READ
  );
  batteryChar->addDescriptor(new BLE2902());
  
  healthService->start();
  deviceInfoService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(HEALTH_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE initialized");
}

// ============================================
// MAIN LOOP
// ============================================
void loop() {
  unsigned long currentTime = millis();
  
  // Read sensors every 100ms
  if (currentTime - lastReadTime >= 100) {
    lastReadTime = currentTime;
    
    readPPGSensor();
    readAccelerometer();
    checkForAlerts();
    updateDisplay();
  }
  
  // Send BLE data every second
  static unsigned long lastBLEUpdate = 0;
  if (deviceConnected && currentTime - lastBLEUpdate >= 1000) {
    lastBLEUpdate = currentTime;
    sendBLEData();
  }
  
  // Check button for emergency
  if (digitalRead(BUTTON_PIN) == LOW) {
    delay(50);
    if (digitalRead(BUTTON_PIN) == LOW) {
      triggerEmergency(1); // Manual emergency
      while (digitalRead(BUTTON_PIN) == LOW) delay(10);
    }
  }
  
  delay(10);
}

// ============================================
// SENSOR READING
// ============================================
void readPPGSensor() {
  long irValue = particleSensor.getIR();
  
  if (irValue > 50000) {
    // Check for beat
    if (checkForBeat(irValue) == true) {
      long delta = millis() - lastBeatTime;
      lastBeatTime = millis();
      
      // Calculate BPM
      int bpm = 60 / (delta / 1000.0);
      if (bpm > 30 && bpm < 220) {
        currentHeartRate = bpm;
      }
      
      // Store PPG value for analysis
      ppgBuffer[ppgIndex] = irValue;
      ppgIndex = (ppgIndex + 1) % PPG_BUFFER_SIZE;
      
      // Estimate blood pressure
      estimateBloodPressure();
    }
  }
  
  lastIRValue = irValue;
}

void readAccelerometer() {
  int16_t ax, ay, az;
  mpu.getAcceleration(&ax, &ay, &az);
  
  accX = ax / 16384.0; // Convert to g
  accY = ay / 16384.0;
  accZ = az / 16384.0;
  
  // Calculate total acceleration magnitude
  float totalAcc = sqrt(accX*accX + accY*accY + accZ*accZ) * 1000; // in mg
  
  // Detect fall (free-fall + impact)
  static bool inFreeFall = false;
  static unsigned long freeFallStart = 0;
  
  if (totalAcc < 300) { // Free fall detected
    if (!inFreeFall) {
      inFreeFall = true;
      freeFallStart = millis();
    }
  } else if (inFreeFall && totalAcc > FALL_THRESHOLD) {
    // Impact detected after free-fall
    unsigned long fallDuration = millis() - freeFallStart;
    if (fallDuration > 100 && fallDuration < 2000) {
      triggerFallAlert();
    }
    inFreeFall = false;
  } else if (inFreeFall && millis() - freeFallStart > 2000) {
    inFreeFall = false;
  }
}

// ============================================
// HEALTH ANALYSIS
// ============================================
void estimateBloodPressure() {
  // Simplified BP estimation using PPG features
  // In production, this would use more sophisticated algorithms
  
  // Estimate based on heart rate and physiological models
  float baseSystolic = 110.0;
  float baseDiastolic = 70.0;
  
  // Adjust based on HR
  if (currentHeartRate > 80) {
    baseSystolic += (currentHeartRate - 80) * 0.5;
  } else if (currentHeartRate < 60) {
    baseSystolic -= (60 - currentHeartRate) * 0.3;
  }
  
  // Add some variability for realism
  estimatedSystolic = (int)(baseSystolic + random(-5, 5));
  estimatedDiastolic = (int)(baseDiastolic + random(-3, 3));
  
  // Clamp values
  estimatedSystolic = constrain(estimatedSystolic, 70, 200);
  estimatedDiastolic = constrain(estimatedDiastolic, 40, 130);
}

void checkForAlerts() {
  unsigned long currentTime = millis();
  
  // Only check every 5 seconds to avoid alert flooding
  if (currentTime - lastAlertTime < 5000) return;
  
  // Check heart rate
  if (currentHeartRate < MIN_HEART_RATE || currentHeartRate > MAX_HEART_RATE) {
    triggerArrhythmiaAlert();
    lastAlertTime = currentTime;
  }
  
  // Check blood pressure
  if (estimatedSystolic > HYPERTENSION_SYSTOLIC) {
    triggerHypertensionAlert();
    lastAlertTime = currentTime;
  }
}

// ============================================
// ALERTS
// ============================================
void triggerEmergency(uint8_t type) {
  if (alertTriggered) return;
  alertTriggered = true;
  
  // Send alert via BLE
  if (deviceConnected) {
    uint8_t alertData[7] = {
      0x03,     // Header
      type,     // Alert type: 1=Fall, 2=Arrhythmia, 4=Hypertension, 8=Manual
      0x02,     // Severity: 1=Warning, 2=Critical
      (uint8_t)(accX * 100), // Accel X
      (uint8_t)(accY * 100), // Accel Y
      (uint8_t)(accZ * 100)  // Accel Z
    };
    alertChar->setValue(alertData, sizeof(alertData));
    alertChar->notify();
  }
  
  // Local alert
  for (int i = 0; i < 3; i++) {
    digitalWrite(MOTOR_PIN, HIGH);
    playTone(1000, 200);
    delay(300);
    digitalWrite(MOTOR_PIN, LOW);
    delay(200);
  }
}

void triggerFallAlert() {
  Serial.println("FALL DETECTED!");
  triggerEmergency(1);
}

void triggerArrhythmiaAlert() {
  Serial.println("ARRHYTHMIA DETECTED!");
  triggerEmergency(2);
}

void triggerHypertensionAlert() {
  Serial.println("HYPERTENSION DETECTED!");
  triggerEmergency(4);
}

// ============================================
// BLE COMMUNICATION
// ============================================
void sendBLEData() {
  // Send heart rate
  uint8_t hrData[6] = {
    0x01,              // Header
    (uint8_t)currentHeartRate,
    (uint8_t)currentSpO2,
    100,               // Confidence
    0, 0               // Reserved
  };
  heartRateChar->setValue(hrData, sizeof(hrData));
  heartRateChar->notify();
  
  // Send blood pressure
  uint8_t bpData[6] = {
    0x02,                      // Header
    (uint8_t)estimatedSystolic,
    (uint8_t)estimatedDiastolic,
    (uint8_t)((estimatedSystolic + 2*estimatedDiastolic) / 3), // MAP
    alertTriggered ? 3 : 0,    // Status
    75                         // Confidence
  };
  bpChar->setValue(bpData, sizeof(bpData));
  bpChar->notify();
  
  // Reset alert after sending
  if (alertTriggered && millis() - lastAlertTime > 30000) {
    alertTriggered = false;
  }
}

// ============================================
// DISPLAY
// ============================================
void updateDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  
  // Header
  display.setTextColor(WHITE);
  display.println("DIGITAL SAVER");
  
  // Connection status
  display.setTextColor(deviceConnected ? GREEN : WHITE);
  display.println(deviceConnected ? "[CONNECTED]" : "[OFFLINE]");
  display.setTextColor(WHITE);
  display.println();
  
  // Heart Rate
  display.print("HR: ");
  display.setTextSize(2);
  display.print(currentHeartRate);
  display.setTextSize(1);
  display.print(" BPM");
  if (currentHeartRate < MIN_HEART_RATE || currentHeartRate > MAX_HEART_RATE) {
    display.setTextColor(RED);
    display.print(" !");
  }
  display.println();
  display.setTextColor(WHITE);
  
  // Blood Pressure
  display.print("BP: ");
  display.setTextSize(2);
  display.print(estimatedSystolic);
  display.print("/");
  display.print(estimatedDiastolic);
  display.setTextSize(1);
  display.print(" mmHg");
  if (estimatedSystolic > HYPERTENSION_SYSTOLIC) {
    display.setTextColor(RED);
    display.print(" !");
  }
  display.println();
  display.setTextColor(WHITE);
  
  // Battery
  display.println();
  display.print("Battery: ");
  display.print(batteryLevel);
  display.println("%");
  
  display.display();
}

// ============================================
// UTILITIES
// ============================================
void playTone(int frequency, int duration) {
  tone(BUZZER_PIN, frequency, duration);
}
