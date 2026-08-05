/*
 * Health Screens Implementation
 */

#include "HealthScreens.h"

void HealthScreens::showHeartRateScreen(int bpm, int hrv, int confidence, bool irregular, int riskScore) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("HEART RATE");
    
    // BPM large display
    display->setTextSize(3);
    char bpmStr[6];
    snprintf(bpmStr, sizeof(bpmStr), "%d", bpm);
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(bpmStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((128 - w) / 2, 12);
    display->print(bpmStr);
    
    display->setTextSize(1);
    display->setCursor((128 - w) / 2 + w + 2, 24);
    display->print("BPM");
    
    // HRV
    display->setCursor(0, 35);
    display->print("HRV:");
    char hrvStr[8];
    snprintf(hrvStr, sizeof(hrvStr), "%d ms", hrv);
    display->print(hrvStr);
    
    // Irregular indicator
    if (irregular) {
        display->setCursor(0, 45);
        display->print("! IRREGULAR");
    }
    
    // Confidence
    display->setCursor(0, 55);
    display->print("Confidence:");
    display->print(confidence);
    display->print("%");
    
    // Risk indicator
    drawRiskIndicator(100, 0, riskScore);
}

void HealthScreens::showSpO2Screen(int spO2, int riskScore) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("BLOOD OXYGEN");
    
    // SpO2 large display
    display->setTextSize(3);
    char spo2Str[6];
    snprintf(spo2Str, sizeof(spo2Str), "%d", spO2);
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(spo2Str, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((128 - w) / 2, 15);
    display->print(spo2Str);
    
    display->setTextSize(2);
    display->setCursor((128 - w) / 2 + w + 2, 22);
    display->print("%");
    
    // Status
    display->setTextSize(1);
    display->setCursor(0, 40);
    if (spO2 >= 95) {
        display->print("STATUS: NORMAL");
    } else if (spO2 >= 90) {
        display->print("STATUS: LOW");
    } else {
        display->print("STATUS: CRITICAL!");
    }
    
    // Gauge
    display->setCursor(0, 50);
    display->print("Target: 95-100%");
    
    // Risk indicator
    drawRiskIndicator(100, 0, riskScore);
}

void HealthScreens::showBloodPressureScreen(int systolic, int diastolic, int map, int riskScore) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("BLOOD PRESSURE");
    
    // BP display
    display->setTextSize(2);
    char bpStr[12];
    snprintf(bpStr, sizeof(bpStr), "%d/%d", systolic, diastolic);
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(bpStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((128 - w) / 2, 15);
    display->print(bpStr);
    
    display->setTextSize(1);
    display->setCursor(0, 35);
    display->print("mmHg");
    
    // MAP
    display->setCursor(0, 45);
    display->print("MAP:");
    display->print(map);
    display->print(" mmHg");
    
    // Category
    display->setCursor(0, 55);
    if (systolic < 120) {
        display->print("Category: NORMAL");
    } else if (systolic < 130) {
        display->print("Category: ELEVATED");
    } else if (systolic < 140) {
        display->print("Category: HIGH STG1");
    } else {
        display->print("Category: HIGH STG2");
    }
    
    drawRiskIndicator(100, 0, riskScore);
}

void HealthScreens::showActivityScreen(int steps, int goal, float calories, float distanceKm, int activeMinutes) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("ACTIVITY");
    
    // Steps
    display->setTextSize(2);
    char stepsStr[12];
    snprintf(stepsStr, sizeof(stepsStr), "%d", steps);
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(stepsStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((128 - w) / 2, 10);
    display->print(stepsStr);
    
    display->setTextSize(1);
    display->setCursor(0, 28);
    display->print("Steps / Goal:");
    display->print(goal);
    
    // Progress bar
    int progress = (steps * 120) / goal;
    if (progress > 120) progress = 120;
    display->drawRect(4, 36, 120, 8, SSD1306_WHITE);
    if (progress > 0) display->fillRect(4, 36, progress, 8, SSD1306_WHITE);
    
    // Calories and distance
    display->setCursor(0, 48);
    display->print("Cal:");
    display->print((int)calories);
    
    display->setCursor(64, 48);
    display->print("Dist:");
    display->print(distanceKm, 1);
    display->print("km");
    
    // Active minutes
    display->setCursor(0, 56);
    display->print("Active:");
    display->print(activeMinutes);
    display->print("min");
}

void HealthScreens::showSleepScreen(float hours, int quality, int deepMinutes, int remMinutes) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("SLEEP");
    
    // Hours
    display->setTextSize(3);
    char hoursStr[8];
    snprintf(hoursStr, sizeof(hoursStr), "%.1f", hours);
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(hoursStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((128 - w) / 2, 10);
    display->print(hoursStr);
    
    display->setTextSize(1);
    display->setCursor((128 - w) / 2 + w + 2, 18);
    display->print("hrs");
    
    // Quality score
    display->setCursor(0, 32);
    display->print("Quality:");
    display->print(quality);
    display->print("%");
    
    // Stages
    display->setCursor(0, 42);
    display->print("Deep:");
    display->print(deepMinutes);
    display->print("min");
    
    display->setCursor(64, 42);
    display->print("REM:");
    display->print(remMinutes);
    display->print("min");
    
    // Recommendation
    display->setCursor(0, 54);
    if (hours >= 7) {
        display->print("Great sleep!");
    } else if (hours >= 6) {
        display->print("Try 7-8 hours");
    } else {
        display->print("Need more rest");
    }
}

void HealthScreens::showAIDashboard(int riskScore, int patternCount, char* patterns, char* prediction) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("AI DASHBOARD");
    
    // Risk gauge
    display->setCursor(0, 10);
    display->print("Risk Score:");
    char riskStr[6];
    snprintf(riskStr, sizeof(riskStr), "%d%%", riskScore);
    display->print(riskStr);
    
    // Risk bar
    int riskBar = (riskScore * 120) / 100;
    display->drawRect(4, 18, 120, 10, SSD1306_WHITE);
    if (riskBar > 0) display->fillRect(4, 18, riskBar, 10, SSD1306_WHITE);
    
    // Patterns
    display->setCursor(0, 32);
    display->print("Patterns:");
    display->print(patternCount);
    
    // Prediction
    display->setCursor(0, 44);
    display->print("Insight:");
    display->setCursor(0, 52);
    display->print(prediction);
}

void HealthScreens::showSettingsScreen(int battery, bool aiEnabled, bool stealthMode) {
    display->setTextSize(1);
    display->setCursor(0, 0);
    display->print("SETTINGS");
    
    display->setCursor(0, 12);
    display->print("Battery:");
    display->print(battery);
    display->print("%");
    
    display->setCursor(0, 24);
    display->print("AI:");
    display->print(aiEnabled ? "ON" : "OFF");
    
    display->setCursor(0, 36);
    display->print("Stealth:");
    display->print(stealthMode ? "ON" : "OFF");
    
    display->setCursor(0, 48);
    display->print("Firmware:");
    display->print("v1.0.0");
}

void HealthScreens::drawGauge(int x, int y, int width, int height, int value, int maxValue) {
    display->drawRect(x, y, width, height, SSD1306_WHITE);
    int fillWidth = (value * width) / maxValue;
    if (fillWidth > 0) display->fillRect(x, y, fillWidth, height, SSD1306_WHITE);
}

void HealthScreens::drawRiskIndicator(int x, int y, int riskScore) {
    display->setTextSize(1);
    display->setCursor(x, y);
    
    if (riskScore < 30) {
        display->print("LOW");
    } else if (riskScore < 60) {
        display->print("MED");
    } else if (riskScore < 80) {
        display->print("HIGH");
    } else {
        display->print("CRIT");
    }
}
