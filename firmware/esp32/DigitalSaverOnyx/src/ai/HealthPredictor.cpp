/*
 * Health Predictor Implementation
 */

#include "HealthPredictor.h"

void HealthPredictor::begin() {
    initialized = true;
    historyCount = 0;
    historyIndex = 0;
    strcpy(nextPrediction, "Collecting data...");
    
    Serial.println("[PREDICTOR] Health predictor initialized");
}

void HealthPredictor::update(HealthReading reading, int* activityHistory, float* sleepHistory) {
    if (!initialized) return;
    
    // Simple prediction based on current trends
    int avgHRV = 0, hrvCount = 0;
    int avgSteps = 0;
    float avgSleep = 0;
    
    for (int i = 0; i < min(historyCount, 7); i++) {
        if (dailyHRV[i] > 0) {
            avgHRV += dailyHRV[i];
            hrvCount++;
        }
        avgSteps += dailySteps[i];
        avgSleep += dailySleep[i];
    }
    
    if (hrvCount > 0) avgHRV /= hrvCount;
    avgSteps /= max(historyCount, 1);
    avgSleep /= max(historyCount, 1);
    
    // Generate prediction
    if (historyCount < 3) {
        strcpy(nextPrediction, "Need more data");
    } else if (avgHRV > 0 && avgHRV < 30) {
        strcpy(nextPrediction, "High stress detected");
    } else if (avgSteps < 5000) {
        strcpy(nextPrediction, "Need more activity");
    } else if (avgSleep < 6) {
        strcpy(nextPrediction, "Sleep more tonight");
    } else {
        strcpy(nextPrediction, "Health stable");
    }
}

int HealthPredictor::getActivityTrend() {
    if (historyCount < 5) return 0;
    
    int recent = 0, older = 0;
    for (int i = 0; i < 3; i++) {
        recent += dailySteps[(historyIndex - 1 - i + 7) % 7];
    }
    for (int i = 3; i < 5; i++) {
        older += dailySteps[(historyIndex - 1 - i + 7) % 7];
    }
    
    if (recent > older * 1.1) return 1;  // Improving
    if (recent < older * 0.9) return -1; // Declining
    return 0; // Stable
}

int HealthPredictor::getSleepTrend() {
    if (historyCount < 5) return 0;
    
    float recent = 0, older = 0;
    for (int i = 0; i < 3; i++) {
        recent += dailySleep[(historyIndex - 1 - i + 7) % 7];
    }
    for (int i = 3; i < 5; i++) {
        older += dailySleep[(historyIndex - 1 - i + 7) % 7];
    }
    
    if (recent > older * 1.1) return 1;
    if (recent < older * 0.9) return -1;
    return 0;
}

int HealthPredictor::getStressTrend() {
    if (historyCount < 5) return 0;
    
    int recent = 0, older = 0, count = 0;
    for (int i = 0; i < 3; i++) {
        if (dailyHRV[(historyIndex - 1 - i + 7) % 7] > 0) {
            recent += dailyHRV[(historyIndex - 1 - i + 7) % 7];
            count++;
        }
    }
    recent /= max(count, 1);
    
    count = 0;
    for (int i = 3; i < 5; i++) {
        if (dailyHRV[(historyIndex - 1 - i + 7) % 7] > 0) {
            older += dailyHRV[(historyIndex - 1 - i + 7) % 7];
            count++;
        }
    }
    older /= max(count, 1);
    
    if (recent > older * 1.2) return 1; // Improving (higher HRV = lower stress)
    if (recent < older * 0.8) return -1; // Declining
    return 0;
}
