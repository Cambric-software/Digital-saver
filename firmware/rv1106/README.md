# Veyro RV1106 firmware (demo)

Minimal LVGL demo for the RV1106G3 + ESP32-C6 architecture.

## Prerequisites
- Linux host (Ubuntu 22.04 recommended)
- Buildroot 2024.x
- LVGL 9.x
- Cross-compiler: arm-rockchip830-linux-gnueabihf

## Build
```bash
cd firmware/rv1106
./build.sh
```

## Flash
Copy the resulting image to the SD card and boot.

## Status
Code-only skeleton; hardware not yet available.