/*
 * BLE Communication Module
 * Handles Bluetooth communication with the Digital Saver mobile app
 */

#ifndef BLE_COMMUNICATION_H
#define BLE_COMMUNICATION_H

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE UUIDs
#define SERVICE_UUID "6e400001-b5a3-f393-e0a9-e50e24dcca9e" // Nordic UART Service
#define CHARACTERISTIC_UUID_RX "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_TX "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

// Packet Types
#define DATA_TYPE_HEALTH 0x01
#define DATA_TYPE_ACTIVITY 0x02
#define DATA_TYPE_SLEEP 0x03
#define DATA_TYPE_EMERGENCY 0x04
#define DATA_TYPE_COMMAND 0x05
#define DATA_TYPE_PROFILE 0x06

// BLE Packet Structure
struct BLEDataPacket {
    uint8_t type;           // Packet type
    uint32_t timestamp;     // Timestamp
    
    // Health data
    int16_t heartRate;
    int16_t spO2;
    int16_t systolic;
    int16_t diastolic;
    int16_t hrv;
    uint8_t confidence;
    
    // Activity
    int32_t steps;
    uint16_t calories;
    
    // AI
    uint8_t aiRiskScore;
    uint8_t aiPatternCount;
    
    // Battery
    uint8_t batteryLevel;
    
    // Reserved
    uint8_t reserved[16];
};

class BLECommunication : public BLEServerCallbacks, 
                        public BLECharacteristicCallbacks {
private:
    BLEServer* pServer = nullptr;
    BLEService* pService = nullptr;
    BLECharacteristic* pTxCharacteristic = nullptr;
    BLECharacteristic* pRxCharacteristic = nullptr;
    
    bool isConnected = false;
    String deviceName;
    
    // Callbacks
    std::function<void(BLEDataPacket)> onDataReceived;
    std::function<void()> onConnect;
    std::function<void()> onDisconnect;
    
public:
    BLECommunication() {}
    
    void begin(String name);
    void setCallbacks(
        std::function<void(BLEDataPacket)> onDataReceived,
        std::function<void()> onConnect,
        std::function<void()> onDisconnect
    );
    
    void sendPacket(BLEDataPacket packet);
    void sendEmergencyAlert(int alertType, int heartRate, int spO2);
    
    bool isDeviceConnected() { return isConnected; }
    
private:
    // BLEServerCallbacks
    void onConnect(BLEServer* pServer) override;
    void onDisconnect(BLEServer* pServer) override;
    
    // BLECharacteristicCallbacks
    void onWrite(BLECharacteristic* pCharacteristic) override;
};

#endif // BLE_COMMUNICATION_H
