/*
 * Emergency System Module
 * Handles fall detection, SOS, and emergency alerts
 */

#ifndef EMERGENCY_SYSTEM_H
#define EMERGENCY_SYSTEM_H

#include <Arduino.h>

enum class EmergencyType {
    NONE,
    FALL,
    SOS,
    HIGH_HEART_RATE,
    LOW_HEART_RATE,
    LOW_OXYGEN,
    AI_ALERT,
    NO_RESPONSE
};

enum class AlertLevel {
    INFO,
    WARNING,
    CRITICAL,
    EMERGENCY
};

class EmergencySystem {
private:
    char emergencyContactName[50];
    char emergencyContactPhone[20];
    
    bool isActive = false;
    unsigned long alertStartTime = 0;
    
    // Alert thresholds
    int heartRateHighThreshold = 180;
    int heartRateLowThreshold = 40;
    int spO2LowThreshold = 85;
    
    // Callbacks
    std::function<void(EmergencyType, AlertLevel)> onAlertTriggered;
    
public:
    EmergencySystem() {}
    
    void begin(const char* contactName, const char* contactPhone);
    
    void triggerFallAlert(int heartRate, int spO2, int steps);
    void triggerSOS(int heartRate, int spO2, int steps);
    void triggerHighHeartRate(int heartRate);
    void triggerLowHeartRate(int heartRate);
    void triggerLowOxygenAlert(int spO2);
    void triggerAIAlert(int riskScore, const char* patterns, int heartRate, int spO2);
    
    void update();
    void cancelAlert();
    
    bool isAlertActive() { return isActive; }
    
    void setContact(const char* name, const char* phone);
    void setThresholds(int hrHigh, int hrLow, int spO2Low);
};

class FallDetector {
private:
    // Thresholds
    float fallThreshold = 3.0;  // g
    float impactThreshold = 2.5; // g
    
    // Timing
    unsigned long fallStartTime = 0;
    unsigned long lastImpactTime = 0;
    
    // State machine
    enum FallState { NORMAL, FREE_FALL, IMPACT, POSSIBLE_FALL, CONFIRMED_FALL };
    FallState state = NORMAL;
    
    // History
    float accelHistory[10] = {0};
    uint8_t historyIndex = 0;
    
public:
    FallDetector() {}
    
    bool update(float accelX, float accelY, float accelZ, 
                float gyroX, float gyroY, float gyroZ);
    
    void reset() { state = NORMAL; }
    bool isFallDetected() { return state == CONFIRMED_FALL; }
};

class SOSHandler {
private:
    bool isActive = false;
    unsigned long sosStartTime = 0;
    int vibrationPattern = 0;
    
public:
    SOSHandler() {}
    
    void trigger();
    void update();
    void cancel();
    bool isActive() { return isActive; }
};

#endif // EMERGENCY_SYSTEM_H
