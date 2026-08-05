/*
 * Watch Faces Implementation
 */

#include "WatchFaces.h"

void WatchFaces::showMainWatchFace(int hour, int minute, int day, int month,
                                     int steps, int goalSteps, int battery, bool charging) {
    switch (style) {
        case 0: showDigitalFace(hour, minute, 0); break;
        case 1: showAnalogFace(hour, minute); break;
        case 2: showMinimalFace(hour, minute, battery); break;
    }
    
    // Always show battery
    drawBattery(100, 0, battery, charging);
    
    // Always show steps at bottom
    drawSteps(0, 54, steps, goalSteps);
    
    // Date
    display->setTextSize(1);
    char dateStr[8];
    snprintf(dateStr, sizeof(dateStr), "%02d/%02d", day, month);
    display->setCursor(0, 0);
    display->print(dateStr);
}

void WatchFaces::showDigitalFace(int hour, int minute, int second) {
    display->setTextSize(3);
    char timeStr[6];
    if (hour < 10) {
        snprintf(timeStr, sizeof(timeStr), "0%d:%02d", hour, minute);
    } else {
        snprintf(timeStr, sizeof(timeStr), "%d:%02d", hour, minute);
    }
    
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(timeStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((SCREEN_WIDTH - w) / 2, 20);
    display->print(timeStr);
    
    // Seconds
    if (second >= 0) {
        display->setTextSize(1);
        char secStr[4];
        snprintf(secStr, sizeof(secStr), ":%02d", second);
        display->setCursor((SCREEN_WIDTH - w) / 2 + w - 10, 28);
        display->print(secStr);
    }
}

void WatchFaces::showAnalogFace(int hour, int minute) {
    int centerX = 64;
    int centerY = 32;
    int radius = 25;
    
    // Draw circle
    display->drawCircle(centerX, centerY, radius, SSD1306_WHITE);
    
    // Hour markers
    for (int i = 0; i < 12; i++) {
        float angle = i * 30 * PI / 180 - PI / 2;
        int x1 = centerX + (radius - 3) * cos(angle);
        int y1 = centerY + (radius - 3) * sin(angle);
        int x2 = centerX + (radius - 1) * cos(angle);
        int y2 = centerY + (radius - 1) * sin(angle);
        display->drawLine(x1, y1, x2, y2, SSD1306_WHITE);
    }
    
    // Hour hand
    float hourAngle = ((hour % 12) + minute / 60.0) * 30 * PI / 180 - PI / 2;
    int hourX = centerX + (radius - 10) * cos(hourAngle);
    int hourY = centerY + (radius - 10) * sin(hourAngle);
    display->drawLine(centerX, centerY, hourX, hourY, SSD1306_WHITE);
    
    // Minute hand
    float minAngle = minute * 6 * PI / 180 - PI / 2;
    int minX = centerX + (radius - 5) * cos(minAngle);
    int minY = centerY + (radius - 5) * sin(minAngle);
    display->drawLine(centerX, centerY, minX, minY, SSD1306_WHITE);
    
    // Center dot
    display->fillCircle(centerX, centerY, 2, SSD1306_WHITE);
}

void WatchFaces::showMinimalFace(int hour, int minute, int battery) {
    display->setTextSize(4);
    char timeStr[6];
    if (hour < 10) {
        snprintf(timeStr, sizeof(timeStr), "0%d:%02d", hour, minute);
    } else {
        snprintf(timeStr, sizeof(timeStr), "%d:%02d", hour, minute);
    }
    
    int16_t x1, y1;
    uint16_t w, h;
    display->getTextBounds(timeStr, 0, 0, &x1, &y1, &w, &h);
    display->setCursor((SCREEN_WIDTH - w) / 2, 22);
    display->print(timeStr);
}

void WatchFaces::drawBattery(int x, int y, int percentage, bool charging) {
    // Battery outline
    display->drawRect(x, y + 2, 20, 10, SSD1306_WHITE);
    display->drawRect(x + 20, y + 4, 2, 6, SSD1306_WHITE);
    
    // Battery fill
    int fillWidth = (percentage * 18) / 100;
    if (fillWidth > 0) {
        display->fillRect(x + 1, y + 3, fillWidth, 8, SSD1306_WHITE);
    }
    
    // Charging indicator
    if (charging) {
        display->setTextSize(1);
        display->setCursor(x + 4, y + 4);
        display->print("+");
    }
}

void WatchFaces::drawSteps(int x, int y, int steps, int goal) {
    // Progress bar
    int barWidth = 128;
    int progress = (steps * barWidth) / goal;
    if (progress > barWidth) progress = barWidth;
    
    display->drawRect(x, y, barWidth, 8, SSD1306_WHITE);
    if (progress > 0) {
        display->fillRect(x + 1, y + 1, progress - 1, 6, SSD1306_WHITE);
    }
    
    // Step count
    display->setTextSize(1);
    char stepStr[16];
    snprintf(stepStr, sizeof(stepStr), "%d/%d", steps, goal);
    display->setCursor(4, y + 10);
    display->print(stepStr);
}
