/*
 * Onyx Smart AI - 8x Enhanced Intelligence
 * Advanced on-device AI for health monitoring
 */

#ifndef ONYX_SMART_AI_H
#define ONYX_SMART_AI_H

#include <Arduino.h>

// AI Configuration
#define AI_INTELLIGENCE_LEVEL 8
#define AI_HISTORY_SIZE 1440
#define AI_PATTERNS_MAX 50
#define AI_RISK_THRESHOLD 70

// Health reading structure
struct HealthReading {
    unsigned long timestamp;
    int heartRate;
    int spO2;
    int hrv;
    float accelerometerMagnitude;
    bool irregularBeat;
};

// Health pattern structure
struct HealthPattern {
    char name[30];
    int occurrenceCount;
    unsigned long lastSeen;
    int severity;
    bool active;
};

class OnyxSmartAI {
private:
    bool initialized = false;
    bool aiEnabled = true;
    
    // User profile
    int userAge = 30;
    int userWeight = 70;
    int userHeight = 170;
    char userGender = 'M';
    char userBloodType[4] = "O+";
    
    // Medical conditions
    bool hasHeartCondition = false;
    bool hasDiabetes = false;
    bool hasHypertension = false;
    bool hasAsthma = false;
    
    // History
    HealthReading history[AI_HISTORY_SIZE];
    int historyIndex = 0;
    int historyCount = 0;
    
    // Patterns
    HealthPattern patterns[AI_PATTERNS_MAX];
    int patternCount = 0;
    
    // Risk assessment
    int currentRiskScore = 0;
    unsigned long lastRiskUpdate = 0;
    unsigned long riskUpdateInterval = 60000; // 1 minute
    
    // Pattern active timeout (5 minutes)
    unsigned long patternTimeout = 300000;
    
public:
    OnyxSmartAI() {}
    
    void begin();
    void setUserProfile(int age, int weight, int height, char gender, const char* bloodType);
    void setMedicalConditions(bool heart, bool diabetes, bool hypertension, bool asthma);
    
    void analyze(HealthReading reading);
    
    // Analysis functions
    void analyzeHeartRate8x(HealthReading reading);
    void analyzeOxygen8x(HealthReading reading);
    void analyzeActivity8x(HealthReading reading);
    void analyzePattern8x(HealthReading reading);
    
    // Risk calculation
    void updateRiskScore();
    bool shouldAlert();
    
    // Pattern management
    void addPattern(const char* name, int severity);
    void updatePatterns();
    void getActivePatterns(char* output, int maxLen);
    
    // Getters
    int getRiskScore() { return currentRiskScore; }
    int getPatternCount() { return patternCount; }
    bool isEnabled() { return aiEnabled; }
    void enable() { aiEnabled = true; }
    void disable() { aiEnabled = false; }
    HealthPattern* getCurrentPatterns() { return patterns; }
};

#endif // ONYX_SMART_AI_H
