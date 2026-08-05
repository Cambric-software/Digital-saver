/*
 * Pattern Analyzer Implementation
 */

#include "PatternAnalyzer.h"

void PatternAnalyzer::begin() {
    initialized = true;
    patternCount = 0;
    consecutiveHighHR = 0;
    consecutiveLowHR = 0;
    consecutiveLowSpO2 = 0;
    
    Serial.println("[PATTERN] Pattern analyzer initialized");
}

void PatternAnalyzer::update(HealthReading reading, HealthPattern* aiPatterns, int riskScore) {
    if (!initialized) return;
    
    // Track consecutive readings
    if (reading.heartRate > 100) {
        consecutiveHighHR++;
        consecutiveLowHR = 0;
    } else if (reading.heartRate < 50 && reading.heartRate > 0) {
        consecutiveLowHR++;
        consecutiveHighHR = 0;
    } else {
        consecutiveHighHR = 0;
        consecutiveLowHR = 0;
    }
    
    if (reading.spO2 > 0 && reading.spO2 < 94) {
        consecutiveLowSpO2++;
    } else {
        consecutiveLowSpO2 = 0;
    }
    
    // Detect patterns based on consecutive readings
    if (consecutiveHighHR >= 10) {
        patterns[patternCount % 20] = {
            PatternType::TACHYCARDIA,
            min(consecutiveHighHR / 5, 10),
            millis(),
            consecutiveHighHR,
            "Elevated heart rate"
        };
        patternCount++;
        consecutiveHighHR = 0;
    }
    
    if (consecutiveLowHR >= 10) {
        patterns[patternCount % 20] = {
            PatternType::BRADYCARDIA,
            min(consecutiveLowHR / 5, 10),
            millis(),
            consecutiveLowHR,
            "Low heart rate"
        };
        patternCount++;
        consecutiveLowHR = 0;
    }
    
    if (consecutiveLowSpO2 >= 10) {
        patterns[patternCount % 20] = {
            PatternType::HYPOXIA,
            min(consecutiveLowSpO2 / 5, 10),
            millis(),
            consecutiveLowSpO2,
            "Low blood oxygen"
        };
        patternCount++;
        consecutiveLowSpO2 = 0;
    }
    
    if (reading.irregularBeat) {
        patterns[patternCount % 20] = {
            PatternType::ARRHYTHMIA,
            8,
            millis(),
            1,
            "Irregular heartbeat"
        };
        patternCount++;
    }
}
