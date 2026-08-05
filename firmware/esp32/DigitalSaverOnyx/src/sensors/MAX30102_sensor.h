/*
 * MAX30102 Heart Rate and SpO2 Sensor Driver
 * 
 * Interface: I2C (SDA=21, SCL=22)
 * Interrupt: GPIO 25
 * Address: 0x57 (87)
 */

#ifndef MAX30102_SENSOR_H
#define MAX30102_SENSOR_H

#include <Arduino.h>
#include <Wire.h>

// MAX30102 I2C Address
#define MAX30102_ADDRESS 0x57

// Register Addresses
namespace MAX30102Reg {
    constexpr uint8_t INTERRUPT_STATUS_1 = 0x00;
    constexpr uint8_t INTERRUPT_STATUS_2 = 0x01;
    constexpr uint8_t INTERRUPT_ENABLE_1 = 0x02;
    constexpr uint8_t INTERRUPT_ENABLE_2 = 0x03;
    constexpr uint8_t FIFO_WRITE_POINTER = 0x04;
    constexpr uint8_t OVERFLOW_COUNTER = 0x05;
    constexpr uint8_t FIFO_READ_POINTER = 0x06;
    constexpr uint8_t FIFO_DATA_REGISTER = 0x07;
    constexpr uint8_t FIFO_CONFIG = 0x08;
    constexpr uint8_t MODE_CONFIG = 0x09;
    constexpr uint8_t SPO2_CONFIG = 0x0A;
    constexpr uint8_t LED_MODE_1 = 0x0C;
    constexpr uint8_t LED_MODE_2 = 0x0D;
    constexpr uint8_t PROXITY_THRESHOLD = 0x0E;
    constexpr uint8_t REVISION_ID = 0xFE;
    constexpr uint8_t PART_ID = 0xFF;
}

// Configuration
struct MAX30102Config {
    uint8_t ledBrightness;    // 0-255
    uint8_t sampleAverage;    // 1, 2, 4, 8, 16, 32
    uint8_t ledMode;          // 1=Red, 2=Red+IR, 3=Red+IR+Green
    uint16_t sampleRate;      // 50, 100, 200, 400, 800, 1000, 1600, 3200
    uint16_t pulseWidth;      // 69, 118, 215, 411 μs
    uint16_t adcRange;        // 2048, 4096, 8192, 16384
};

class MAX30102Sensor {
private:
    bool initialized = false;
    
    // Data
    int32_t redValue = 0;
    int32_t irValue = 0;
    int32_t greenValue = 0;
    
    // Calculated values
    int32_t heartRate = 0;
    int32_t spO2 = 0;
    int32_t confidence = 0;
    int32_t hrv = 0;  // RMSSD
    
    // Beat detection
    bool beatDetected = false;
    uint32_t lastBeatTime = 0;
    uint32_t beatIntervalSum = 0;
    int beatCount = 0;
    uint32_t lastIR = 0;
    
    // HRV calculation
    uint32_t rrIntervals[32] = {0};
    uint8_t rrIndex = 0;
    uint8_t rrCount = 0;
    
    // SpO2 calculation
    double spO2Ratio = 0;
    
    // Configuration
    MAX30102Config config;
    
public:
    MAX30102Sensor() : config{60, 4, 2, 400, 69, 4096} {}
    
    bool begin();
    void configure(uint8_t ledBrightness, uint8_t sampleAverage, uint8_t ledMode, 
                   uint16_t sampleRate, uint16_t pulseWidth, uint16_t adcRange);
    
    void update();
    
    // Getters
    int32_t getHeartRate() { return heartRate; }
    int32_t getSpO2() { return spO2; }
    int32_t getConfidence() { return confidence; }
    int32_t getHRV() { return hrv; }
    bool isIrregularBeat() { return beatCount > 5 && (heartRate < 50 || heartRate > 120); }
    
    int32_t getRedValue() { return redValue; }
    int32_t getIRValue() { return irValue; }
    int32_t getGreenValue() { return greenValue; }
    
    bool checkForBeat();
    
private:
    void writeRegister(uint8_t reg, uint8_t value);
    uint8_t readRegister(uint8_t reg);
    void readFIFO();
    
    void calculateHeartRate();
    void calculateSpO2();
    void calculateHRV();
};

#endif // MAX30102_SENSOR_H
