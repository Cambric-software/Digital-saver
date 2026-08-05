/*
 * BLE Communication Implementation
 */

#include "BLECommunication.h"

void BLECommunication::begin(String name) {
    deviceName = name;
    
    Serial.println("[BLE] Starting BLE...");
    
    // Initialize BLE
    BLEDevice::init(deviceName.c_str());
    
    // Create BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(this);
    
    // Create BLE Service
    pService = pServer->createService(SERVICE_UUID);
    
    // Create TX Characteristic (Watch -> Phone)
    pTxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_TX,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    pTxCharacteristic->addDescriptor(new BLE2902());
    
    // Create RX Characteristic (Phone -> Watch)
    pRxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_RX,
        BLECharacteristic::PROPERTY_WRITE
    );
    pRxCharacteristic->setCallbacks(this);
    
    // Start service
    pService->start();
    
    // Start advertising
    BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinPreferred(0x12);
    
    BLEDevice::startAdvertising();
    
    Serial.println("[BLE] BLE started, waiting for connection...");
}

void BLECommunication::setCallbacks(
    std::function<void(BLEDataPacket)> onDataReceived,
    std::function<void()> onConnect,
    std::function<void()> onDisconnect
) {
    this->onDataReceived = onDataReceived;
    this->onConnect = onConnect;
    this->onDisconnect = onDisconnect;
}

void BLECommunication::sendPacket(BLEDataPacket packet) {
    if (!isConnected || pTxCharacteristic == nullptr) return;
    
    pTxCharacteristic->setValue((uint8_t*)&packet, sizeof(BLEDataPacket));
    pTxCharacteristic->notify();
}

void BLECommunication::sendEmergencyAlert(int alertType, int heartRate, int spO2) {
    BLEDataPacket emergency;
    memset(&emergency, 0, sizeof(BLEDataPacket));
    
    emergency.type = DATA_TYPE_EMERGENCY;
    emergency.timestamp = millis();
    emergency.heartRate = heartRate;
    emergency.spO2 = spO2;
    
    sendPacket(emergency);
}

void BLECommunication::onConnect(BLEServer* pServer) {
    isConnected = true;
    Serial.println("[BLE] Client connected");
    
    if (onConnect) {
        onConnect();
    }
}

void BLECommunication::onDisconnect(BLEServer* pServer) {
    isConnected = false;
    Serial.println("[BLE] Client disconnected");
    
    // Restart advertising
    BLEDevice::startAdvertising();
    
    if (onDisconnect) {
        onDisconnect();
    }
}

void BLECommunication::onWrite(BLECharacteristic* pCharacteristic) {
    std::string rxValue = pCharacteristic->getValue();
    
    if (rxValue.length() >= sizeof(BLEDataPacket)) {
        BLEDataPacket packet;
        memcpy(&packet, rxValue.data(), sizeof(BLEDataPacket));
        
        if (onDataReceived) {
            onDataReceived(packet);
        }
    } else if (rxValue.length() > 0) {
        // Handle command packets
        String command = "";
        for (unsigned int i = 0; i < rxValue.length(); i++) {
            command += (char)rxValue[i];
        }
        
        Serial.printf("[BLE] Received command: %s\n", command.c_str());
        
        // Parse commands
        if (command.startsWith("STEALTH:")) {
            // Toggle stealth mode
        } else if (command.startsWith("SYNC:")) {
            // Sync requested
        }
    }
}
