/*
 * SSD1306 Display Implementation
 */

#include "SSD1306_display.h"
#include <Wire.h>

bool SSD1306Display::begin() {
    // Initialize with I2C address
    if (!display->begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
        Serial.println("[DISPLAY] SSD1306 allocation failed!");
        return false;
    }
    
    display->display();
    delay(100);
    
    initialized = true;
    display->setTextColor(SSD1306_WHITE);
    display->setTextSize(1);
    
    Serial.println("[DISPLAY] Initialized successfully");
    return true;
}

void SSD1306Display::clear() {
    display->clearDisplay();
    display->setCursor(0, 0);
}

void SSD1306Display::update() {
    display->display();
}

void SSD1306Display::setContrast(uint8_t value) {
    contrast = value;
    display->ssd1306_command(SSD1306_SETCONTRAST);
    display->ssd1306_command(value);
}

void SSD1306Display::showLogo() {
    clear();
    
    // Cambric Logo
    display->setTextSize(2);
    display->setCursor(10, 10);
    display->println("DIGITAL");
    display->setCursor(25, 30);
    display->println("SAVER");
    
    display->setTextSize(1);
    display->setCursor(20, 48);
    display->println("Onyx Smartwatch");
    
    update();
}

void SSD1306Display::showTransition() {
    // Simple fade effect
    for (int i = 0; i < 3; i++) {
        display->invertDisplay(true);
        delay(50);
        display->invertDisplay(false);
        delay(50);
    }
}
