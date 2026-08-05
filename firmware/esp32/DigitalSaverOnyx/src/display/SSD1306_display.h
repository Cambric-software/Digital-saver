/*
 * SSD1306 OLED Display Driver
 * 128x64 pixels, I2C interface
 */

#ifndef SSD1306_DISPLAY_H
#define SSD1306_DISPLAY_H

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define OLED_ADDRESS 0x3C

class SSD1306Display {
private:
    Adafruit_SSD1306* display;
    bool initialized = false;
    uint8_t contrast = 255;
    
public:
    SSD1306Display() {
        display = new Adafruit_SSD1306(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
    }
    
    bool begin();
    void clear();
    void update();
    void setContrast(uint8_t value);
    
    // Get display object for custom drawing
    Adafruit_SSD1306* getDisplay() { return display; }
    
    void showLogo();
    void showTransition();
};

#endif // SSD1306_DISPLAY_H
