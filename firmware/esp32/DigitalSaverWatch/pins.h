#pragma once
// One pin map. Do not invent a second table in docs.

#define I2C_SDA 21
#define I2C_SCL 22

#define PIN_VIBE 25
#define PIN_LED_RED 4
#define PIN_LED_GREEN 16
#define PIN_BTN_MODE 17   // has internal pull-up
#define PIN_BTN_SOS 32    // has internal pull-up; hold 2s = SOS

// Battery: two 100k resistors, BAT+ -- R1 -- GPIO34 -- R2 -- GND
// GPIO34 is input-only (no pull-up). If you skip the divider, battery stays 0.
#define PIN_BAT_ADC 34

#define OLED_W 128
#define OLED_H 64
#define OLED_ADDR 0x3C
