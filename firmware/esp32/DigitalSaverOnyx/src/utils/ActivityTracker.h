/*
 * Activity Tracker Utility
 * Tracks steps, calories, and activity levels
 */

#ifndef ACTIVITY_TRACKER_H
#define ACTIVITY_TRACKER_H

#include <Arduino.h>

class ActivityTracker {
private:
    int steps = 0;
    int goalSteps = 10000;
    float calories = 0;
    float distanceKm = 0;
    int activeMinutes = 0;
    
    // Step detection state
    uint32_t lastStepTime = 0;
    float lastAccelMag = 0;
    bool stepInProgress = false;
    
    // Constants
    const float STEP_THRESHOLD_HIGH = 1.5;
    const float STEP_THRESHOLD_LOW = 0.8;
    const uint32_t STEP_MIN_INTERVAL = 250; // ms
    
public:
    ActivityTracker() {}
    
    void begin(int dailyGoal = 10000) {
        goalSteps = dailyGoal;
        Serial.println("[ACTIVITY] Activity tracker initialized");
    }
    
    void update(float accelerometerMagnitude, int heartRate, uint32_t currentTime);
    
    // Getters
    int getSteps() { return steps; }
    int getGoalSteps() { return goalSteps; }
    float getCalories() { return calories; }
    float getDistanceKm() { return distanceKm; }
    int getActiveMinutes() { return activeMinutes; }
    
    // Calculate calories
    float getCalories(int weightKg, int heightCm);
    float getDistanceKm(int heightCm);
    
    void reset();
    void addSteps(int additional) { steps += additional; }
    
    int* getDailyHistory() { return nullptr; } // TODO: Implement
};

#endif // ACTIVITY_TRACKER_H
