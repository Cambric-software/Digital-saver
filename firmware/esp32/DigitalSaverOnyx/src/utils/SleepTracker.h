/*
 * Sleep Tracker Utility
 */

#ifndef SLEEP_TRACKER_H
#define SLEEP_TRACKER_H

#include <Arduino.h>

class SleepTracker {
private:
    // Last night data
    float totalSleepHours = 0;
    float deepSleepMinutes = 0;
    float remSleepMinutes = 0;
    float lightSleepMinutes = 0;
    int sleepQualityScore = 0;
    
    // Weekly history
    float weeklySleep[7] = {0};
    int weeklyIndex = 0;
    int weeklyCount = 0;
    
    // Tracking state
    bool isTracking = false;
    unsigned long sleepStartTime = 0;
    unsigned long deepSleepStart = 0;
    unsigned long lastMovement = 0;
    
public:
    SleepTracker() {}
    
    void begin();
    void startSleep();
    void endSleep();
    void update(float accelerometerMagnitude, int hrv);
    
    // Getters
    float getLastNightHours() { return totalSleepHours; }
    int getQualityScore() { return sleepQualityScore; }
    int getDeepSleepMinutes() { return (int)deepSleepMinutes; }
    int getREMMINUTES() { return (int)remSleepMinutes; }
    float* getWeeklyHistory() { return weeklySleep; }
    
    // Calculate quality score
    int calculateQualityScore(float hours, float deep, float rem);
};

#endif // SLEEP_TRACKER_H
