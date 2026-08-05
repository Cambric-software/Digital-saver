/*
 * Onyx Smart AI Implementation - 8x Enhanced Intelligence
 */

#include "OnyxSmartAI.h"

void OnyxSmartAI::begin() {
    initialized = true;
    currentRiskScore = 0;
    historyCount = 0;
    historyIndex = 0;
    patternCount = 0;
    
    Serial.println("[AI] Onyx Smart AI v8 initialized");
    Serial.printf("[AI] Intelligence Level: %d (Enhanced)\n", AI_INTELLIGENCE_LEVEL);
    Serial.printf("[AI] History buffer: %d readings\n", AI_HISTORY_SIZE);
    Serial.printf("[AI] Max patterns: %d\n", AI_PATTERNS_MAX);
}

void OnyxSmartAI::setUserProfile(int age, int weight, int height, char gender, const char* bloodType) {
    userAge = age;
    userWeight = weight;
    userHeight = height;
    userGender = gender;
    strncpy(userBloodType, bloodType, 3);
    
    Serial.printf("[AI] Profile updated: Age=%d, Weight=%dkg, Height=%dcm\n", age, weight, height);
}

void OnyxSmartAI::setMedicalConditions(bool heart, bool diabetes, bool hypertension, bool asthma) {
    hasHeartCondition = heart;
    hasDiabetes = diabetes;
    hasHypertension = hypertension;
    hasAsthma = asthma;
    
    Serial.println("[AI] Medical conditions updated");
}

void OnyxSmartAI::analyze(HealthReading reading) {
    if (!initialized || !aiEnabled) return;
    
    // Add to history
    history[historyIndex] = reading;
    historyIndex = (historyIndex + 1) % AI_HISTORY_SIZE;
    if (historyCount < AI_HISTORY_SIZE) historyCount++;
    
    // Run 8x analysis modules
    analyzeHeartRate8x(reading);
    analyzeOxygen8x(reading);
    analyzeActivity8x(reading);
    analyzePattern8x(reading);
    
    // Update risk score periodically
    unsigned long now = millis();
    if (now - lastRiskUpdate >= riskUpdateInterval) {
        lastRiskUpdate = now;
        updateRiskScore();
    }
}

void OnyxSmartAI::analyzeHeartRate8x(HealthReading reading) {
    int hr = reading.heartRate;
    int hrv = reading.hrv;
    
    if (hr <= 0) return;
    
    // Calculate age-adjusted thresholds
    int maxHR = 220 - userAge;
    int riskScore = 0;
    
    // Heart rate risk factors (8x enhanced)
    if (hr > maxHR * 0.95) {
        riskScore = 40;
        addPattern("Critical_Tachycardia", 9);
    } else if (hr > maxHR * 0.85) {
        riskScore = 20;
        addPattern("High_Tachycardia", 6);
    } else if (hr < 40) {
        riskScore = 45;
        addPattern("Critical_Bradycardia", 9);
    } else if (hr < 50) {
        riskScore = 15;
        addPattern("Low_Bradycardia", 5);
    }
    
    // HRV analysis (very sensitive with 8x)
    if (hrv > 0) {
        if (hrv < 15) {
            riskScore += 30;
            addPattern("Critical_Stress", 8);
        } else if (hrv < 25) {
            riskScore += 15;
            addPattern("High_Stress", 5);
        } else if (hrv > 80) {
            riskScore -= 15; // Good!
            addPattern("Excellent_Recovery", 1);
        } else if (hrv > 60) {
            riskScore -= 10;
        }
    }
    
    // Irregular heartbeat (A-Fib indicator)
    if (reading.irregularBeat) {
        riskScore += 35;
        addPattern("Irregular_Beat", 8);
    }
    
    // Medical condition modifiers
    if (hasHeartCondition) {
        riskScore = (riskScore * 130) / 100; // 30% increase
    }
    if (hasHypertension) {
        riskScore = (riskScore * 120) / 100; // 20% increase
    }
    
    // Trend analysis
    if (historyCount >= 10) {
        int recentAvg = 0;
        for (int i = 0; i < 5; i++) {
            int idx = (historyIndex - 1 - i + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            recentAvg += history[idx].heartRate;
        }
        recentAvg /= 5;
        
        if (recentAvg > hr * 1.2) {
            riskScore += 15;
            addPattern("HR_Accelerating", 6);
        }
    }
    
    Serial.printf("[AI-HR] HR:%d HRV:%d Risk:+%d\n", hr, hrv, riskScore);
}

void OnyxSmartAI::analyzeOxygen8x(HealthReading reading) {
    int spO2 = reading.spO2;
    
    if (spO2 <= 0) return;
    
    int riskScore = 0;
    
    // SpO2 thresholds (8x enhanced sensitivity)
    if (spO2 < 85) {
        riskScore = 60;
        addPattern("Critical_Hypoxia", 10);
    } else if (spO2 < 90) {
        riskScore = 40;
        addPattern("Low_Hypoxia", 7);
    } else if (spO2 < 94) {
        riskScore = 15;
        addPattern("Borderline_Oxygen", 4);
    }
    
    // Trend detection
    if (historyCount >= 10) {
        int dropping = 0;
        for (int i = 0; i < 9; i++) {
            int idx1 = (historyIndex - 1 - i + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            int idx2 = (historyIndex - 1 - i - 1 + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            if (history[idx1].spO2 > 0 && history[idx2].spO2 > 0 &&
                history[idx1].spO2 < history[idx2].spO2) {
                dropping++;
            }
        }
        
        if (dropping >= 7) {
            riskScore += 20;
            addPattern("SpO2_Dropping", 7);
        }
    }
    
    // Low perfusion check (based on accelerometer)
    if (reading.accelerometerMagnitude < 0.5) {
        riskScore = (riskScore * 120) / 100;
    }
    
    Serial.printf("[AI-O2] SpO2:%d%% Risk:+%d\n", spO2, riskScore);
}

void OnyxSmartAI::analyzeActivity8x(HealthReading reading) {
    // Activity level based on accelerometer
    float activity = reading.accelerometerMagnitude;
    int hr = reading.heartRate;
    
    // Calculate BMR
    double bmr;
    if (userGender == 'F') {
        bmr = (10.0 * userWeight) + (6.25 * userHeight) - (5.0 * userAge) - 161;
    } else {
        bmr = (10.0 * userWeight) + (6.25 * userHeight) - (5.0 * userAge) + 5;
    }
    
    // Calculate activity multiplier
    double activityMultiplier = 1.0;
    if (activity > 2.0 || hr > 120) {
        activityMultiplier = 2.2; // Intense
        addPattern("Intense_Activity", 2);
    } else if (activity > 1.0 || hr > 100) {
        activityMultiplier = 1.8; // Active
    } else if (activity > 0.3 || hr > 80) {
        activityMultiplier = 1.5; // Moderate
    } else if (activity > 0.1) {
        activityMultiplier = 1.3; // Light
    }
    
    // Calories per minute
    double caloriesPerMinute = (bmr * activityMultiplier) / 1440;
    
    Serial.printf("[AI-ACT] Activity:%.1f Cal/min:%.2f\n", activity, caloriesPerMinute);
}

void OnyxSmartAI::analyzePattern8x(HealthReading reading) {
    // Pattern detection from history
    
    // 1. Tachycardia pattern (heart rate > 100 for 8+ of last 10 readings)
    if (historyCount >= 10) {
        int rapidCount = 0;
        for (int i = 0; i < 10; i++) {
            int idx = (historyIndex - 1 - i + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            if (history[idx].heartRate > 100) rapidCount++;
        }
        if (rapidCount >= 8) {
            addPattern("Tachycardia_Episode", 8);
        }
    }
    
    // 2. Hypoxia pattern (SpO2 < 94 for 4+ of last 5 readings)
    if (historyCount >= 5) {
        int lowO2Count = 0;
        for (int i = 0; i < 5; i++) {
            int idx = (historyIndex - 1 - i + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            if (history[idx].spO2 > 0 && history[idx].spO2 < 94) lowO2Count++;
        }
        if (lowO2Count >= 4) {
            addPattern("Hypoxia_Pattern", 9);
        }
    }
    
    // 3. Chronic stress (low HRV for 25+ of last 30 readings)
    if (historyCount >= 30) {
        int lowHrvCount = 0;
        for (int i = 0; i < 30; i++) {
            int idx = (historyIndex - 1 - i + AI_HISTORY_SIZE) % AI_HISTORY_SIZE;
            if (history[idx].hrv > 0 && history[idx].hrv < 30) lowHrvCount++;
        }
        if (lowHrvCount >= 25) {
            addPattern("Chronic_Stress", 6);
        }
    }
}

void OnyxSmartAI::addPattern(const char* name, int severity) {
    // Check if pattern already exists
    for (int i = 0; i < patternCount; i++) {
        if (strcmp(patterns[i].name, name) == 0) {
            patterns[i].occurrenceCount++;
            patterns[i].lastSeen = millis();
            patterns[i].severity = max(patterns[i].severity, severity);
            return;
        }
    }
    
    // Add new pattern
    if (patternCount < AI_PATTERNS_MAX) {
        strncpy(patterns[patternCount].name, name, 29);
        patterns[patternCount].name[29] = '\0';
        patterns[patternCount].occurrenceCount = 1;
        patterns[patternCount].lastSeen = millis();
        patterns[patternCount].severity = severity;
        patterns[patternCount].active = true;
        patternCount++;
        
        Serial.printf("[AI-PTN] New pattern: %s (severity: %d)\n", name, severity);
    }
}

void OnyxSmartAI::updateRiskScore() {
    int totalRisk = 0;
    int factorCount = 0;
    
    // Active patterns contribute to risk
    for (int i = 0; i < patternCount; i++) {
        unsigned long age = millis() - patterns[i].lastSeen;
        if (age < patternTimeout) {
            totalRisk += patterns[i].severity * 10;
            factorCount++;
        }
    }
    
    // Recent history risk
    for (int i = max(0, historyCount - 30); i < historyCount; i++) {
        int hrRisk = 0;
        if (history[i].heartRate > 100) hrRisk = 10;
        if (history[i].heartRate > 120) hrRisk = 20;
        if (history[i].irregularBeat) hrRisk += 15;
        
        int o2Risk = 0;
        if (history[i].spO2 > 0 && history[i].spO2 < 94) o2Risk = 10;
        if (history[i].spO2 > 0 && history[i].spO2 < 90) o2Risk = 25;
        
        totalRisk += hrRisk + o2Risk;
        factorCount++;
    }
    
    // Normalize
    currentRiskScore = factorCount > 0 ? totalRisk / factorCount : 0;
    currentRiskScore = constrain(currentRiskScore, 0, 100);
    
    Serial.printf("[AI-RISK] Score: %d%%\n", currentRiskScore);
}

bool OnyxSmartAI::shouldAlert() {
    if (currentRiskScore > AI_RISK_THRESHOLD) return true;
    
    // Check for high severity patterns
    for (int i = 0; i < patternCount; i++) {
        unsigned long age = millis() - patterns[i].lastSeen;
        if (age < patternTimeout && patterns[i].severity >= 8 && patterns[i].occurrenceCount >= 2) {
            return true;
        }
    }
    
    return false;
}

void OnyxSmartAI::getActivePatterns(char* output, int maxLen) {
    int pos = 0;
    for (int i = 0; i < patternCount && pos < maxLen - 30; i++) {
        unsigned long age = millis() - patterns[i].lastSeen;
        if (age < patternTimeout) {
            int written = snprintf(output + pos, maxLen - pos, "%s(%d) ", 
                                   patterns[i].name, patterns[i].severity);
            pos += written;
        }
    }
}
