/*
 * Activity Tracker Implementation
 */

#include "ActivityTracker.h"
#include <math.h>

void ActivityTracker::update(float accelerometerMagnitude, int heartRate, uint32_t currentTime) {
    // Peak detection algorithm for step counting
    if (accelerometerMagnitude > STEP_THRESHOLD_HIGH && 
        lastAccelMag <= STEP_THRESHOLD_HIGH &&
        !stepInProgress) {
        // Rising edge
        stepInProgress = true;
    }
    
    if (stepInProgress && 
        accelerometerMagnitude < STEP_THRESHOLD_LOW &&
        currentTime - lastStepTime > STEP_MIN_INTERVAL) {
        // Valid step detected
        steps++;
        stepInProgress = false;
        lastStepTime = currentTime;
        
        // Update active minutes
        if (currentTime - lastStepTime > 60000) { // 1 minute of activity
            activeMinutes++;
        }
    }
    
    lastAccelMag = accelerometerMagnitude;
    
    // Update distance and calories periodically
    distanceKm = getDistanceKm(170); // Default height
    calories = getCalories(70, 170); // Default weight/height
}

float ActivityTracker::getCalories(int weightKg, int heightCm) {
    // Calculate distance
    float strideLength = heightCm * 0.414 / 100.0; // meters
    distanceKm = (steps * strideLength) / 1000.0;
    
    // Calories = distance (km) * weight (kg) * 0.5
    return distanceKm * weightKg * 0.5;
}

float ActivityTracker::getDistanceKm(int heightCm) {
    float strideLength = heightCm * 0.414 / 100.0; // meters
    return (steps * strideLength) / 1000.0;
}

void ActivityTracker::reset() {
    steps = 0;
    calories = 0;
    distanceKm = 0;
    activeMinutes = 0;
    lastStepTime = 0;
    lastAccelMag = 0;
    stepInProgress = false;
}
