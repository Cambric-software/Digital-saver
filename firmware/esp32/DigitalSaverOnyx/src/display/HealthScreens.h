/*
 * Health Screens Module
 * Display health information on the watch
 */

#ifndef HEALTH_SCREENS_H
#define HEALTH_SCREENS_H

#include <Arduino.h>
#include <Adafruit_SSD1306.h>

class HealthScreens {
private:
    Adafruit_SSD1306* display;
    
public:
    HealthScreens(Adafruit_SSD1306* disp) : display(disp) {}
    
    // Heart Rate Screen
    void showHeartRateScreen(int bpm, int hrv, int confidence, bool irregular, int riskScore);
    
    // SpO2 Screen
    void showSpO2Screen(int spO2, int riskScore);
    
    // Blood Pressure Screen
    void showBloodPressureScreen(int systolic, int diastolic, int map, int riskScore);
    
    // Activity Screen
    void showActivityScreen(int steps, int goal, float calories, float distanceKm, int activeMinutes);
    
    // Sleep Screen
    void showSleepScreen(float hours, int quality, int deepMinutes, int remMinutes);
    
    // AI Dashboard
    void showAIDashboard(int riskScore, int patternCount, char* patterns, char* prediction);
    
    // Settings Screen
    void showSettingsScreen(int battery, bool aiEnabled, bool stealthMode);
    
    // Draw gauge
    void drawGauge(int x, int y, int width, int height, int value, int maxValue);
    
    // Draw risk indicator
    void drawRiskIndicator(int x, int y, int riskScore);
};

#endif // HEALTH_SCREENS_H
