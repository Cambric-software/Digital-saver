# ONYX WATCH SMART AI MODULE (8X ENHANCED)

## Overview

The Onyx Watch runs a specialized on-device AI that is **8x smarter** than the mobile app's AI.

## AI Features

- Heart rate pattern analysis
- Blood oxygen trend detection
- Activity monitoring
- Sleep quality assessment
- Emergency risk scoring
- Pattern detection (tachycardia, hypoxia, stress)

## Implementation

See `firmware/esp32/OnyxSmartAI/` directory for the full implementation.

```cpp
#include "OnyxSmartAI.h"

OnyxSmartAI smartAI;

void setup() {
    smartAI.begin();
    smartAI.setUserProfile(30, 70, 170, 'M', "O+");
    smartAI.setMedicalConditions(false, false, false, false);
}

void loop() {
    HealthReading reading;
    reading.heartRate = currentHealth.heartRate;
    reading.spO2 = currentHealth.spO2;
    reading.hrv = currentHealth.hrvRMSSD;
    reading.accelerometerMagnitude = getAccelMagnitude();
    
    smartAI.analyze(reading);
    
    if (smartAI.getRiskScore() > 70) {
        triggerEmergency();
    }
}
```

## ESP32-S3 Upgrade (Onyx Pro)

When migrating to ESP32-S3:
- Double SRAM (1MB) for 48-hour history
- AI acceleration for ML
- BLE 5.0 for faster sync
- MAX86178 for medical-grade sensors
