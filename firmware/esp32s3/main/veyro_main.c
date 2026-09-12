/**
 * Veyro Production Firmware 5.0.0
 * Cambric — ESP32-S3-MINI-1U-N16R8
 * ESP-IDF v5.2 + FreeRTOS + NimBLE
 *
 * Hardware:
 *   VC31B     — wrist PPG (HR, SpO2, HRV) on I2C bus B (GPIO1/GPIO2), addr 0x33
 *   QMI6858C  — IMU + hardware pedometer on I2C bus B, addr 0x6A
 *   BMP581    — barometric pressure/altitude on I2C bus B, addr 0x47
 *   STTS22H   — skin temperature on I2C bus B, addr 0x3C
 *   DRV2605L  — haptic controller on I2C bus B, addr 0x5A
 *   BQ25895   — PMIC on I2C bus C (GPIO17/GPIO18), addr 0x6B
 *   FT6336G   — touch on I2C bus A (GPIO4/GPIO5), addr 0x38
 *   AMOLED    — 360x360 round display, SPI (GPIO11/12/10/8/9), BL GPIO7
 *   WS2812B   — RGB LED, GPIO21
 *   Crown     — GPIO0, SOS — GPIO13
 *   Battery NTC — GPIO14 ADC
 */

#include <string.h>
#include <math.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/timers.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_random.h"
#include "esp_efuse.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "driver/i2c.h"
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "driver/ledc.h"
#include "driver/adc.h"
#include "esp_adc_cal.h"
#include "esp_spiffs.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "esp_timer.h"
#include "esp_sleep.h"
#include "esp_wifi.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/ble_uuid.h"
#include "host/ble_gap.h"
#include "host/ble_gatt.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include "lvgl.h"

/* ─────────────────────────────────────────────────────────────────────── */
/*  GPIO DEFINITIONS                                                        */
/* ─────────────────────────────────────────────────────────────────────── */

#define GPIO_CROWN        0
#define GPIO_SOS          13
#define GPIO_DISP_BL      7
#define GPIO_DISP_DC      8
#define GPIO_DISP_RST     9
#define GPIO_DISP_CS      10
#define GPIO_DISP_MOSI    11
#define GPIO_DISP_CLK     12
#define GPIO_TOUCH_INT    6
#define GPIO_QMI_INT2     3
#define GPIO_BMP_INT      22
#define GPIO_STTS_DRDY    23
#define GPIO_PMIC_INT     15
#define GPIO_RGB_LED      21
#define GPIO_BAT_NTC      14

#define I2C_BUS_A         I2C_NUM_0   /* Touch FT6336G */
#define I2C_SDA_A         4
#define I2C_SCL_A         5
#define I2C_BUS_B         I2C_NUM_1   /* All health sensors */
#define I2C_SDA_B         1
#define I2C_SCL_B         2
#define I2C_BUS_C         I2C_NUM_2   /* PMIC */
#define I2C_SDA_C         17
#define I2C_SCL_C         18

#define ADDR_VC31B        0x33
#define ADDR_QMI6858      0x6A
#define ADDR_BMP581       0x47
#define ADDR_STTS22H      0x3C
#define ADDR_DRV2605      0x5A
#define ADDR_BQ25895      0x6B
#define ADDR_FT6336G      0x38

/* ─────────────────────────────────────────────────────────────────────── */
/*  FIRMWARE VERSION                                                        */
/* ─────────────────────────────────────────────────────────────────────── */

#define VEYRO_FW_VERSION  "5.0.0"
#define VEYRO_PROTO       2
#define VEYRO_NAME        "Veyro"
#define RETAIN_DAYS       60

/* ─────────────────────────────────────────────────────────────────────── */
/*  BLE SERVICE AND CHARACTERISTIC UUIDs                                   */
/* ─────────────────────────────────────────────────────────────────────── */

/* Service: 4fafc201-1fb5-459e-8fcc-c5c9c331914b */
static const ble_uuid128_t gatt_svc_uuid = BLE_UUID128_INIT(
    0x4b, 0x91, 0x31, 0xc3, 0xc9, 0xc5, 0xcc, 0x8f,
    0x9e, 0x45, 0xb5, 0x1f, 0x01, 0xc2, 0xaf, 0x4f);

/* Live vitals: beb5483e-36e1-4688-b7f5-ea07361b26a8 */
static const ble_uuid128_t chr_live_uuid = BLE_UUID128_INIT(
    0xa8, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* History: suffix 26a1 */
static const ble_uuid128_t chr_hist_uuid = BLE_UUID128_INIT(
    0xa1, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* Info: suffix 26a2 */
static const ble_uuid128_t chr_info_uuid = BLE_UUID128_INIT(
    0xa2, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* Command: suffix 26f0 */
static const ble_uuid128_t chr_cmd_uuid = BLE_UUID128_INIT(
    0xf0, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* Notifications: suffix 26b0 */
static const ble_uuid128_t chr_notif_uuid = BLE_UUID128_INIT(
    0xb0, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* OTA data: suffix 26c0 */
static const ble_uuid128_t chr_ota_uuid = BLE_UUID128_INIT(
    0xc0, 0x26, 0x1b, 0x36, 0x07, 0xea, 0xf5, 0xb7,
    0x88, 0x46, 0xe1, 0x36, 0x3e, 0x48, 0xb5, 0xbe);

/* ─────────────────────────────────────────────────────────────────────── */
/*  GLOBAL HEALTH STATE                                                     */
/* ─────────────────────────────────────────────────────────────────────── */

static volatile int     g_hr_bpm      = 0;
static volatile int     g_spo2        = 0;
static volatile int     g_hrv_ms      = 0;
static volatile int     g_stress      = 0;  /* 0-100 */
static volatile uint32_t g_steps      = 0;
static volatile int     g_floors      = 0;
static volatile float   g_altitude_m  = 0;
static volatile float   g_pressure_hpa = 1013.25f;
static volatile float   g_skin_temp_c = 0;
static volatile int     g_battery_pct = 0;
static volatile bool    g_charging    = false;
static volatile bool    g_fall        = false;
static volatile int     g_activity_zone = 0; /* 0=rest,1=fatburn,2=cardio,3=peak,4=max */
static volatile int     g_weather     = 0;   /* 0=steady,1=clear,2=rain */
static volatile bool    g_sleep_mode  = false;
static volatile uint32_t g_unix_time  = 0;
static volatile uint32_t g_boot_ms    = 0;
static volatile bool    g_ble_paired  = false;
static volatile bool    g_ble_connected = false;
static volatile int     g_watch_face  = 0;
static volatile int     g_theme       = 0;
static volatile uint32_t g_saved_steps = 0;  /* last value written to NVS */
static volatile int     g_wrong_pin_count = 0;
static char             g_pin_code[7] = "000000";
static char             g_serial[16]  = "VY00000000000";

/* RR interval buffer for HRV */
static uint16_t g_rr_buf[8] = {0};
static int      g_rr_idx    = 0;

/* Pressure history for weather trend (3 hours = 18 samples at 10s) */
#define PRESSURE_HISTORY_LEN 18
static float g_pressure_history[PRESSURE_HISTORY_LEN] = {0};
static int   g_pressure_history_idx = 0;

/* Watchdog heartbeats — each task updates its slot every second */
#define TASK_COUNT 8
static volatile uint32_t g_task_heartbeat[TASK_COUNT] = {0};
#define HB_SENSORS  0
#define HB_BLE      1
#define HB_STORAGE  2
#define HB_DISPLAY  3
#define HB_HAPTIC   4
#define HB_POWER    5
#define HB_ENV      6
#define HB_WATCHDOG 7

/* ─────────────────────────────────────────────────────────────────────── */
/*  FreeRTOS QUEUES AND SEMAPHORES                                          */
/* ─────────────────────────────────────────────────────────────────────── */

static QueueHandle_t g_sensor_queue;   /* sensor_event_t, size 16 */
static QueueHandle_t g_haptic_queue;   /* uint8_t effect number, size 8 */
static SemaphoreHandle_t g_i2c_b_mutex; /* protects I2C bus B */
static SemaphoreHandle_t g_storage_mutex; /* protects LittleFS writes */

typedef struct {
    int hr;
    int spo2;
    int hrv;
    int stress;
    uint32_t steps;
    int floors;
    float altitude;
    float skin_temp;
    int battery;
    bool fall;
    int zone;
    int weather;
    uint32_t ts;
} sensor_event_t;

/* ─────────────────────────────────────────────────────────────────────── */
/*  I2C HELPERS                                                             */
/* ─────────────────────────────────────────────────────────────────────── */

/** Write one byte to a register on the given I2C bus. */
static esp_err_t i2c_write_reg(i2c_port_t bus, uint8_t addr, uint8_t reg, uint8_t val) {
    uint8_t buf[2] = {reg, val};
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write(cmd, buf, 2, true);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(bus, cmd, pdMS_TO_TICKS(50));
    i2c_cmd_link_delete(cmd);
    return ret;
}

/** Read one byte from a register. */
static esp_err_t i2c_read_reg(i2c_port_t bus, uint8_t addr, uint8_t reg, uint8_t *out) {
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, reg, true);
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_READ, true);
    i2c_master_read_byte(cmd, out, I2C_MASTER_LAST_NACK);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(bus, cmd, pdMS_TO_TICKS(50));
    i2c_cmd_link_delete(cmd);
    return ret;
}

/** Read multiple bytes starting from a register. */
static esp_err_t i2c_read_regs(i2c_port_t bus, uint8_t addr, uint8_t reg, uint8_t *buf, size_t len) {
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, reg, true);
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (addr << 1) | I2C_MASTER_READ, true);
    if (len > 1) i2c_master_read(cmd, buf, len - 1, I2C_MASTER_ACK);
    i2c_master_read_byte(cmd, buf + len - 1, I2C_MASTER_LAST_NACK);
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(bus, cmd, pdMS_TO_TICKS(100));
    i2c_cmd_link_delete(cmd);
    return ret;
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  SENSOR INITIALISATION                                                   */
/* ─────────────────────────────────────────────────────────────────────── */

/** Initialise VC31B wrist PPG sensor. */
static bool init_vc31b(void) {
    /* VC31B wake up: write 0x01 to register 0x00 */
    esp_err_t r = i2c_write_reg(I2C_BUS_B, ADDR_VC31B, 0x00, 0x01);
    if (r != ESP_OK) return false;
    vTaskDelay(pdMS_TO_TICKS(100));
    /* Enable HR + SpO2 measurement mode (mode byte 0x03) */
    i2c_write_reg(I2C_BUS_B, ADDR_VC31B, 0x01, 0x03);
    /* Set LED drive current to mid level for wrist */
    i2c_write_reg(I2C_BUS_B, ADDR_VC31B, 0x02, 0x1F);
    return true;
}

/** Read HR, SpO2, and latest RR interval from VC31B. */
static void read_vc31b(int *hr, int *spo2, int *rr_ms) {
    uint8_t buf[6];
    if (i2c_read_regs(I2C_BUS_B, ADDR_VC31B, 0x10, buf, 6) != ESP_OK) return;
    /* Byte 0-1: HR (big endian), byte 2-3: SpO2, byte 4-5: RR interval */
    int new_hr  = (int)((buf[0] << 8) | buf[1]);
    int new_spo2 = (int)((buf[2] << 8) | buf[3]);
    int new_rr  = (int)((buf[4] << 8) | buf[5]);
    if (new_hr > 30 && new_hr < 220)   *hr   = new_hr;
    if (new_spo2 > 80 && new_spo2 <= 100) *spo2 = new_spo2;
    if (new_rr > 300 && new_rr < 2000)    *rr_ms = new_rr;
}

/** Initialise QMI6858C IMU. */
static bool init_qmi6858(void) {
    uint8_t chip_id;
    if (i2c_read_reg(I2C_BUS_B, ADDR_QMI6858, 0x00, &chip_id) != ESP_OK) return false;
    if (chip_id != 0x05) return false; /* QMI6858 chip ID */
    /* Enable accelerometer + gyroscope */
    i2c_write_reg(I2C_BUS_B, ADDR_QMI6858, 0x03, 0x03);
    /* Accelerometer range ±8g, ODR 52 Hz */
    i2c_write_reg(I2C_BUS_B, ADDR_QMI6858, 0x04, 0x24);
    /* Gyroscope range ±512 deg/s, ODR 52 Hz */
    i2c_write_reg(I2C_BUS_B, ADDR_QMI6858, 0x05, 0x28);
    /* Enable hardware pedometer, interrupt on INT2 every 10 steps */
    i2c_write_reg(I2C_BUS_B, ADDR_QMI6858, 0x20, 0x01);
    i2c_write_reg(I2C_BUS_B, ADDR_QMI6858, 0x21, 0x0A); /* 10 steps per interrupt */
    return true;
}

/** Read accelerometer X/Y/Z (in g) and gyroscope magnitude (deg/s). */
static void read_qmi6858(float *ax, float *ay, float *az, float *gyro_rate) {
    uint8_t buf[12];
    if (i2c_read_regs(I2C_BUS_B, ADDR_QMI6858, 0x35, buf, 12) != ESP_OK) return;
    int16_t rx = (int16_t)((buf[1] << 8) | buf[0]);
    int16_t ry = (int16_t)((buf[3] << 8) | buf[2]);
    int16_t rz = (int16_t)((buf[5] << 8) | buf[4]);
    int16_t gx = (int16_t)((buf[7] << 8) | buf[6]);
    int16_t gy = (int16_t)((buf[9] << 8) | buf[8]);
    int16_t gz = (int16_t)((buf[11] << 8) | buf[10]);
    *ax = rx / 4096.0f; /* ±8g range, 16-bit */
    *ay = ry / 4096.0f;
    *az = rz / 4096.0f;
    float gxf = gx / 64.0f, gyf = gy / 64.0f, gzf = gz / 64.0f;
    *gyro_rate = sqrtf(gxf * gxf + gyf * gyf + gzf * gzf);
}

/** Initialise BMP581 pressure sensor. */
static bool init_bmp581(void) {
    uint8_t chip_id;
    if (i2c_read_reg(I2C_BUS_B, ADDR_BMP581, 0x01, &chip_id) != ESP_OK) return false;
    if (chip_id != 0x50) return false; /* BMP581 chip ID */
    /* Set power mode to normal, ODR 1 Hz, IIR filter coefficient 3 */
    i2c_write_reg(I2C_BUS_B, ADDR_BMP581, 0x37, 0x01); /* normal mode */
    i2c_write_reg(I2C_BUS_B, ADDR_BMP581, 0x36, 0x18); /* ODR 1 Hz */
    return true;
}

/** Read pressure from BMP581 and update global state. */
static void read_bmp581(void) {
    uint8_t buf[6];
    if (i2c_read_regs(I2C_BUS_B, ADDR_BMP581, 0x20, buf, 6) != ESP_OK) return;
    /* Pressure in Pa (20-bit, LSB first): combine buf[0..2] */
    int32_t raw_p = (int32_t)((buf[2] << 16) | (buf[1] << 8) | buf[0]);
    if (raw_p & 0x80000) raw_p |= 0xFFF00000; /* sign extend 20-bit */
    float press_pa = raw_p / 64.0f;
    g_pressure_hpa = press_pa / 100.0f;
    /* Barometric altitude formula */
    g_altitude_m = 44330.0f * (1.0f - powf(g_pressure_hpa / 1013.25f, 0.1903f));
}

/** Initialise STTS22H skin temperature sensor. */
static bool init_stts22h(void) {
    uint8_t chip_id;
    if (i2c_read_reg(I2C_BUS_B, ADDR_STTS22H, 0x01, &chip_id) != ESP_OK) return false;
    if (chip_id != 0xA0) return false; /* STTS22H WHO_AM_I */
    /* Continuous mode, 1 Hz ODR, free-running */
    i2c_write_reg(I2C_BUS_B, ADDR_STTS22H, 0x04, 0x3C);
    return true;
}

/** Read skin temperature from STTS22H. */
static void read_stts22h(void) {
    uint8_t buf[2];
    if (i2c_read_regs(I2C_BUS_B, ADDR_STTS22H, 0x06, buf, 2) != ESP_OK) return;
    int16_t raw = (int16_t)((buf[1] << 8) | buf[0]);
    g_skin_temp_c = raw / 100.0f;
}

/** Initialise DRV2605L haptic controller. */
static bool init_drv2605(void) {
    /* Reset */
    i2c_write_reg(I2C_BUS_B, ADDR_DRV2605, 0x01, 0x00); /* standby off */
    vTaskDelay(pdMS_TO_TICKS(10));
    /* LRA mode */
    i2c_write_reg(I2C_BUS_B, ADDR_DRV2605, 0x1A, 0xA8);
    /* Internal trigger */
    i2c_write_reg(I2C_BUS_B, ADDR_DRV2605, 0x01, 0x00);
    return true;
}

/** Play a DRV2605L effect by number. Non-blocking. */
static void drv2605_play(uint8_t effect) {
    i2c_write_reg(I2C_BUS_B, ADDR_DRV2605, 0x04, effect);
    i2c_write_reg(I2C_BUS_B, ADDR_DRV2605, 0x0C, 0x01); /* GO */
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  HEALTH ALGORITHMS                                                       */
/* ─────────────────────────────────────────────────────────────────────── */

/** Compute RMSSD from last N RR intervals (in ms).
 *  RMSSD = sqrt( mean of squared successive differences )
 *  A higher value means lower stress and better recovery.
 */
static int compute_rmssd(uint16_t *rr, int count) {
    if (count < 2) return 0;
    float sum_sq = 0;
    int n = (count > 8) ? 8 : count;
    for (int i = 1; i < n; i++) {
        float diff = (float)rr[i] - (float)rr[i - 1];
        sum_sq += diff * diff;
    }
    return (int)sqrtf(sum_sq / (n - 1));
}

/** Derive stress index (0-100) from RMSSD.
 *  High RMSSD = low stress. Low RMSSD = high stress.
 */
static int rmssd_to_stress(int rmssd) {
    if (rmssd <= 0) return 50; /* no data, return neutral */
    int stress = 100 - (int)((float)rmssd / 100.0f * 100.0f);
    if (stress < 0) stress = 0;
    if (stress > 100) stress = 100;
    return stress;
}

/** Classify activity zone from HR. */
static int classify_zone(int hr) {
    if (hr <= 0)    return 0;
    if (hr < 60)    return 0; /* resting */
    if (hr < 100)   return 1; /* fat burn */
    if (hr < 140)   return 2; /* cardio */
    if (hr < 170)   return 3; /* peak */
    return 4;                  /* max */
}

/** Update weather trend from pressure history ring buffer. */
static void update_weather_trend(float current_pressure) {
    g_pressure_history[g_pressure_history_idx] = current_pressure;
    g_pressure_history_idx = (g_pressure_history_idx + 1) % PRESSURE_HISTORY_LEN;

    /* Compare oldest vs newest sample */
    float oldest = g_pressure_history[g_pressure_history_idx]; /* next slot = oldest */
    if (oldest == 0) return; /* buffer not full yet */
    float delta = current_pressure - oldest; /* over 18 x 10s = 3 hours */
    float delta_per_hour = delta / 3.0f;

    if (delta_per_hour < -1.0f) g_weather = 2;       /* rain coming */
    else if (delta_per_hour > 1.0f) g_weather = 1;   /* clearing up */
    else g_weather = 0;                               /* steady */
}

/** Get current UNIX timestamp (RTC-derived). */
static uint32_t now_unix(void) {
    if (g_unix_time == 0) return 0;
    return g_unix_time + ((xTaskGetTickCount() * portTICK_PERIOD_MS - g_boot_ms) / 1000);
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  NVS (NON-VOLATILE STORAGE)                                             */
/* ─────────────────────────────────────────────────────────────────────── */

static nvs_handle_t g_nvs;

/** Load persistent settings from NVS on boot. */
static void nvs_load_all(void) {
    size_t len = sizeof(g_pin_code);
    nvs_get_str(g_nvs, "pin", g_pin_code, &len);
    nvs_get_u32(g_nvs, "steps", (uint32_t *)&g_steps);
    g_saved_steps = g_steps;
    uint8_t face;
    if (nvs_get_u8(g_nvs, "face", &face) == ESP_OK) g_watch_face = face % 8;
    uint8_t theme;
    if (nvs_get_u8(g_nvs, "theme", &theme) == ESP_OK) g_theme = theme % 4;
    len = sizeof(g_serial);
    nvs_get_str(g_nvs, "serial", g_serial, &len);
}

/** Generate a random 6-digit PIN and save to NVS. */
static void generate_pin(void) {
    uint32_t n = esp_random() % 900000UL + 100000UL;
    snprintf(g_pin_code, sizeof(g_pin_code), "%06lu", (unsigned long)n);
    nvs_set_str(g_nvs, "pin", g_pin_code);
    nvs_commit(g_nvs);
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  STORAGE (LittleFS / SPIFFS)                                            */
/* ─────────────────────────────────────────────────────────────────────── */

#include "esp_spiffs.h"
#include <dirent.h>
#include <sys/stat.h>

static bool g_fs_ready = false;

/** Initialise SPIFFS filesystem. */
static void fs_init(void) {
    esp_vfs_spiffs_conf_t conf = {
        .base_path = "/spiffs",
        .partition_label = NULL,
        .max_files = 8,
        .format_if_mount_failed = true,
    };
    esp_err_t ret = esp_vfs_spiffs_register(&conf);
    if (ret == ESP_OK) {
        mkdir("/spiffs/d", 0777);
        mkdir("/spiffs/cfg", 0777);
        mkdir("/spiffs/assets", 0777);
        mkdir("/spiffs/log", 0777);
        g_fs_ready = true;
    }
}

/** Build day file path from UNIX timestamp. */
static void day_path(uint32_t ts, char *buf, size_t len) {
    time_t t = (time_t)ts;
    struct tm tm;
    gmtime_r(&t, &tm);
    snprintf(buf, len, "/spiffs/d/%04d%02d%02d.csv",
             tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday);
}

/** Append one health sample row to today's CSV file.
 *  Format: unix,hr,spo2,hrv,stress,steps,floors,altitude,skin_temp,battery,fall,zone
 */
static void fs_append_sample(sensor_event_t *e) {
    if (!g_fs_ready || e->ts == 0) return;
    char path[48];
    day_path(e->ts, path, sizeof(path));
    FILE *f = fopen(path, "a");
    if (!f) f = fopen(path, "w");
    if (!f) return;
    fprintf(f, "%lu,%d,%d,%d,%d,%lu,%d,%.1f,%.1f,%d,%d,%d\n",
            (unsigned long)e->ts, e->hr, e->spo2, e->hrv, e->stress,
            (unsigned long)e->steps, e->floors, e->altitude, e->skin_temp,
            e->battery, e->fall ? 1 : 0, e->zone);
    fclose(f);
}

/** Delete files older than RETAIN_DAYS from /spiffs/d/. */
static void fs_prune(void) {
    if (!g_fs_ready) return;
    uint32_t now = now_unix();
    if (now == 0) return;
    time_t cutoff = (time_t)now - (time_t)RETAIN_DAYS * 86400;
    struct tm cut_tm;
    gmtime_r(&cutoff, &cut_tm);
    char cutkey[9];
    snprintf(cutkey, sizeof(cutkey), "%04d%02d%02d",
             cut_tm.tm_year + 1900, cut_tm.tm_mon + 1, cut_tm.tm_mday);

    DIR *dir = opendir("/spiffs/d");
    if (!dir) return;
    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        char *name = ent->d_name;
        if (strlen(name) < 8) continue;
        char filekey[9];
        memcpy(filekey, name, 8);
        filekey[8] = 0;
        if (strcmp(filekey, cutkey) < 0) {
            char full[64];
            snprintf(full, sizeof(full), "/spiffs/d/%s", name);
            remove(full);
        }
    }
    closedir(dir);
}

/** Log an error message to /spiffs/log/errors.txt (ring buffer, max 100 lines). */
static void fs_log_error(const char *msg) {
    if (!g_fs_ready) return;
    FILE *f = fopen("/spiffs/log/errors.txt", "a");
    if (!f) return;
    fprintf(f, "[%lu] %s\n", (unsigned long)now_unix(), msg);
    fclose(f);
    /* TODO: implement 100-line ring buffer by checking line count */
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: SENSORS                                                           */
/* ─────────────────────────────────────────────────────────────────────── */

/** ISR for QMI6858C INT2 (step counter interrupt).
 *  Every interrupt = 10 steps. Increments g_steps directly from ISR.
 */
static void IRAM_ATTR qmi_step_isr(void *arg) {
    g_steps += 10;
}

static void task_sensors(void *arg) {
    float ax = 0, ay = 0, az = 1, gyro = 0;
    float last_fall_mag = 1.0f;
    uint32_t fall_low_start = 0;
    bool fall_armed = false;
    int rr_ms = 800;
    static uint32_t last_sample_ms = 0;

    while (1) {
        uint32_t now_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
        g_task_heartbeat[HB_SENSORS] = now_ms;

        xSemaphoreTake(g_i2c_b_mutex, portMAX_DELAY);

        /* ---- VC31B: read HR, SpO2, RR ---- */
        int new_hr = g_hr_bpm, new_spo2 = g_spo2;
        read_vc31b(&new_hr, &new_spo2, &rr_ms);
        if (new_hr > 30 && new_hr < 220) {
            g_hr_bpm = (int)(0.85f * g_hr_bpm + 0.15f * new_hr);
        }
        if (new_spo2 > 80) g_spo2 = new_spo2;

        /* Update RR buffer and compute HRV */
        if (rr_ms > 300 && rr_ms < 2000) {
            g_rr_buf[g_rr_idx % 8] = (uint16_t)rr_ms;
            g_rr_idx++;
        }
        if (g_rr_idx >= 5) {
            g_hrv_ms = compute_rmssd(g_rr_buf, (g_rr_idx > 8) ? 8 : g_rr_idx);
            g_stress  = rmssd_to_stress(g_hrv_ms);
        }
        g_activity_zone = classify_zone(g_hr_bpm);

        /* ---- QMI6858C: read accelerometer + gyroscope ---- */
        read_qmi6858(&ax, &ay, &az, &gyro);
        float mag = sqrtf(ax * ax + ay * ay + az * az);

        /* Fall detection v2: free-fall + spike + gyro */
        if (mag < 0.4f) {
            if (fall_low_start == 0) fall_low_start = now_ms;
            fall_armed = true;
        } else {
            if (fall_armed && (now_ms - fall_low_start) > 80) {
                if (mag > 2.5f && gyro > 200.0f) {
                    g_fall = true;
                    uint8_t fx = 47;
                    xQueueSend(g_haptic_queue, &fx, 0);
                }
            }
            fall_low_start = 0;
            fall_armed = false;
        }
        last_fall_mag = mag;

        /* Sleep detection: HR < 75 and very low motion for 10 min (24000 x 25ms) */
        static int sleep_counter = 0;
        if (g_hr_bpm > 0 && g_hr_bpm < 75 && mag < 0.15f) {
            sleep_counter++;
            if (sleep_counter > 24000) g_sleep_mode = true;
        } else {
            sleep_counter = 0;
            if (g_sleep_mode && (g_hr_bpm > 80 || mag > 0.5f)) g_sleep_mode = false;
        }

        xSemaphoreGive(g_i2c_b_mutex);

        /* Post sensor event every second (40 ticks × 25ms) */
        static int tick_count = 0;
        tick_count++;
        if (tick_count >= 40 && g_ble_connected && g_ble_paired) {
            tick_count = 0;
            sensor_event_t ev = {
                .hr = g_hr_bpm, .spo2 = g_spo2, .hrv = g_hrv_ms,
                .stress = g_stress, .steps = g_steps, .floors = g_floors,
                .altitude = g_altitude_m, .skin_temp = g_skin_temp_c,
                .battery = g_battery_pct, .fall = g_fall,
                .zone = g_activity_zone, .weather = g_weather,
                .ts = now_unix()
            };
            xQueueSend(g_sensor_queue, &ev, 0);
        }

        vTaskDelay(pdMS_TO_TICKS(25));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: STORAGE                                                           */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_storage(void *arg) {
    static uint32_t last_sample_unix = 0;
    static uint32_t last_prune_unix  = 0;

    while (1) {
        uint32_t now_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
        g_task_heartbeat[HB_STORAGE] = now_ms;
        uint32_t now = now_unix();

        /* Write one CSV row per minute when actively worn */
        if (now > 0 && (now - last_sample_unix) >= 60) {
            if (g_hr_bpm > 30 || g_steps > 0) {
                last_sample_unix = now;
                xSemaphoreTake(g_storage_mutex, portMAX_DELAY);
                sensor_event_t ev = {
                    .hr = g_hr_bpm, .spo2 = g_spo2, .hrv = g_hrv_ms,
                    .stress = g_stress, .steps = g_steps, .floors = g_floors,
                    .altitude = g_altitude_m, .skin_temp = g_skin_temp_c,
                    .battery = g_battery_pct, .fall = g_fall,
                    .zone = g_activity_zone, .weather = g_weather, .ts = now
                };
                fs_append_sample(&ev);
                xSemaphoreGive(g_storage_mutex);
            }
        }

        /* Save steps to NVS when changed */
        if (g_steps != g_saved_steps) {
            nvs_set_u32(g_nvs, "steps", g_steps);
            nvs_set_i32(g_nvs, "floors", g_floors);
            nvs_commit(g_nvs);
            g_saved_steps = g_steps;
        }

        /* Midnight UTC: reset daily counters */
        if (now > 0) {
            time_t t = (time_t)now;
            struct tm tm;
            gmtime_r(&t, &tm);
            if (tm.tm_hour == 0 && tm.tm_min == 0 && tm.tm_sec < 60) {
                static uint32_t last_midnight = 0;
                if (now - last_midnight > 60) {
                    g_steps = 0; g_saved_steps = 0; g_floors = 0;
                    nvs_set_u32(g_nvs, "steps", 0);
                    nvs_set_i32(g_nvs, "floors", 0);
                    nvs_commit(g_nvs);
                    last_midnight = now;
                }
            }
        }

        /* Prune old files every 24 hours */
        if (now > 0 && (now - last_prune_unix) >= 86400) {
            last_prune_unix = now;
            xSemaphoreTake(g_storage_mutex, portMAX_DELAY);
            fs_prune();
            xSemaphoreGive(g_storage_mutex);
        }

        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: HAPTIC                                                            */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_haptic(void *arg) {
    uint8_t effect;
    while (1) {
        g_task_heartbeat[HB_HAPTIC] = xTaskGetTickCount() * portTICK_PERIOD_MS;
        if (xQueueReceive(g_haptic_queue, &effect, pdMS_TO_TICKS(100))) {
            xSemaphoreTake(g_i2c_b_mutex, portMAX_DELAY);
            drv2605_play(effect);
            xSemaphoreGive(g_i2c_b_mutex);
        }
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: POWER                                                             */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_power(void *arg) {
    static uint32_t last_low_bat_alert = 0;

    while (1) {
        uint32_t now_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
        g_task_heartbeat[HB_POWER] = now_ms;

        /* Read BQ25895 battery voltage register 0x0E */
        uint8_t vbat_reg;
        i2c_read_reg(I2C_BUS_C, ADDR_BQ25895, 0x0E, &vbat_reg);
        float vbat_v = 2.304f + (vbat_reg & 0x7F) * 0.02f;
        int pct = (int)((vbat_v - 3.30f) / (4.15f - 3.30f) * 100.0f);
        if (pct < 0) pct = 0;
        if (pct > 100) pct = 100;
        g_battery_pct = pct;

        /* Read charging status from register 0x0B bits [6:5] */
        uint8_t status_reg;
        i2c_read_reg(I2C_BUS_C, ADDR_BQ25895, 0x0B, &status_reg);
        g_charging = ((status_reg >> 5) & 0x03) > 0;

        /* Low battery haptic alert (once per hour) */
        if (pct < 10 && !g_charging) {
            if (now_ms - last_low_bat_alert > 3600000UL) {
                last_low_bat_alert = now_ms;
                uint8_t fx = 47;
                xQueueSend(g_haptic_queue, &fx, 0);
            }
        }

        /* Power save mode below 5% */
        if (pct < 5 && !g_charging) {
            /* TODO: reduce BLE interval, slow sensor rate, dim display */
        }

        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: ENVIRONMENT (BMP581 + STTS22H)                                  */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_env(void *arg) {
    static float last_floor_alt = 0;

    while (1) {
        uint32_t now_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
        g_task_heartbeat[HB_ENV] = now_ms;

        xSemaphoreTake(g_i2c_b_mutex, portMAX_DELAY);

        /* BMP581: pressure + altitude */
        read_bmp581();
        update_weather_trend(g_pressure_hpa);

        /* Floors climbed: altitude increase of 3m = 1 floor */
        if (g_altitude_m - last_floor_alt >= 3.0f) {
            g_floors++;
            last_floor_alt = g_altitude_m;
        } else if (last_floor_alt - g_altitude_m >= 3.0f) {
            /* Descended, update reference */
            last_floor_alt = g_altitude_m;
        }

        /* STTS22H: skin temperature */
        read_stts22h();

        xSemaphoreGive(g_i2c_b_mutex);

        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: WATCHDOG                                                          */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_watchdog(void *arg) {
    static uint32_t last_hb[TASK_COUNT] = {0};
    static int missed[TASK_COUNT] = {0};
    static const char *task_names[] = {
        "sensors", "ble", "storage", "display", "haptic", "power", "env", "watchdog"
    };

    while (1) {
        uint32_t now_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
        g_task_heartbeat[HB_WATCHDOG] = now_ms;

        for (int i = 0; i < TASK_COUNT - 1; i++) { /* skip checking self */
            if (g_task_heartbeat[i] == last_hb[i]) {
                missed[i]++;
                if (missed[i] >= 30) {
                    char msg[64];
                    snprintf(msg, sizeof(msg), "Task %s hung, restarting", task_names[i]);
                    fs_log_error(msg);
                    esp_restart();
                }
            } else {
                missed[i] = 0;
                last_hb[i] = g_task_heartbeat[i];
            }
        }

        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  TASK: DISPLAY (stub — LVGL implementation in display module)           */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_display(void *arg) {
    /* Full LVGL watch face implementation is in firmware/esp32s3/main/display.c
     * This task stub runs the LVGL timer and updates widget values. */
    while (1) {
        g_task_heartbeat[HB_DISPLAY] = xTaskGetTickCount() * portTICK_PERIOD_MS;
        lv_timer_handler();
        vTaskDelay(pdMS_TO_TICKS(5));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  BLE TASK (stub — NimBLE implementation in ble_service.c)              */
/* ─────────────────────────────────────────────────────────────────────── */

static void task_ble(void *arg) {
    /* NimBLE GATT server implementation is in firmware/esp32s3/main/ble_service.c
     * This task reads from g_sensor_queue and sends live notify. */
    sensor_event_t ev;
    while (1) {
        g_task_heartbeat[HB_BLE] = xTaskGetTickCount() * portTICK_PERIOD_MS;
        if (xQueueReceive(g_sensor_queue, &ev, pdMS_TO_TICKS(1100))) {
            /* Build and send live JSON notification via NimBLE */
            char json[256];
            snprintf(json, sizeof(json),
                "{\"v\":2,\"hr\":%d,\"spo2\":%d,\"hrv\":%d,\"stress\":%d,"
                "\"steps\":%lu,\"floors\":%d,\"alt\":%.1f,\"temp\":%.1f,"
                "\"bat\":%d,\"fall\":%d,\"zone\":%d,\"weather\":%d,\"ts\":%lu}",
                ev.hr, ev.spo2, ev.hrv, ev.stress,
                (unsigned long)ev.steps, ev.floors, ev.altitude, ev.skin_temp,
                ev.battery, ev.fall ? 1 : 0, ev.zone, ev.weather,
                (unsigned long)ev.ts);
            /* ble_service_notify_live(json) is called here when BLE module is linked */
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  PERIPHERAL INITIALISATION                                               */
/* ─────────────────────────────────────────────────────────────────────── */

/** Initialise all three I2C buses. */
static void init_i2c_buses(void) {
    /* Bus A: Touch FT6336G — 400 kHz */
    i2c_config_t cfgA = {
        .mode = I2C_MODE_MASTER, .sda_io_num = I2C_SDA_A,
        .scl_io_num = I2C_SCL_A, .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE, .master.clk_speed = 400000,
    };
    i2c_param_config(I2C_BUS_A, &cfgA);
    i2c_driver_install(I2C_BUS_A, I2C_MODE_MASTER, 0, 0, 0);

    /* Bus B: All health sensors — 400 kHz */
    i2c_config_t cfgB = {
        .mode = I2C_MODE_MASTER, .sda_io_num = I2C_SDA_B,
        .scl_io_num = I2C_SCL_B, .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE, .master.clk_speed = 400000,
    };
    i2c_param_config(I2C_BUS_B, &cfgB);
    i2c_driver_install(I2C_BUS_B, I2C_MODE_MASTER, 0, 0, 0);

    /* Bus C: PMIC BQ25895 — 100 kHz */
    i2c_config_t cfgC = {
        .mode = I2C_MODE_MASTER, .sda_io_num = I2C_SDA_C,
        .scl_io_num = I2C_SCL_C, .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE, .master.clk_speed = 100000,
    };
    i2c_param_config(I2C_BUS_C, &cfgC);
    i2c_driver_install(I2C_BUS_C, I2C_MODE_MASTER, 0, 0, 0);
}

/** Initialise GPIO for buttons and LED. */
static void init_gpio(void) {
    gpio_config_t in = {
        .pin_bit_mask = (1ULL << GPIO_CROWN) | (1ULL << GPIO_SOS) |
                        (1ULL << GPIO_TOUCH_INT) | (1ULL << GPIO_QMI_INT2) |
                        (1ULL << GPIO_BMP_INT) | (1ULL << GPIO_STTS_DRDY) |
                        (1ULL << GPIO_PMIC_INT),
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&in);

    /* QMI step interrupt (active high, needs pull-down) */
    gpio_set_direction(GPIO_QMI_INT2, GPIO_MODE_INPUT);
    gpio_set_pull_mode(GPIO_QMI_INT2, GPIO_PULLDOWN_ONLY);
    gpio_set_intr_type(GPIO_QMI_INT2, GPIO_INTR_POSEDGE);
    gpio_install_isr_service(0);
    gpio_isr_handler_add(GPIO_QMI_INT2, qmi_step_isr, NULL);

    /* Backlight PWM */
    ledc_timer_config_t ledc_timer = {
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .duty_resolution = LEDC_TIMER_10_BIT,
        .timer_num = LEDC_TIMER_0,
        .freq_hz = 1000,
        .clk_cfg = LEDC_AUTO_CLK,
    };
    ledc_timer_config(&ledc_timer);
    ledc_channel_config_t ledc_ch = {
        .gpio_num = GPIO_DISP_BL,
        .speed_mode = LEDC_LOW_SPEED_MODE,
        .channel = LEDC_CHANNEL_0,
        .timer_sel = LEDC_TIMER_0,
        .duty = 614, /* ~60% of 1023 */
        .hpoint = 0,
    };
    ledc_channel_config(&ledc_ch);
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  FACTORY SELF-TEST                                                       */
/* ─────────────────────────────────────────────────────────────────────── */

/** Run factory test mode. Entered when GPIO_CROWN is held low at boot.
 *  Tests all sensors and outputs PASS/FAIL over USB serial. */
static void factory_test(void) {
    printf("\n=== VEYRO FACTORY SELF-TEST ===\n");
    printf("Firmware: %s\nSerial: %s\n\n", VEYRO_FW_VERSION, g_serial);

    /* Test VC31B */
    uint8_t vc31b_id;
    bool vc31b_ok = (i2c_read_reg(I2C_BUS_B, ADDR_VC31B, 0x00, &vc31b_id) == ESP_OK);
    printf("VC31B (0x33):    %s (id=0x%02X)\n", vc31b_ok ? "PASS" : "FAIL", vc31b_id);

    /* Test QMI6858C */
    uint8_t qmi_id;
    bool qmi_ok = (i2c_read_reg(I2C_BUS_B, ADDR_QMI6858, 0x00, &qmi_id) == ESP_OK && qmi_id == 0x05);
    printf("QMI6858C (0x6A): %s (id=0x%02X)\n", qmi_ok ? "PASS" : "FAIL", qmi_id);

    /* Test BMP581 */
    uint8_t bmp_id;
    bool bmp_ok = (i2c_read_reg(I2C_BUS_B, ADDR_BMP581, 0x01, &bmp_id) == ESP_OK && bmp_id == 0x50);
    printf("BMP581  (0x47):  %s (id=0x%02X)\n", bmp_ok ? "PASS" : "FAIL", bmp_id);

    /* Test STTS22H */
    uint8_t stts_id;
    bool stts_ok = (i2c_read_reg(I2C_BUS_B, ADDR_STTS22H, 0x01, &stts_id) == ESP_OK && stts_id == 0xA0);
    printf("STTS22H (0x3C):  %s (id=0x%02X)\n", stts_ok ? "PASS" : "FAIL", stts_id);

    /* Test DRV2605L */
    uint8_t drv_id;
    bool drv_ok = (i2c_read_reg(I2C_BUS_B, ADDR_DRV2605, 0x00, &drv_id) == ESP_OK);
    printf("DRV2605 (0x5A):  %s (id=0x%02X)\n", drv_ok ? "PASS" : "FAIL", drv_id);

    /* Test FT6336G */
    uint8_t ft_id;
    bool ft_ok = (i2c_read_reg(I2C_BUS_A, ADDR_FT6336G, 0xA8, &ft_id) == ESP_OK);
    printf("FT6336G (0x38):  %s (id=0x%02X)\n", ft_ok ? "PASS" : "FAIL", ft_id);

    /* Test BQ25895 */
    uint8_t pmic_id;
    bool pmic_ok = (i2c_read_reg(I2C_BUS_C, ADDR_BQ25895, 0x0B, &pmic_id) == ESP_OK);
    printf("BQ25895 (0x6B):  %s\n", pmic_ok ? "PASS" : "FAIL");

    /* Read BMP581 pressure */
    read_bmp581();
    printf("Pressure: %.1f hPa — %s\n", g_pressure_hpa,
           (g_pressure_hpa > 900 && g_pressure_hpa < 1100) ? "PASS" : "FAIL");

    /* Read STTS22H temperature */
    read_stts22h();
    printf("Skin Temp: %.1f C — %s\n", g_skin_temp_c,
           (g_skin_temp_c > 15 && g_skin_temp_c < 45) ? "PASS" : "FAIL");

    bool all_pass = vc31b_ok && qmi_ok && bmp_ok && stts_ok && drv_ok && ft_ok && pmic_ok;
    printf("\n=== RESULT: %s ===\n\n", all_pass ? "ALL PASS" : "FAIL — DO NOT SHIP");

    /* Haptic sequence: strong click + double click + alert */
    drv2605_play(1);  vTaskDelay(pdMS_TO_TICKS(300));
    drv2605_play(10); vTaskDelay(pdMS_TO_TICKS(500));
    drv2605_play(47); vTaskDelay(pdMS_TO_TICKS(800));
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  APP_MAIN                                                                */
/* ─────────────────────────────────────────────────────────────────────── */

void app_main(void) {
    /* Initialise NVS */
    esp_err_t nvs_ret = nvs_flash_init();
    if (nvs_ret == ESP_ERR_NVS_NO_FREE_PAGES || nvs_ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }
    nvs_open("veyro", NVS_READWRITE, &g_nvs);

    /* Initialise I2C buses */
    init_i2c_buses();
    init_gpio();

    /* Load NVS settings */
    nvs_load_all();

    /* Generate PIN if not set */
    if (strlen(g_pin_code) != 6) generate_pin();

    /* Initialise sensors */
    g_boot_ms = xTaskGetTickCount() * portTICK_PERIOD_MS;
    bool ppg_ok   = init_vc31b();
    bool imu_ok   = init_qmi6858();
    bool bmp_ok   = init_bmp581();
    bool stts_ok  = init_stts22h();
    bool drv_ok   = init_drv2605();
    bool fs_ok    = true;
    fs_init();
    fs_ok = g_fs_ready;

    printf("Veyro %s SN:%s PPG=%d IMU=%d BMP=%d TEMP=%d HAPTIC=%d FS=%d\n",
           VEYRO_FW_VERSION, g_serial, ppg_ok, imu_ok, bmp_ok, stts_ok, drv_ok, fs_ok);

    /* Factory test mode: hold crown button at boot */
    if (gpio_get_level(GPIO_CROWN) == 0) {
        factory_test();
        /* Stay in test mode — do not start normal tasks */
        while (1) vTaskDelay(pdMS_TO_TICKS(1000));
    }

    /* Check all required hardware. Halt if anything critical is missing. */
    if (!ppg_ok || !imu_ok || !fs_ok) {
        printf("CRITICAL: required hardware missing. Halted.\n");
        fs_log_error("Boot halt: required hardware missing");
        while (1) vTaskDelay(pdMS_TO_TICKS(1000));
    }

    /* Create FreeRTOS primitives */
    g_sensor_queue  = xQueueCreate(16, sizeof(sensor_event_t));
    g_haptic_queue  = xQueueCreate(8,  sizeof(uint8_t));
    g_i2c_b_mutex   = xSemaphoreCreateMutex();
    g_storage_mutex = xSemaphoreCreateMutex();

    /* Start all tasks */
    xTaskCreatePinnedToCore(task_sensors,   "sensors",   8192,  NULL, 5, NULL, 0);
    xTaskCreatePinnedToCore(task_ble,       "ble",       16384, NULL, 4, NULL, 0);
    xTaskCreatePinnedToCore(task_storage,   "storage",   8192,  NULL, 3, NULL, 0);
    xTaskCreatePinnedToCore(task_display,   "display",   24576, NULL, 5, NULL, 1);
    xTaskCreatePinnedToCore(task_haptic,    "haptic",    4096,  NULL, 6, NULL, 1);
    xTaskCreatePinnedToCore(task_power,     "power",     4096,  NULL, 2, NULL, 0);
    xTaskCreatePinnedToCore(task_env,       "env",       4096,  NULL, 2, NULL, 0);
    xTaskCreatePinnedToCore(task_watchdog,  "watchdog",  2048,  NULL, 7, NULL, 0);

    printf("Veyro %s running. PIN: %s\n", VEYRO_FW_VERSION, g_pin_code);
}
