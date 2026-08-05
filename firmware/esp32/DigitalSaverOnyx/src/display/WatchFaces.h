/*
 * Watch Faces Module
 * Different watch face styles for the Onyx display
 */

#ifndef WATCH_FACES_H
#define WATCH_FACES_H

#include <Arduino.h>
#include <Adafruit_SSD1306.h>
#include <math.h>

class WatchFaces {
private:
    Adafruit_SSD1306* display;
    
    // Current style
    int style = 0;
    int totalStyles = 3;
    
public:
    WatchFaces(Adafruit_SSD1306* disp) : display(disp) {}
    
    void setStyle(int s) { style = s % totalStyles; }
    int getStyle() { return style; }
    void nextStyle() { style = (style + 1) % totalStyles; }
    
    // Main watch face with all info
    void showMainWatchFace(int hour, int minute, int day, int month, 
                           int steps, int goalSteps, int battery, bool charging);
    
    // Digital style
    void showDigitalFace(int hour, int minute, int second);
    
    // Analog style
    void showAnalogFace(int hour, int minute);
    
    // Minimal style
    void showMinimalFace(int hour, int minute, int battery);
    
    // Draw time
    void drawTime(int x, int y, int hour, int minute, bool centered = false);
    
    // Draw battery icon
    void drawBattery(int x, int y, int percentage, bool charging);
    
    // Draw steps progress
    void drawSteps(int x, int y, int steps, int goal);
};

#endif // WATCH_FACES_H
