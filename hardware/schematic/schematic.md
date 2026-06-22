# Circuit Schematic - Digital Saver Smartwatch

## Overview

This document provides the circuit schematic and pin connections for the Digital Saver smartwatch.

## Block Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    POWER SUPPLY                         │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐              │
│  │ Battery │───►│ TP4056  │───►│  3.3V   │              │
│  │  3.7V   │    │ Charger │    │ Reg     │              │
│  │ 500mAh │    └─────────┘    └────┬────┘              │
│  └─────────┘                      │                    │
│                                    ▼                    │
├─────────────────────────────────────────────────────────┤
│                      ESP32                              │
│  ┌─────────────────────────────────────────────────┐  │
│  │  ESP32-WROOM-32                                  │  │
│  │  • Bluetooth 4.2 BLE                            │  │
│  │  • Dual-core 240MHz                            │  │
│  │  • WiFi (optional)                             │  │
│  └─────────────────────────────────────────────────┘  │
│         │           │           │           │          │
│    ┌────┴────┐ ┌────┴────┐ ┌────┴────┐ ┌────┴────┐     │
│    │  GPIO21 │ │  GPIO22 │ │  GPIO26 │ │  GPIO27 │     │
│    │   SDA   │ │   SCL   │ │  MOTOR  │ │  BUZZER │     │
│    └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘     │
├─────────┼───────────┼───────────┼───────────┼───────────┤
│         │           │           │           │           │
│         ▼           ▼           ▼           │           │
│    ┌─────────┐ ┌─────────┐ ┌─────────┐     │           │
│    │  MAX30102│ │ MPU6050 │ │  OLED   │     │           │
│    │   PPG   │ │   IMU   │ │ 1.3"    │     │           │
│    └─────────┘ └─────────┘ └─────────┘     │           │
│                                              │           │
│    ┌─────────────────────────────────────┐   │           │
│    │           GPIO 0 ──► BUTTON          │   │           │
│    └─────────────────────────────────────┘   │           │
│                                              │           │
└──────────────────────────────────────────────────────────┘
```

## Pin Connections

### Power Rails
| Component | VCC | GND | Notes |
|-----------|-----|-----|-------|
| ESP32 | 3.3V | GND | Main controller |
| MAX30102 | 3.3V | GND | I2C sensor |
| MPU6050 | 3.3V | GND | I2C sensor |
| OLED | 3.3V | GND | I2C display |
| TP4056 | USB 5V | GND | Battery charger |

### I2C Bus (Pull-up Resistors Required)
| ESP32 Pin | I2C Device | I2C Address |
|-----------|------------|-------------|
| GPIO 21 (SDA) | MAX30102 SDA | 0x57 |
| GPIO 21 (SDA) | MPU6050 SDA | 0x68 |
| GPIO 21 (SDA) | OLED SDA | 0x3C |
| GPIO 22 (SCL) | MAX30102 SCL | 0x57 |
| GPIO 22 (SCL) | MPU6050 SCL | 0x68 |
| GPIO 22 (SCL) | OLED SCL | 0x3C |

**Note:** Add 4.7KΩ pull-up resistors between SDA and 3.3V, and SCL and 3.3V.

### Interrupt Pins
| ESP32 Pin | Sensor | Interrupt Purpose |
|-----------|--------|-------------------|
| GPIO 35 | MAX30102 | Data ready interrupt |
| GPIO 34 | MPU6050 | Motion interrupt |

### Output Pins
| ESP32 Pin | Component | Function |
|-----------|-----------|----------|
| GPIO 26 | Vibration Motor | Haptic feedback |
| GPIO 27 | Buzzer | Audio alerts |

### Input Pins
| ESP32 Pin | Component | Function |
|-----------|-----------|----------|
| GPIO 0 | Tactile Button | Emergency trigger |

## Detailed Schematic

### Power Circuit
```
    USB-C
      │
      ▼
   ┌──────┐
   │TP4056│ Battery Charger
   │      │
   │  OUT+│───────┬─────────────┐
   │  OUT-│───────┘             │
   │  IN+ │─────── USB 5V       │
   │  IN- │─────── USB GND      │
   └──────┘
      │
      ▼
   ┌─────────────────┐
   │  LiPo Battery   │
   │   3.7V 500mAh   │
   └─────────────────┘
      │
      │ Battery+
      ▼
   ┌─────────────────┐
   │    LD1117AV33   │  3.3V Regulator
   │    (or MCP1700) │
   └─────────────────┘
      │
      ▼ 3.3V Rail
      │
      ├───► ESP32 VCC
      ├───► MAX30102 VCC
      ├───► MPU6050 VCC
      └───► OLED VCC
```

### Sensor Circuit
```
                    3.3V
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    │            4.7KΩ              4.7KΩ
    │                │                │
    │                ├───────┬────────┤
    │                │       │        │
    │           ┌────┴───┐   │   ┌────┴────┐
    │           │ MAX30102│   │   │ MPU6050 │
    │           │    SDA  │◄──┼──►│   SDA   │
    │           └─────────┘   │   └─────────┘
    │                │       │        │
    │           ┌────┴───┐   │   ┌────┴────┐
    │           │ MAX30102│   │   │ MPU6050 │
    │           │   SCL   │◄──┴──►│   SCL   │
    │           └─────────┘       └─────────┘
    │                │                │
    └────────────────┼────────────────┘
                     │
                   GPIO 21 (SDA)
                   GPIO 22 (SCL)
```

### Alert Circuit
```
ESP32 GPIO 26 ────┤ 2N2222 NPN ┌─────┐
                   │ Transistor │     │
                   │            │MOTOR│
                   │       ┌────┤     │
                   └────────│─│──└─────┘
                            └────  Flyback Diode
                            (1N4001)

ESP32 GPIO 27 ────┤ 2N2222 NPN ┌─────┐
                   │ Transistor │     │
                   │            │BUZZER│
                   │       ┌────┤     │
                   └────────│─│──└─────┘
                            └────
                            (1N4001)
```

## Battery Life Estimation

| Component | Current Draw | Duty Cycle | Average |
|-----------|-------------|------------|---------|
| ESP32 (BLE active) | 100mA | 10% | 10mA |
| ESP32 (sleep) | 10µA | 90% | 0.01mA |
| MAX30102 | 25mA | 5% | 1.25mA |
| OLED (active) | 20mA | 20% | 4mA |
| **Total** | | | **~15mA avg** |

**Battery Life:** 500mAh / 15mA ≈ 33 hours (continuous monitoring)

With optimizations and deep sleep:
- Sleep current: ~100µA
- Active monitoring: 30s intervals
- Estimated life: 5-7 days

## Physical Layout

### PCB Dimensions
- Size: 45mm x 45mm
- Layers: 2-layer PCB recommended
- Mounting holes: 4x M2 holes at corners

### Component Placement (Top View)
```
    ┌─────────────────────────────┐
    │                             │
    │   ┌─────────────────┐      │
    │   │     OLED 1.3"    │      │
    │   │      (top)       │      │
    │   └─────────────────┘      │
    │                             │
    │  ┌───────┐    ┌───────┐    │
    │  │ESP32  │    │ MAX30102│   │
    │  │      │    │  (PPG) │    │
    │  └───────┘    └───────┘    │
    │                             │
    │  ┌───────┐    ┌───────┐    │
    │  │TP4056 │    │MPU6050│    │
    │  │      │    │  (IMU) │    │
    │  └───────┘    └───────┘    │
    │                             │
    │   [BTN]         [MOTOR]     │
    │                             │
    └─────────────────────────────┘
```

## Assembly Notes

1. **SMD Components:** Use hot air station for small SMD parts
2. **Headers:** Use female headers for ESP32 and sensors for easy replacement
3. **Wires:** Use 26 AWG wire for power connections
4. **Protection:** Add 100µF capacitor near ESP32 power pins
