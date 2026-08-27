#pragma once
// BLE contract v1. App and firmware must stay in sync.

#define VEYRO_NAME "Veyro"
#define VEYRO_PROTO 1
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHAR_LIVE_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHAR_CMD_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26f0"
#define CHAR_HIST_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a1"
#define CHAR_INFO_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a2"

#define RETAIN_DAYS 60
#define SAMPLE_EVERY_MS 60000UL   // one flash sample per minute while worn
#define LIVE_EVERY_MS 1000UL
