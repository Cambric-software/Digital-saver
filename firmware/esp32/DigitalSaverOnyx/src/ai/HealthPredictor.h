/*
 * Health Predictor Module
 * Predicts health trends based on historical data
 */

#ifndef HEALTH_PREDICTOR_H
#define HEALTH_PREDICTOR_H

#include <Arduino.h>

class HealthPredictor {
private:
    bool initialized = false;
    
    // Activity history (last 7 days)
    int dailySteps[7] = {0};
    float dailyCalories[7] = {0};
    float dailySleep[7] = {0};
    int dailyHRV[7] = {0};
    
    int historyIndex = 0;
    int historyCount = 0;
    
    // Predictions
    char nextPrediction[100];
    
public:
    HealthPredictor() {}
    
    void begin();
    void update(HealthReading reading, int* activityHistory, float* sleepHistory);
    
    char* getNextPrediction() { return nextPrediction; }
    
    // Trend analysis
    int getActivityTrend();
    int getSleepTrend();
    int getStressTrend();
};

#endif // HEALTH_PREDICTOR_H
