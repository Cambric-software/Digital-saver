# Digital Saver Watch - Enhanced Features Guide (v3.3.0)
*Generated enhancements to add to DigitalSaverWatch.ino*

## 1. Enhanced User Profile Structure

Add to the existing UserProfile struct:

```cpp
// Enhanced User Profile Data (stored in flash)
struct EnhancedUserProfile {
    String name;            // User's name
    int age;                // User's age
    int weightKg;           // Weight in kg
    int heightCm;           // Height in cm
    String gender;          // "male" or "female"
    int targetSteps;         // Daily step goal
    int targetSleepHours;   // Sleep goal
    float maxHeartRate;      // Max safe heart rate
    float minHeartRate;     // Min safe heart rate
    
    // NEW: Medical Information
    String bloodType;        // "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"
    bool hasAllergies;        // Has known allergies
    String allergiesList;    // Comma-separated list
    bool hasMedicalConditions; // Has medical conditions
    String medicalConditionsList; // Comma-separated list
    bool hasMedications;      // Takes regular medications
    String medicationsList;   // Comma-separated list
    
    // NEW: Emergency Contacts
    String emergencyContact1Name;
    String emergencyContact1Phone;
    String emergencyContact2Name;
    String emergencyContact2Phone;
    
    // NEW: Insurance Info
    String insuranceProvider;
    String insurancePolicyNumber;
    
    // NEW: Medical Notes
    String medicalNotes;      // Any important medical notes
    
    bool profileSet;         // Has profile been configured
};
EnhancedUserProfile userProfile;
```

## 2. Enhanced Emergency System

Add these new functions after the existing `triggerEmergency()`:

```cpp
// ============================================
//           ENHANCED EMERGENCY SYSTEM
// ============================================

// Emergency types
enum EmergencyType {
    EMERGENCY_FALL,
    EMERGENCY_HEART_ATTACK,
    EMERGENCY_STROKE,
    EMERGENCY_BREATHING,
    EMERGENCY_MANUAL
};

// Critical health data package for emergencies
struct CriticalHealthPackage {
    char bloodType[4];              // "A+", "O-", etc.
    bool allergiesKnown;
    char allergiesList[256];         // Comma-separated
    bool medicalConditionsKnown;
    char medicalConditionsList[256];
    bool medicationsKnown;
    char medicationsList[256];
    char emergencyContact1[100];
    char emergencyContact2[100];
    char insuranceInfo[100];
    float currentHeartRate;
    float currentSpO2;
    bool irregularHeartbeat;
    char timestamp[32];
};

CriticalHealthPackage criticalData;

void prepareCriticalHealthPackage() {
    // Populate with current data
    strcpy(criticalData.bloodType, userProfile.bloodType.c_str());
    criticalData.allergiesKnown = userProfile.hasAllergies;
    strcpy(criticalData.allergiesList, userProfile.allergiesList.c_str());
    criticalData.medicalConditionsKnown = userProfile.hasMedicalConditions;
    strcpy(criticalData.medicalConditionsList, userProfile.medicalConditionsList.c_str());
    criticalData.medicationsKnown = userProfile.hasMedications;
    strcpy(criticalData.medicationsList, userProfile.medicationsList.c_str());
    strcpy(criticalData.emergencyContact1, 
           (userProfile.emergencyContact1Name + " " + userProfile.emergencyContact1Phone).c_str());
    strcpy(criticalData.emergencyContact2,
           (userProfile.emergencyContact2Name + " " + userProfile.emergencyContact2Phone).c_str());
    strcpy(criticalData.insuranceInfo,
           (userProfile.insuranceProvider + " - " + userProfile.insurancePolicyNumber).c_str());
    criticalData.currentHeartRate = currentHealth.heartRate;
    criticalData.currentSpO2 = currentHealth.spO2;
    criticalData.irregularHeartbeat = currentHealth.irregularHeartbeat;
    
    // Add timestamp
    time_t now = time(nullptr);
    strcpy(criticalData.timestamp, ctime(&now));
}

void triggerEnhancedEmergency(EmergencyType type) {
    emergencyMode = true;
    
    // Prepare critical data package
    prepareCriticalHealthPackage();
    
    // Vibrate pattern: SOS in Morse code
    // S: ...
    vibrate(100); delay(200); vibrate(100); delay(200); vibrate(100); delay(600);
    // O: ---
    vibrate(300); delay(200); vibrate(300); delay(200); vibrate(300); delay(600);
    // S: ...
    vibrate(100); delay(200); vibrate(100); delay(200); vibrate(100);
    
    // Show emergency message on display
    displayEmergencyMessage(type);
    
    // Log the emergency type
    Serial.print("[EMERGENCY] Triggered: ");
    switch(type) {
        case EMERGENCY_FALL: Serial.println("FALL DETECTED"); break;
        case EMERGENCY_HEART_ATTACK: Serial.println("HEART ATTACK SUSPECTED"); break;
        case EMERGENCY_STROKE: Serial.println("STROKE SUSPECTED"); break;
        case EMERGENCY_BREATHING: Serial.println("BREATHING EMERGENCY"); break;
        case EMERGENCY_MANUAL: Serial.println("MANUAL SOS"); break;
    }
    
    // BLE will send critical data to app
}

void displayEmergencyMessage(EmergencyType type) {
    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("EMERGENCY!");
    
    display.setTextSize(1);
    switch(type) {
        case EMERGENCY_FALL:
            display.println("Fall Detected");
            break;
        case EMERGENCY_HEART_ATTACK:
            display.println("Heart Emergency!");
            display.print("HR: "); display.print(currentHealth.heartRate);
            break;
        case EMERGENCY_STROKE:
            display.println("Stroke Warning!");
            break;
        case EMERGENCY_BREATHING:
            display.println("Breathing Issue");
            display.print("SpO2: "); display.print(currentHealth.spO2);
            break;
        case EMERGENCY_MANUAL:
            display.println("SOS Activated");
            break;
    }
    
    // Show blood type
    display.print("Blood: ");
    display.println(userProfile.bloodType.c_str());
    
    display.display();
}
```

## 3. Enhanced Fall Detection

Replace the existing `detectFall()` with this improved version:

```cpp
// ============================================
//           ENHANCED FALL DETECTION
// ============================================

// Fall detection variables
float lastAccelMagnitude = 1.0;
bool fallAlertSent = false;
uint32_t fallDetectionTime = 0;
bool impactDetected = false;
bool immobilityDetected = false;
uint32_t lastMovementTime = 0;

// Multi-axis fall detection
float accelVarianceX = 0;
float accelVarianceY = 0;
float accelVarianceZ = 0;
float rotationMagnitude = 0;

void updateFallDetection() {
    static float accelHistoryX[10] = {0};
    static float accelHistoryY[10] = {0};
    static float accelHistoryZ[10] = {0};
    static uint8_t historyIndex = 0;
    
    // Read accelerometer
    int16_t ax, ay, az;
    Wire.beginTransmission(MPU6050_ADDR);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)MPU6050_ADDR, (size_t)6);
    
    if (Wire.available() >= 6) {
        ax = Wire.read() << 8 | Wire.read();
        ay = Wire.read() << 8 | Wire.read();
        az = Wire.read() << 8 | Wire.read();
        
        // Convert to g (assuming +/-8g range)
        float accelX = ax / 4096.0;
        float accelY = ay / 4096.0;
        float accelZ = az / 4096.0;
        
        // Calculate magnitude
        float currentMagnitude = sqrt(accelX*accelX + accelY*accelY + accelZ*accelZ);
        
        // Calculate rotation magnitude
        rotationMagnitude = abs(accelX - lastAccelMagnitude) + abs(accelY - lastAccelMagnitude);
        
        // Update history for variance calculation
        accelHistoryX[historyIndex] = accelX;
        accelHistoryY[historyIndex] = accelY;
        accelHistoryZ[historyIndex] = accelZ;
        historyIndex = (historyIndex + 1) % 10;
        
        // Calculate variance
        accelVarianceX = calculateVariance(accelHistoryX, 10);
        accelVarianceY = calculateVariance(accelHistoryY, 10);
        accelVarianceZ = calculateVariance(accelHistoryZ, 10);
        
        uint32_t now = millis();
        
        // PHASE 1: Impact Detection
        if (currentMagnitude > FALL_THRESHOLD || abs(currentMagnitude - lastAccelMagnitude) > 1.5) {
            impactDetected = true;
            fallDetectionTime = now;
            Serial.println("[FALL] Impact detected!");
        }
        
        // PHASE 2: Free Fall Detection
        if (currentMagnitude < 0.3 && impactDetected) {
            Serial.println("[FALL] Free fall detected!");
        }
        
        // PHASE 3: Post-Fall Immobility Check
        if (impactDetected && (now - fallDetectionTime > 5000)) {
            // Check for immobility (no significant movement for 5 seconds)
            if (rotationMagnitude < 0.1 && abs(currentMagnitude - 1.0) < 0.2) {
                immobilityDetected = true;
                lastMovementTime = now;
            } else {
                // User got up
                immobilityDetected = false;
                impactDetected = false;
            }
        }
        
        // PHASE 4: Confirm Fall and Trigger Alert
        if (immobilityDetected && (now - lastMovementTime > 10000) && !fallAlertSent) {
            // Check if user is conscious (press button to cancel)
            display.clearDisplay();
            display.setTextSize(2);
            display.println("FALL DETECTED!");
            display.setTextSize(1);
            display.println("Are you OK?");
            display.println("Press any button");
            display.println("to cancel");
            display.display();
            
            // Wait 10 seconds for user response
            delay(10000);
            
            // Check if user cancelled
            if (digitalRead(BUTTON_MODE) == LOW || digitalRead(BUTTON_BACK) == LOW) {
                Serial.println("[FALL] User cancelled");
                impactDetected = false;
                immobilityDetected = false;
                fallAlertSent = false;
                return;
            }
            
            // Trigger emergency
            fallAlertSent = true;
            triggerEnhancedEmergency(EMERGENCY_FALL);
        }
        
        // Reset if user recovered
        if (fallAlertSent && rotationMagnitude > 0.5) {
            fallAlertSent = false;
            impactDetected = false;
            immobilityDetected = false;
        }
        
        lastAccelMagnitude = currentMagnitude;
    }
}

float calculateVariance(float arr[], uint8_t size) {
    float sum = 0;
    float mean = 0;
    float variance = 0;
    
    for (uint8_t i = 0; i < size; i++) {
        sum += arr[i];
    }
    mean = sum / size;
    
    sum = 0;
    for (uint8_t i = 0; i < size; i++) {
        sum += (arr[i] - mean) * (arr[i] - mean);
    }
    variance = sum / size;
    
    return variance;
}
```

## 4. Enhanced HRV with Arrhythmia Detection

Add after the existing HRV calculation:

```cpp
// ============================================
//           ENHANCED HRV & ARRHYTHMIA
// ============================================

// Arrhythmia detection
bool arrhythmiaSuspected = false;
int arrhythmiaCounter = 0;
#define ARRHYTHMIA_THRESHOLD 5  // Triggers after 5 irregular beats

// Heart rhythm states
enum HeartRhythm {
    RHYTHM_NORMAL,
    RHYTHM_TACHYCARDIA,    // HR > 100
    RHYTHM_BRADYCARDIA,     // HR < 60
    RHYTHM_ARRHYTHMIA,      // Irregular
    RHYTHM_PVC,             // Premature beats
    RHYTHM_AFIB             // Atrial fibrillation suspected
};
HeartRhythm currentRhythm = RHYTHM_NORMAL;

void analyzeHeartRhythm() {
    // Calculate RMSSD (Root Mean Square of Successive Differences)
    float rmssd = calculateRMSSD(rrIntervals, rrIndex);
    currentHealth.hrvRMSSD = rmssd;
    
    // Calculate SDNN (Standard Deviation of NN intervals)
    float sdnn = calculateSDNN(rrIntervals, rrIndex);
    currentHealth.hrvSDNN = sdnn;
    
    // Analyze for irregular heartbeat
    int irregularCount = countIrregularBeats(rrIntervals, rrIndex);
    
    if (irregularCount >= ARRHYTHMIA_THRESHOLD) {
        currentHealth.irregularHeartbeat = true;
        arrhythmiaSuspected = true;
        arrhythmiaCounter++;
        
        // Determine arrhythmia type
        if (currentHealth.heartRate > 100) {
            currentRhythm = RHYTHM_AFIB;  // Tachyarrhythmia
        } else if (currentHealth.heartRate < 60) {
            currentRhythm = RHYTHM_BRADYCARDIA;
        } else {
            currentRhythm = RHYTHM_ARRHYTHMIA;
        }
        
        // Alert if sustained
        if (arrhythmiaCounter > 10) {
            healthAI.arrhythmiaRisk = 4;  // High risk
            healthAI.warningMessage = "Sustained irregular heartbeat detected";
            
            // Optional: automatic emergency trigger for critical cases
            if (currentHealth.heartRate > 180 || currentHealth.heartRate < 40) {
                triggerEnhancedEmergency(EMERGENCY_HEART_ATTACK);
            }
        }
    } else {
        currentHealth.irregularHeartbeat = false;
        arrhythmiaSuspected = false;
        arrhythmiaCounter = max(0, arrhythmiaCounter - 1);
    }
    
    // Determine overall rhythm state
    if (!arrhythmiaSuspected) {
        if (currentHealth.heartRate > 100) {
            currentRhythm = RHYTHM_TACHYCARDIA;
        } else if (currentHealth.heartRate < 60) {
            currentRhythm = RHYTHM_BRADYCARDIA;
        } else {
            currentRhythm = RHYTHM_NORMAL;
        }
    }
}

float calculateRMSSD(float intervals[], uint8_t count) {
    if (count < 2) return 0;
    
    float sumSquaredDiff = 0;
    int diffCount = 0;
    
    for (uint8_t i = 1; i < count; i++) {
        float diff = intervals[i] - intervals[i-1];
        sumSquaredDiff += diff * diff;
        diffCount++;
    }
    
    if (diffCount == 0) return 0;
    return sqrt(sumSquaredDiff / diffCount);
}

float calculateSDNN(float intervals[], uint8_t count) {
    if (count == 0) return 0;
    
    float sum = 0;
    for (uint8_t i = 0; i < count; i++) {
        sum += intervals[i];
    }
    float mean = sum / count;
    
    float sumSquaredDiff = 0;
    for (uint8_t i = 0; i < count; i++) {
        float diff = intervals[i] - mean;
        sumSquaredDiff += diff * diff;
    }
    
    return sqrt(sumSquaredDiff / count);
}

int countIrregularBeats(float intervals[], uint8_t count) {
    if (count < 3) return 0;
    
    int irregularCount = 0;
    
    // Calculate average and standard deviation
    float sum = 0;
    for (uint8_t i = 0; i < count; i++) {
        sum += intervals[i];
    }
    float mean = sum / count;
    float sd = calculateSDNN(intervals, count);
    
    // Check for outliers (> 2 SD from mean)
    for (uint8_t i = 0; i < count; i++) {
        if (abs(intervals[i] - mean) > 2 * sd) {
            irregularCount++;
        }
    }
    
    // Check for successive differences
    for (uint8_t i = 2; i < count; i++) {
        float diff1 = abs(intervals[i-1] - intervals[i-2]);
        float diff2 = abs(intervals[i] - intervals[i-1]);
        if (abs(diff1 - diff2) > mean * 0.2) {  // 20% variation
            irregularCount++;
        }
    }
    
    return irregularCount;
}

const char* getRhythmLabel() {
    switch(currentRhythm) {
        case RHYTHM_NORMAL: return "Normal";
        case RHYTHM_TACHYCARDIA: return "Fast";
        case RHYTHM_BRADYCARDIA: return "Slow";
        case RHYTHM_ARRHYTHMIA: return "Irregular";
        case RHYTHM_PVC: return "PVC";
        case RHYTHM_AFIB: return "AFib?";
        default: return "Unknown";
    }
}
```

## 5. Enhanced BLE Data Package

Replace the existing `sendBLEData()` with:

```cpp
// ============================================
//           ENHANCED BLE DATA PACKAGE
// ============================================

// Extended data structure for BLE
struct ExtendedHealthData {
    // Basic health
    float heartRate;
    float spO2;
    float bloodPressureSys;
    float bloodPressureDia;
    float temperature;
    
    // HRV data
    float hrvRMSSD;
    float hrvSDNN;
    bool irregularHeartbeat;
    char rhythmLabel[16];
    
    // Activity
    uint32_t steps;
    float caloriesBurned;
    uint8_t activityLevel;
    
    // Fall detection
    bool fallDetected;
    
    // Battery
    uint8_t batteryLevel;
    
    // Medical ID (for emergency responders)
    char bloodType[4];
    bool allergiesKnown;
    bool medicalConditionsKnown;
    
    // Timestamp
    uint32_t timestamp;
};

ExtendedHealthData extHealthData;

void updateExtendedHealthData() {
    extHealthData.heartRate = currentHealth.heartRate;
    extHealthData.spO2 = currentHealth.spO2;
    extHealthData.bloodPressureSys = currentHealth.bloodPressureSys;
    extHealthData.bloodPressureDia = currentHealth.bloodPressureDia;
    extHealthData.temperature = currentHealth.temperature;
    extHealthData.hrvRMSSD = currentHealth.hrvRMSSD;
    extHealthData.hrvSDNN = currentHealth.hrvSDNN;
    extHealthData.irregularHeartbeat = currentHealth.irregularHeartbeat;
    strcpy(extHealthData.rhythmLabel, getRhythmLabel());
    extHealthData.steps = currentHealth.steps;
    extHealthData.caloriesBurned = currentHealth.calories;
    extHealthData.activityLevel = currentHealth.activityLevel;
    extHealthData.fallDetected = currentHealth.fallDetected;
    extHealthData.batteryLevel = getBatteryLevel();
    
    // Medical ID
    strcpy(extHealthData.bloodType, userProfile.bloodType.c_str());
    extHealthData.allergiesKnown = userProfile.hasAllergies;
    extHealthData.medicalConditionsKnown = userProfile.hasMedicalConditions;
    
    extHealthData.timestamp = millis();
}

void sendExtendedBLEData() {
    if (!deviceConnected) return;
    
    // Update the data
    updateExtendedHealthData();
    
    // Send as JSON string (max 512 bytes for BLE)
    char bleData[512];
    snprintf(bleData, sizeof(bleData),
        "{"
        "\"hr\":%.0f,\"spo2\":%.1f,\"bps\":%.0f,\"bpd\":%.0f,"
        "\"temp\":%.1f,\"rmssd\":%.2f,\"sdnn\":%.2f,"
        "\"irregular\":%d,\"rhythm\":\"%s\","
        "\"steps\":%lu,\"cal\":%.0f,\"activity\":%d,"
        "\"fall\":%d,\"batt\":%d,"
        "\"blood\":\"%s\",\"allergies\":%d,\"conditions\":%d"
        "}",
        extHealthData.heartRate,
        extHealthData.spO2,
        extHealthData.bloodPressureSys,
        extHealthData.bloodPressureDia,
        extHealthData.temperature,
        extHealthData.hrvRMSSD,
        extHealthData.hrvSDNN,
        extHealthData.irregularHeartbeat,
        extHealthData.rhythmLabel,
        extHealthData.steps,
        extHealthData.caloriesBurned,
        extHealthData.activityLevel,
        extHealthData.fallDetected,
        extHealthData.batteryLevel,
        extHealthData.bloodType,
        extHealthData.allergiesKnown,
        extHealthData.medicalConditionsKnown
    );
    
    pCharacteristic->setValue(bleData);
    pCharacteristic->notify();
}

// Battery level estimation (if using ADC)
uint8_t getBatteryLevel() {
    // For ESP32 with battery monitoring
    // This is a placeholder - implement based on your hardware
    return 100;  // Return 100% if no battery monitoring
}
```

## 6. Power Management Mode

Add to the configuration section:

```cpp
// ============================================
//           POWER MANAGEMENT
// ============================================

// Power modes
enum PowerMode {
    POWER_FULL,        // All sensors active
    POWER_SAVING,      // Reduced sampling
    POWER_ULTRA_SAVE,  // Minimal sensors
    POWER_STEALTH      // Discreet mode
};
PowerMode currentPowerMode = POWER_FULL;

// Timing for power saving
#define FULL_SAMPLE_INTERVAL 1000      // 1 second
#define SAVING_SAMPLE_INTERVAL 5000     // 5 seconds
#define ULTRA_SAMPLE_INTERVAL 30000    // 30 seconds

uint32_t getSampleInterval() {
    switch(currentPowerMode) {
        case POWER_FULL: return FULL_SAMPLE_INTERVAL;
        case POWER_SAVING: return SAVING_SAMPLE_INTERVAL;
        case POWER_ULTRA_SAVE: return ULTRA_SAMPLE_INTERVAL;
        case POWER_STEALTH: return SAVING_SAMPLE_INTERVAL;
        default: return FULL_SAMPLE_INTERVAL;
    }
}

void setPowerMode(PowerMode mode) {
    currentPowerMode = mode;
    
    switch(mode) {
        case POWER_FULL:
            // Full power
            particleSensor.setPulseAmplitudeIR(0x1F);
            particleSensor.setPulseAmplitudeRed(0x0A);
            break;
            
        case POWER_SAVING:
            // Reduce LED brightness
            particleSensor.setPulseAmplitudeIR(0x0F);
            particleSensor.setPulseAmplitudeRed(0x05);
            break;
            
        case POWER_ULTRA_SAVE:
            // Minimum brightness
            particleSensor.setPulseAmplitudeIR(0x05);
            particleSensor.setPulseAmplitudeRed(0x00);
            break;
            
        case POWER_STEALTH:
            // Turn off all indicators
            particleSensor.setPulseAmplitudeIR(0x00);
            particleSensor.setPulseAmplitudeRed(0x00);
            // Display still shows time but no health data
            break;
    }
    
    Serial.print("[POWER] Mode changed to: ");
    switch(mode) {
        case POWER_FULL: Serial.println("FULL"); break;
        case POWER_SAVING: Serial.println("SAVING"); break;
        case POWER_ULTRA_SAVE: Serial.println("ULTRA SAVE"); break;
        case POWER_STEALTH: Serial.println("STEALTH"); break;
    }
}
```

## 7. Medical ID Display Mode

Add to display modes:

```cpp
// Add to WatchMode enum:
enum WatchMode {
    MODE_CLOCK,
    MODE_HEART_RATE,
    MODE_BLOOD_PRESSURE,
    MODE_ACTIVITY,
    MODE_SLEEP,
    MODE_WEATHER,
    MODE_STEALTH,
    MODE_SETTINGS,
    MODE_MEDICAL_ID  // NEW: Shows medical info for emergency responders
};

void displayMedicalID() {
    display.clearDisplay();
    display.setTextSize(1);
    
    // Header
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("*** MEDICAL ID ***");
    
    // Blood Type - Large and visible
    display.setTextSize(2);
    display.print("Blood: ");
    display.println(userProfile.bloodType.c_str());
    
    // Allergies
    display.setTextSize(1);
    if (userProfile.hasAllergies) {
        display.print("ALLERGIES: ");
        display.println(userProfile.allergiesList.c_str());
    } else {
        display.println("Allergies: None known");
    }
    
    // Medical Conditions
    if (userProfile.hasMedicalConditions) {
        display.print("Conditions: ");
        display.println(userProfile.medicalConditionsList.c_str());
    }
    
    // Medications
    if (userProfile.hasMedications) {
        display.print("Meds: ");
        display.println(userProfile.medicationsList.c_str());
    }
    
    // Emergency Contact
    display.println("");
    display.print("Emergency: ");
    display.println(userProfile.emergencyContact1Phone.c_str());
    
    // Insurance
    display.print("Insurance: ");
    display.println(userProfile.insuranceProvider.c_str());
    
    display.display();
}
```

## Implementation Steps

1. Copy the enhanced code blocks into the appropriate sections of `DigitalSaverWatch.ino`
2. Update the version number to 3.3.0
3. Test compilation in Arduino IDE or PlatformIO
4. Upload to ESP32 and test with the app

## Notes

- Blood type information is CRITICAL for emergency responders
- The enhanced fall detection uses multi-axis analysis for better accuracy
- Arrhythmia detection is for awareness only - not a medical device
- Power modes help extend battery life during extended monitoring
- Medical ID mode can be accessed quickly by first responders
