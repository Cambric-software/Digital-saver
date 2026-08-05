/*
 * Emergency System Implementation
 */

#include "EmergencySystem.h"

void EmergencySystem::begin(const char* contactName, const char* contactPhone) {
    strncpy(emergencyContactName, contactName, sizeof(emergencyContactName) - 1);
    strncpy(emergencyContactPhone, contactPhone, sizeof(emergencyContactPhone) - 1);
    
    Serial.println("[EMERGENCY] Emergency system initialized");
    Serial.printf("[EMERGENCY] Contact: %s - %s\n", emergencyContactName, emergencyContactPhone);
}

void EmergencySystem::triggerFallAlert(int heartRate, int spO2, int steps) {
    if (isActive) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.println("[EMERGENCY] FALL DETECTED!");
    Serial.printf("[EMERGENCY] HR: %d, SpO2: %d%%, Steps: %d\n", heartRate, spO2, steps);
    
    // Flash red LED
    // digitalWrite(Pins::LED_RED, HIGH);
    
    // Vibration pattern
    // TODO: Trigger vibration motor
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::FALL, AlertLevel::EMERGENCY);
    }
}

void EmergencySystem::triggerSOS(int heartRate, int spO2, int steps) {
    if (isActive) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.println("[EMERGENCY] SOS TRIGGERED BY USER!");
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::SOS, AlertLevel::EMERGENCY);
    }
}

void EmergencySystem::triggerHighHeartRate(int heartRate) {
    if (isActive) return;
    if (heartRate < heartRateHighThreshold) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.printf("[EMERGENCY] HIGH HEART RATE: %d BPM\n", heartRate);
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::HIGH_HEART_RATE, AlertLevel::WARNING);
    }
}

void EmergencySystem::triggerLowHeartRate(int heartRate) {
    if (isActive) return;
    if (heartRate > heartRateLowThreshold) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.printf("[EMERGENCY] LOW HEART RATE: %d BPM\n", heartRate);
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::LOW_HEART_RATE, AlertLevel::WARNING);
    }
}

void EmergencySystem::triggerLowOxygenAlert(int spO2) {
    if (isActive) return;
    if (spO2 > spO2LowThreshold) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.printf("[EMERGENCY] LOW OXYGEN: %d%%\n", spO2);
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::LOW_OXYGEN, AlertLevel::CRITICAL);
    }
}

void EmergencySystem::triggerAIAlert(int riskScore, const char* patterns, int heartRate, int spO2) {
    if (isActive) return;
    
    isActive = true;
    alertStartTime = millis();
    
    Serial.printf("[EMERGENCY] AI ALERT! Risk: %d%%\n", riskScore);
    Serial.printf("[EMERGENCY] Patterns: %s\n", patterns);
    
    if (onAlertTriggered) {
        onAlertTriggered(EmergencyType::AI_ALERT, AlertLevel::CRITICAL);
    }
}

void EmergencySystem::update() {
    // Auto-cancel after 5 minutes if no response
    if (isActive && (millis() - alertStartTime > 300000)) {
        // TODO: Actually send alert and cancel
        isActive = false;
    }
}

void EmergencySystem::cancelAlert() {
    isActive = false;
    Serial.println("[EMERGENCY] Alert cancelled");
}

void EmergencySystem::setContact(const char* name, const char* phone) {
    strncpy(emergencyContactName, name, sizeof(emergencyContactName) - 1);
    strncpy(emergencyContactPhone, phone, sizeof(emergencyContactPhone) - 1);
}

void EmergencySystem::setThresholds(int hrHigh, int hrLow, int spO2Low) {
    heartRateHighThreshold = hrHigh;
    heartRateLowThreshold = hrLow;
    spO2LowThreshold = spO2Low;
}

// Fall Detector Implementation
bool FallDetector::update(float accelX, float accelY, float accelZ,
                         float gyroX, float gyroY, float gyroZ) {
    // Calculate total acceleration magnitude
    float magnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    
    // Store in history
    accelHistory[historyIndex] = magnitude;
    historyIndex = (historyIndex + 1) % 10;
    
    unsigned long now = millis();
    
    switch (state) {
        case NORMAL:
            // Check for free fall (low acceleration for ~100-300ms)
            if (magnitude < 0.3) {
                state = FREE_FALL;
                fallStartTime = now;
            }
            break;
            
        case FREE_FALL:
            // Check if free fall continues
            if (magnitude > fallThreshold) {
                // Impact detected
                state = IMPACT;
                lastImpactTime = now;
            } else if (now - fallStartTime > 500) {
                // Too long in free fall, probably not a fall
                state = NORMAL;
            }
            break;
            
        case IMPACT:
            // Check for post-impact stillness (indicates fall vs stumble)
            if (now - lastImpactTime > 200) {
                // Calculate average recent acceleration
                float avgRecent = 0;
                for (int i = 0; i < 5; i++) {
                    avgRecent += accelHistory[(historyIndex - i + 10) % 10];
                }
                avgRecent /= 5;
                
                // Very still after impact = likely fall
                if (avgRecent < 0.3) {
                    state = POSSIBLE_FALL;
                } else {
                    state = NORMAL; // Probably just stumbled
                }
            }
            break;
            
        case POSSIBLE_FALL:
            // Wait a moment to see if person gets up (LOC scenario)
            if (now - lastImpactTime > 3000) {
                // No movement for 3 seconds = confirmed fall with LOC
                state = CONFIRMED_FALL;
            } else {
                // Check for recovery (movement)
                if (magnitude > 0.8) {
                    // Person got up
                    state = NORMAL;
                }
            }
            break;
            
        case CONFIRMED_FALL:
            // Fall detected - wait for reset
            break;
    }
    
    return (state == CONFIRMED_FALL);
}

// SOS Handler Implementation
void SOSHandler::trigger() {
    isActive = true;
    sosStartTime = millis();
    vibrationPattern = 0;
    
    Serial.println("[SOS] SOS triggered!");
}

void SOSHandler::update() {
    if (!isActive) return;
    
    // SOS Morse code: ... --- ...
    unsigned long elapsed = millis() - sosStartTime;
    uint8_t pattern = (elapsed / 1000) % 10;
    
    // 0-1: S (...)
    // 2: pause
    // 3-5: O (---)
    // 6: pause
    // 7-9: S (...)
    
    bool shouldVibrate = false;
    
    switch (pattern) {
        case 0: case 1: case 2: // First S
            shouldVibrate = (pattern < 2);
            break;
        case 3: case 4: case 5: // O
            shouldVibrate = true;
            break;
        case 6: case 7: case 8: // Second S
            shouldVibrate = (pattern >= 7);
            break;
    }
    
    // Control vibration motor
    // digitalWrite(Pins::VIBRATION_MOTOR, shouldVibration ? HIGH : LOW);
    
    // Cancel after 30 seconds
    if (elapsed > 30000) {
        cancel();
    }
}

void SOSHandler::cancel() {
    isActive = false;
    // digitalWrite(Pins::VIBRATION_MOTOR, LOW);
    Serial.println("[SOS] SOS cancelled");
}
