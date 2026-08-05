/*
 * MPU6050 6-Axis Accelerometer Implementation
 */

#include "MPU6050_sensor.h"

bool MPU6050Sensor::begin() {
    Wire.beginTransmission(MPU6050_ADDRESS);
    if (Wire.endTransmission() != 0) {
        Serial.println("[MPU6050] Device not found!");
        return false;
    }
    
    // Wake up MPU6050
    writeRegister(MPU6050Reg::PWR_MGMT_1, 0);
    delay(100);
    
    // Verify WHO_AM_I
    uint8_t whoAmI = readRegister(MPU6050Reg::WHO_AM_I);
    Serial.printf("[MPU6050] WHO_AM_I: 0x%02X (expected 0x68)\n", whoAmI);
    
    initialized = true;
    Serial.println("[MPU6050] Initialized successfully");
    return true;
}

void MPU6050Sensor::configure(MPU6050AccelRange accelRange, 
                               MPU6050GyroRange gyroRange,
                               MPU6050Bandwidth bandwidth) {
    this->accelRange = accelRange;
    this->gyroRange = gyroRange;
    
    // Set accelerometer range
    switch (accelRange) {
        case MPU6050AccelRange::RANGE_2G: accelScale = 16384.0; break;
        case MPU6050AccelRange::RANGE_4G: accelScale = 8192.0; break;
        case MPU6050AccelRange::RANGE_8G: accelScale = 4096.0; break;
        case MPU6050AccelRange::RANGE_16G: accelScale = 2048.0; break;
    }
    writeRegister(MPU6050Reg::ACCEL_CONFIG, (uint8_t)accelRange << 3);
    
    // Set gyroscope range
    switch (gyroRange) {
        case MPU6050GyroRange::RANGE_250: gyroScale = 131.0; break;
        case MPU6050GyroRange::RANGE_500: gyroScale = 65.5; break;
        case MPU6050GyroRange::RANGE_1000: gyroScale = 32.8; break;
        case MPU6050GyroRange::RANGE_2000: gyroScale = 16.4; break;
    }
    writeRegister(MPU6050Reg::GYRO_CONFIG, (uint8_t)gyroRange << 3);
    
    // Set bandwidth
    writeRegister(MPU6050Reg::CONFIG, (uint8_t)bandwidth);
    
    // Set sample rate (1kHz / (div + 1))
    writeRegister(MPU6050Reg::SMPLRT_DIV, 7); // 125Hz
    
    Serial.println("[MPU6050] Configuration applied");
}

void MPU6050Sensor::update() {
    if (!initialized) return;
    
    readAllSensors();
    calculateMagnitude();
    detectMovement();
}

void MPU6050Sensor::readAllSensors() {
    Wire.beginTransmission(MPU6050_ADDRESS);
    Wire.write(MPU6050Reg::ACCEL_XOUT_H);
    Wire.endTransmission(false);
    
    Wire.requestFrom((uint8_t)MPU6050_ADDRESS, (uint8_t)14);
    
    rawAccelX = (Wire.read() << 8) | Wire.read();
    rawAccelY = (Wire.read() << 8) | Wire.read();
    rawAccelZ = (Wire.read() << 8) | Wire.read();
    rawTemp = (Wire.read() << 8) | Wire.read();
    rawGyroX = (Wire.read() << 8) | Wire.read();
    rawGyroY = (Wire.read() << 8) | Wire.read();
    rawGyroZ = (Wire.read() << 8) | Wire.read();
    
    // Convert to physical units
    accelX = rawAccelX / accelScale;
    accelY = rawAccelY / accelScale;
    accelZ = rawAccelZ / accelScale;
    
    gyroX = rawGyroX / gyroScale;
    gyroY = rawGyroY / gyroScale;
    gyroZ = rawGyroZ / gyroScale;
}

void MPU6050Sensor::calculateMagnitude() {
    // Total acceleration magnitude (accounting for gravity)
    accelMagnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
    
    // Gyro magnitude
    gyroMagnitude = sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
}

void MPU6050Sensor::detectMovement() {
    static unsigned long lastUpdate = 0;
    
    // If magnitude > 1.1g or < 0.9g, or gyro > 20°/s, we're moving
    if (accelMagnitude > 1.15 || accelMagnitude < 0.85 || gyroMagnitude > 25) {
        if (!isMoving) {
            isMoving = true;
            lastMovementTime = millis();
        }
    } else if (isMoving && (millis() - lastMovementTime > 2000)) {
        isMoving = false;
    }
    
    lastUpdate = millis();
}

void MPU6050Sensor::updateStepCount(uint32_t currentTime) {
    const float STEP_THRESHOLD_HIGH = 1.5;  // g
    const float STEP_THRESHOLD_LOW = 0.8;   // g
    const uint32_t STEP_MIN_INTERVAL = 250; // ms
    
    // Peak detection algorithm
    if (accelMagnitude > STEP_THRESHOLD_HIGH && lastAccelMag <= STEP_THRESHOLD_HIGH) {
        // Rising edge detected
        if (currentTime - lastStepTime > STEP_MIN_INTERVAL) {
            stepCount++;
            stepDetected = true;
            lastStepTime = currentTime;
        }
    }
    
    lastAccelMag = accelMagnitude;
}

void MPU6050Sensor::enableWakeOnMotion() {
    // Enable motion interrupt
    writeRegister(MPU6050Reg::INT_ENABLE, 0x40); // WOM_EN
    writeRegister(MPU6050Reg::PWR_MGMT_1, 0x20); // CYCLE mode
    
    // Set wake frequency
    writeRegister(0x69, 0x40); // LP_ACCEL_ODR
}

void MPU6050Sensor::disableWakeOnMotion() {
    writeRegister(MPU6050Reg::INT_ENABLE, 0);
    writeRegister(MPU6050Reg::PWR_MGMT_1, 0);
}

void MPU6050Sensor::sleep() {
    writeRegister(MPU6050Reg::PWR_MGMT_1, 0x40); // Sleep bit
}

void MPU6050Sensor::wake() {
    writeRegister(MPU6050Reg::PWR_MGMT_1, 0);
}

void MPU6050Sensor::writeRegister(uint8_t reg, uint8_t value) {
    Wire.beginTransmission(MPU6050_ADDRESS);
    Wire.write(reg);
    Wire.write(value);
    Wire.endTransmission();
}

uint8_t MPU6050Sensor::readRegister(uint8_t reg) {
    Wire.beginTransmission(MPU6050_ADDRESS);
    Wire.write(reg);
    Wire.endTransmission(false);
    Wire.requestFrom((uint8_t)MPU6050_ADDRESS, (uint8_t)1);
    return Wire.read();
}
