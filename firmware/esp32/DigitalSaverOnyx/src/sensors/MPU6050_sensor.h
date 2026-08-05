/*
 * MPU6050 6-Axis Accelerometer and Gyroscope Sensor Driver
 * 
 * Interface: I2C (SDA=21, SCL=22)
 * Interrupt: GPIO 27
 * Address: 0x68 (104)
 */

#ifndef MPU6050_SENSOR_H
#define MPU6050_SENSOR_H

#include <Arduino.h>
#include <Wire.h>

// MPU6050 I2C Address
#define MPU6050_ADDRESS 0x68

// Register Addresses
namespace MPU6050Reg {
    constexpr uint8_t SELF_TEST_X = 0x0D;
    constexpr uint8_t SELF_TEST_Y = 0x0E;
    constexpr uint8_t SELF_TEST_Z = 0x0F;
    constexpr uint8_t SMPLRT_DIV = 0x19;
    constexpr uint8_t CONFIG = 0x1A;
    constexpr uint8_t GYRO_CONFIG = 0x1B;
    constexpr uint8_t ACCEL_CONFIG = 0x1C;
    constexpr uint8_t FIFO_EN = 0x23;
    constexpr uint8_t INT_PIN_CONFIG = 0x37;
    constexpr uint8_t INT_ENABLE = 0x38;
    constexpr uint8_t INT_STATUS = 0x3A;
    constexpr uint8_t ACCEL_XOUT_H = 0x3B;
    constexpr uint8_t ACCEL_XOUT_L = 0x3C;
    constexpr uint8_t ACCEL_YOUT_H = 0x3D;
    constexpr uint8_t ACCEL_YOUT_L = 0x3E;
    constexpr uint8_t ACCEL_ZOUT_H = 0x3F;
    constexpr uint8_t ACCEL_ZOUT_L = 0x40;
    constexpr uint8_t TEMP_OUT_H = 0x41;
    constexpr uint8_t TEMP_OUT_L = 0x42;
    constexpr uint8_t GYRO_XOUT_H = 0x43;
    constexpr uint8_t GYRO_XOUT_L = 0x44;
    constexpr uint8_t GYRO_YOUT_H = 0x45;
    constexpr uint8_t GYRO_YOUT_L = 0x46;
    constexpr uint8_t GYRO_ZOUT_H = 0x47;
    constexpr uint8_t GYRO_ZOUT_L = 0x48;
    constexpr uint8_t PWR_MGMT_1 = 0x6B;
    constexpr uint8_t WHO_AM_I = 0x75;
}

// Range settings
enum class MPU6050AccelRange {
    RANGE_2G = 0,
    RANGE_4G = 1,
    RANGE_8G = 2,
    RANGE_16G = 3
};

enum class MPU6050GyroRange {
    RANGE_250 = 0,
    RANGE_500 = 1,
    RANGE_1000 = 2,
    RANGE_2000 = 3
};

enum class MPU6050Bandwidth {
    BAND_260_HZ = 0,
    BAND_184_HZ = 1,
    BAND_94_HZ = 2,
    BAND_44_HZ = 3,
    BAND_21_HZ = 4,
    BAND_10_HZ = 5,
    BAND_5_HZ = 6
};

class MPU6050Sensor {
private:
    bool initialized = false;
    
    // Configuration
    MPU6050AccelRange accelRange = MPU6050AccelRange::RANGE_8G;
    MPU6050GyroRange gyroRange = MPU6050GyroRange::RANGE_500_DEG;
    
    // Scale factors
    float accelScale = 4096.0;  // LSB/g
    float gyroScale = 65.5;      // LSB/(°/s)
    
    // Raw values
    int16_t rawAccelX = 0, rawAccelY = 0, rawAccelZ = 0;
    int16_t rawGyroX = 0, rawGyroY = 0, rawGyroZ = 0;
    int16_t rawTemp = 0;
    
    // Calculated values
    float accelX = 0, accelY = 0, accelZ = 0;  // In g
    float gyroX = 0, gyroY = 0, gyroZ = 0;      // In °/s
    
    // Magnitude
    float accelMagnitude = 0;
    float gyroMagnitude = 0;
    
    // Step detection
    uint32_t lastStepTime = 0;
    uint32_t stepCount = 0;
    float lastAccelMag = 0;
    bool stepDetected = false;
    
    // Activity detection
    bool isMoving = false;
    uint32_t lastMovementTime = 0;
    
public:
    MPU6050Sensor() {}
    
    bool begin();
    void configure(MPU6050AccelRange accelRange, MPU6050GyroRange gyroRange, 
                   MPU6050Bandwidth bandwidth);
    
    void update();
    void updateStepCount(uint32_t currentTime);
    
    // Getters
    float getAccelerationX() { return accelX; }
    float getAccelerationY() { return accelY; }
    float getAccelerationZ() { return accelZ; }
    float getAccelerationMagnitude() { return accelMagnitude; }
    
    float getGyroX() { return gyroX; }
    float getGyroY() { return gyroY; }
    float getGyroZ() { return gyroZ; }
    float getGyroMagnitude() { return gyroMagnitude; }
    
    float getTemperature() { return (rawTemp / 340.0) + 36.53; }
    
    int getStepCount() { return stepCount; }
    bool isActive() { return isMoving; }
    
    // Sleep/Wake functions
    void enableWakeOnMotion();
    void disableWakeOnMotion();
    void sleep();
    void wake();
    
private:
    void writeRegister(uint8_t reg, uint8_t value);
    uint8_t readRegister(uint8_t reg);
    void readAllSensors();
    
    void calculateMagnitude();
    void detectStep(float magnitude, uint32_t currentTime);
    void detectMovement();
};

#endif // MPU6050_SENSOR_H
