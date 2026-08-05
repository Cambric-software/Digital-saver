/*
 * MAX30102 Heart Rate and SpO2 Sensor Implementation
 */

#include "MAX30102_sensor.h"
#include <math.h>

bool MAX30102Sensor::begin() {
    Wire.beginTransmission(MAX30102_ADDRESS);
    if (Wire.endTransmission() != 0) {
        Serial.println("[MAX30102] Device not found!");
        return false;
    }
    
    // Read part ID
    uint8_t partId = readRegister(MAX30102Reg::PART_ID);
    Serial.printf("[MAX30102] Part ID: 0x%02X\n", partId);
    
    // Reset
    writeRegister(MAX30102Reg::MODE_CONFIG, 0x40);
    delay(100);
    
    initialized = true;
    Serial.println("[MAX30102] Initialized successfully");
    return true;
}

void MAX30102Sensor::configure(uint8_t ledBrightness, uint8_t sampleAverage, 
                                 uint8_t ledMode, uint16_t sampleRate,
                                 uint16_t pulseWidth, uint16_t adcRange) {
    config.ledBrightness = ledBrightness;
    config.sampleAverage = sampleAverage;
    config.ledMode = ledMode;
    config.sampleRate = sampleRate;
    config.pulseWidth = pulseWidth;
    config.adcRange = adcRange;
    
    // Configure FIFO
    // Sample average (bits 5-7), rollover (bit 4), almost full (bits 0-3)
    uint8_t fifoConfig = ((config.sampleAverage / 2) << 5) | (1 << 4) | (15);
    writeRegister(MAX30102Reg::FIFO_CONFIG, fifoConfig);
    
    // Configure SpO2
    // SR (bits 2-4), LED_PW (bits 0-1)
    uint8_t spo2Config = 0;
    if (config.sampleRate == 400) spo2Config |= (3 << 2);
    else if (config.sampleRate == 800) spo2Config |= (4 << 2);
    else if (config.sampleRate == 1000) spo2Config |= (5 << 2);
    else if (config.sampleRate == 1600) spo2Config |= (6 << 2);
    else if (config.sampleRate == 3200) spo2Config |= (7 << 2);
    
    if (config.pulseWidth == 118) spo2Config |= 1;
    else if (config.pulseWidth == 215) spo2Config |= 2;
    else if (config.pulseWidth == 411) spo2Config |= 3;
    
    writeRegister(MAX30102Reg::SPO2_CONFIG, spo2Config);
    
    // Configure LEDs
    // LED1 (Red) current
    writeRegister(0x11, config.ledBrightness);  // LED1 PA
    // LED2 (IR) current
    writeRegister(0x12, config.ledBrightness);  // LED2 PA
    
    // Mode configuration
    // Mode (bits 0-2): 2=SpO2, 3=HR, 7=Multi-LED
    uint8_t modeConfig = 2;  // SpO2 mode
    writeRegister(MAX30102Reg::MODE_CONFIG, modeConfig);
    
    // Clear FIFO
    writeRegister(MAX30102Reg::FIFO_WRITE_POINTER, 0);
    writeRegister(MAX30102Reg::OVERFLOW_COUNTER, 0);
    writeRegister(MAX30102Reg::FIFO_READ_POINTER, 0);
    
    Serial.println("[MAX30102] Configuration applied");
}

void MAX30102Sensor::update() {
    if (!initialized) return;
    
    // Read FIFO data
    readFIFO();
    
    // Calculate values
    calculateHeartRate();
    calculateSpO2();
    calculateHRV();
}

void MAX30102Sensor::readFIFO() {
    // Get FIFO pointers
    uint8_t writePtr = readRegister(MAX30102Reg::FIFO_WRITE_POINTER);
    uint8_t readPtr = readRegister(MAX30102Reg::FIFO_READ_POINTER);
    
    uint8_t samplesToRead = (writePtr - readPtr) & 0x1F;
    if (samplesToRead > 0) {
        samplesToRead = min(samplesToRead, (uint8_t)3); // Read max 3 at a time
    }
    
    if (samplesToRead == 0) {
        return;
    }
    
    // Read FIFO data (3 bytes per channel, MSB first)
    // For mode 2: Red + IR = 6 bytes per sample
    uint8_t data[32];
    
    Wire.beginTransmission(MAX30102_ADDRESS);
    Wire.write(MAX30102Reg::FIFO_DATA_REGISTER);
    Wire.endTransmission(false);
    
    Wire.requestFrom((uint8_t)MAX30102_ADDRESS, (uint8_t)(samplesToRead * 6));
    
    for (uint8_t i = 0; i < samplesToRead * 6; i++) {
        data[i] = Wire.read();
    }
    
    // Process the last sample
    uint8_t offset = (samplesToRead - 1) * 6;
    
    // Red: 3 bytes (MSB first)
    redValue = ((int32_t)data[offset] << 16) | ((int32_t)data[offset + 1] << 8) | data[offset + 2];
    // Handle negative values (2's complement for 18-bit ADC)
    if (redValue & 0x20000) redValue |= 0xFFFC0000;
    
    // IR: 3 bytes (MSB first)
    irValue = ((int32_t)data[offset + 3] << 16) | ((int32_t)data[offset + 4] << 8) | data[offset + 5];
    if (irValue & 0x20000) irValue |= 0xFFFC0000;
    
    // Green (if mode 3)
    if (config.ledMode == 3) {
        // Read additional 3 bytes for green
        greenValue = 0; // Would need more bytes
    }
}

void MAX30102Sensor::calculateHeartRate() {
    // Check if finger is on sensor
    if (irValue < 50000) {
        // No finger detected
        heartRate = 0;
        confidence = 0;
        return;
    }
    
    confidence = 100; // Simplified
    
    // Beat detection using derivative and threshold
    if (checkForBeat()) {
        uint32_t currentTime = millis();
        uint32_t interval = currentTime - lastBeatTime;
        
        if (interval > 300 && interval < 2000) { // Valid beat interval
            // Add to RR intervals
            rrIntervals[rrIndex] = interval;
            rrIndex = (rrIndex + 1) % 32;
            if (rrCount < 32) rrCount++;
            
            // Calculate heart rate from recent intervals
            uint32_t avgInterval = 0;
            uint8_t count = min((uint8_t)8, rrCount);
            for (uint8_t i = 0; i < count; i++) {
                uint8_t idx = (rrIndex - 1 - i + 32) % 32;
                avgInterval += rrIntervals[idx];
            }
            avgInterval /= count;
            
            heartRate = (uint32_t)(60000.0 / avgInterval);
            lastBeatTime = currentTime;
        }
    }
    
    // Sanity check
    if (heartRate < 30 || heartRate > 220) {
        heartRate = 0;
    }
}

bool MAX30102Sensor::checkForBeat() {
    // Simple peak detection
    static int32_t prevIR = 0;
    static bool rising = false;
    static uint32_t peakTime = 0;
    static int32_t threshold = 0;
    
    // Update threshold periodically
    if (millis() - peakTime > 1000) {
        threshold = irValue * 0.7;
    }
    
    // Detect rising edge
    if (irValue > prevIR) {
        rising = true;
    } else if (rising && irValue < prevIR) {
        // Peak detected
        rising = false;
        if (irValue > threshold && prevIR > threshold) {
            peakTime = millis();
            beatDetected = true;
        }
    }
    
    prevIR = irValue;
    return beatDetected;
}

void MAX30102Sensor::calculateSpO2() {
    // Check if finger is on sensor
    if (irValue < 50000 || redValue < 50000) {
        spO2 = 0;
        return;
    }
    
    // Simple SpO2 calculation using ratio of ratios
    // This is a simplified formula - real MAX30102 library uses more sophisticated methods
    
    // DC removal (simplified - just use current values for demo)
    double irDC = irValue;
    double redDC = redValue;
    
    // Calculate R (ratio of ratios)
    // In real implementation, you need to separate DC and AC components
    double R = (double)redValue / (double)irValue;
    
    // SpO2 formula (empirical)
    if (R < 0.5) R = 0.5;
    if (R > 3.5) R = 3.5;
    
    spO2 = (int32_t)(110.0 - 25.0 * R);
    
    // Sanity check
    if (spO2 < 50) spO2 = 50;
    if (spO2 > 100) spO2 = 100;
}

void MAX30102Sensor::calculateHRV() {
    // Calculate RMSSD (Root Mean Square of Successive Differences)
    if (rrCount < 2) {
        hrv = 0;
        return;
    }
    
    uint32_t sumSquaredDiff = 0;
    uint8_t count = min((uint8_t)(rrCount - 1), (uint8_t)30);
    
    for (uint8_t i = 0; i < count; i++) {
        uint8_t idx1 = (rrIndex - 1 - i + 32) % 32;
        uint8_t idx2 = (rrIndex - 2 - i + 32) % 32;
        int32_t diff = rrIntervals[idx1] - rrIntervals[idx2];
        sumSquaredDiff += diff * diff;
    }
    
    hrv = (int32_t)sqrt((double)sumSquaredDiff / count);
    
    // Sanity check
    if (hrv < 0 || hrv > 500) {
        hrv = 0;
    }
}

void MAX30102Sensor::writeRegister(uint8_t reg, uint8_t value) {
    Wire.beginTransmission(MAX30102_ADDRESS);
    Wire.write(reg);
    Wire.write(value);
    Wire.endTransmission();
}

uint8_t MAX30102Sensor::readRegister(uint8_t reg) {
    Wire.beginTransmission(MAX30102_ADDRESS);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)MAX30102_ADDRESS, (uint8_t)1);
    return Wire.read();
}
