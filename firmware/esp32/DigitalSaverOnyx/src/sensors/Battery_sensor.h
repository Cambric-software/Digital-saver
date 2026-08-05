/*
 * Battery Monitoring Sensor
 * Monitors LiPo battery voltage and charging status
 */

#ifndef BATTERY_SENSOR_H
#define BATTERY_SENSOR_H

#include <Arduino.h>

class BatterySensor {
private:
    int pinADC;
    int pinChargeStatus;
    
    int percentage = 100;
    bool isCharging = false;
    
    // Voltage dividers (100K + 100K)
    const float R1 = 100.0;
    const float R2 = 100.0;
    const float ADC_MAX = 4095.0; // 12-bit ADC
    const float ADC_VOLTAGE = 3.3;
    
    // Battery thresholds (LiPo 3.7V nominal, 4.2V max, 3.0V min)
    const float MAX_VOLTAGE = 4.2;
    const float MIN_VOLTAGE = 3.0;
    const float NOMINAL_VOLTAGE = 3.7;
    
public:
    BatterySensor() : pinADC(33), pinChargeStatus(32) {}
    
    void begin(int adcPin, int chargeStatusPin) {
        pinADC = adcPin;
        pinChargeStatus = chargeStatusPin;
        
        pinMode(pinADC, INPUT);
        pinMode(pinChargeStatus, INPUT_PULLUP);
        
        update();
    }
    
    void update() {
        // Read ADC
        int rawADC = analogRead(pinADC);
        
        // Convert to voltage
        float voltage = (rawADC / ADC_MAX) * ADC_VOLTAGE * (R1 + R2) / R2;
        
        // Calculate percentage
        float percentageRange = MAX_VOLTAGE - MIN_VOLTAGE;
        float voltageAboveMin = voltage - MIN_VOLTAGE;
        percentage = (int)((voltageAboveMin / percentageRange) * 100.0);
        percentage = constrain(percentage, 0, 100);
        
        // Check charging status (active low)
        isCharging = (digitalRead(pinChargeStatus) == LOW);
        
        // Simulate for demo
        if (percentage > 100) percentage = 85;
        if (percentage < 0) percentage = 15;
    }
    
    int getPercentage() { return percentage; }
    bool isChargingStatus() { return isCharging; }
    
    float getVoltage() {
        int rawADC = analogRead(pinADC);
        return (rawADC / ADC_MAX) * ADC_VOLTAGE * (R1 + R2) / R2;
    }
    
    bool isLow() { return percentage < 20; }
    bool isCritical() { return percentage < 10; }
};

#endif // BATTERY_SENSOR_H
