#include "display.h"
#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include "driver/gpio.h"
#include "driver/spi_master.h"
#include "driver/ledc.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include "lvgl.h"

static const char *TAG = "VEYRO_DISP";

#define PIN_NUM_MISO -1
#define PIN_NUM_MOSI 11
#define PIN_NUM_CLK  12
#define PIN_NUM_CS   10
#define PIN_NUM_DC   8
#define PIN_NUM_RST  9
#define PIN_NUM_BCKL 7

static spi_device_handle_t spi;
static lv_disp_drv_t disp_drv;
static lv_disp_draw_buf_t disp_buf;
static lv_color_t *buf1 = NULL;
static lv_color_t *buf2 = NULL;

static lv_obj_t *lbl_time;
static lv_obj_t *lbl_hr;
static lv_obj_t *lbl_steps;
static lv_obj_t *lbl_battery;
static lv_obj_t *lbl_spo2;
static lv_obj_t *arc_steps;

static void lcd_spi_pre_transfer_callback(spi_transaction_t *t) {
    int dc = (int)t->user;
    gpio_set_level(PIN_NUM_DC, dc);
}

static void lcd_cmd(const uint8_t cmd) {
    spi_transaction_t t = {
        .length = 8,
        .tx_buffer = &cmd,
        .user = (void*)0
    };
    spi_device_polling_transmit(spi, &t);
}

static void lcd_data(const uint8_t *data, int len) {
    if (len == 0) return;
    spi_transaction_t t = {
        .length = len * 8,
        .tx_buffer = data,
        .user = (void*)1
    };
    spi_device_polling_transmit(spi, &t);
}

static void disp_flush(lv_disp_drv_t *drv, const lv_area_t *area, lv_color_t *color_p) {
    uint32_t size = (area->x2 - area->x1 + 1) * (area->y2 - area->y1 + 1);
    
    // Column address set
    lcd_cmd(0x2A);
    uint8_t col_data[4] = {
        (uint8_t)(area->x1 >> 8), (uint8_t)(area->x1 & 0xFF),
        (uint8_t)(area->x2 >> 8), (uint8_t)(area->x2 & 0xFF)
    };
    lcd_data(col_data, 4);

    // Row address set
    lcd_cmd(0x2B);
    uint8_t row_data[4] = {
        (uint8_t)(area->y1 >> 8), (uint8_t)(area->y1 & 0xFF),
        (uint8_t)(area->y2 >> 8), (uint8_t)(area->y2 & 0xFF)
    };
    lcd_data(row_data, 4);

    // Write RAM
    lcd_cmd(0x2C);
    
    spi_transaction_t t = {
        .length = size * 16,
        .tx_buffer = color_p,
        .user = (void*)1
    };
    spi_device_transmit(spi, &t);

    lv_disp_flush_ready(drv);
}

void display_init(void) {
    ESP_LOGI(TAG, "Initializing circular display subsystem...");

    gpio_set_direction(PIN_NUM_DC, GPIO_MODE_OUTPUT);
    gpio_set_direction(PIN_NUM_RST, GPIO_MODE_OUTPUT);
    gpio_set_direction(PIN_NUM_BCKL, GPIO_MODE_OUTPUT);

    // Hardware reset
    gpio_set_level(PIN_NUM_RST, 0);
    vTaskDelay(pdMS_TO_TICKS(100));
    gpio_set_level(PIN_NUM_RST, 1);
    vTaskDelay(pdMS_TO_TICKS(100));

    // Turn on backlight
    gpio_set_level(PIN_NUM_BCKL, 1);

    spi_bus_config_t buscfg = {
        .miso_io_num = PIN_NUM_MISO,
        .mosi_io_num = PIN_NUM_MOSI,
        .sclk_io_num = PIN_NUM_CLK,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = DISP_HOR_RES * 40 * sizeof(lv_color_t)
    };
    spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);

    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = 40 * 1000 * 1000,
        .mode = 0,
        .spics_io_num = PIN_NUM_CS,
        .queue_size = 7,
        .pre_cb = lcd_spi_pre_transfer_callback,
    };
    spi_bus_add_device(SPI2_HOST, &devcfg, &spi);

    // Display wake & setup (Sleep out, Display ON)
    lcd_cmd(0x11);
    vTaskDelay(pdMS_TO_TICKS(120));
    lcd_cmd(0x29);

    lv_init();

    buf1 = heap_caps_malloc(DISP_HOR_RES * 40 * sizeof(lv_color_t), MALLOC_CAP_DMA | MALLOC_CAP_INTERNAL);
    buf2 = heap_caps_malloc(DISP_HOR_RES * 40 * sizeof(lv_color_t), MALLOC_CAP_DMA | MALLOC_CAP_INTERNAL);
    lv_disp_draw_buf_init(&disp_buf, buf1, buf2, DISP_HOR_RES * 40);

    lv_disp_drv_init(&disp_drv);
    disp_drv.hor_res = DISP_HOR_RES;
    disp_drv.ver_res = DISP_VER_RES;
    disp_drv.flush_cb = disp_flush;
    disp_drv.draw_buf = &disp_buf;
    lv_disp_drv_register(&disp_drv);

    // Build Default Watch Face (Minimal Circular Dark)
    lv_obj_t *scr = lv_scr_act();
    lv_obj_set_style_bg_color(scr, lv_color_hex(0x0A0E17), 0);

    // Circular Step Progress Ring
    arc_steps = lv_arc_create(scr);
    lv_obj_set_size(arc_steps, 320, 320);
    lv_obj_align(arc_steps, LV_ALIGN_CENTER, 0, 0);
    lv_arc_set_angles(arc_steps, 135, 45);
    lv_arc_set_range(arc_steps, 0, 10000);
    lv_arc_set_value(arc_steps, 0);
    lv_obj_set_style_arc_color(arc_steps, lv_color_hex(0x1F2937), LV_PART_MAIN);
    lv_obj_set_style_arc_color(arc_steps, lv_color_hex(0x10B981), LV_PART_INDICATOR);
    lv_obj_set_style_arc_width(arc_steps, 10, LV_PART_MAIN);
    lv_obj_set_style_arc_width(arc_steps, 10, LV_PART_INDICATOR);
    lv_obj_remove_style(arc_steps, NULL, LV_PART_KNOB);

    // Time Label (Center)
    lbl_time = lv_label_create(scr);
    lv_obj_align(lbl_time, LV_ALIGN_CENTER, 0, -25);
    lv_obj_set_style_text_font(lbl_time, &lv_font_montserrat_36, 0);
    lv_obj_set_style_text_color(lbl_time, lv_color_hex(0xFFFFFF), 0);
    lv_label_set_text(lbl_time, "12:00");

    // Heart Rate (Top Left offset)
    lbl_hr = lv_label_create(scr);
    lv_obj_align(lbl_hr, LV_ALIGN_CENTER, -60, 45);
    lv_obj_set_style_text_font(lbl_hr, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(lbl_hr, lv_color_hex(0xEF4444), 0);
    lv_label_set_text(lbl_hr, "-- bpm");

    // SpO2 (Top Right offset)
    lbl_spo2 = lv_label_create(scr);
    lv_obj_align(lbl_spo2, LV_ALIGN_CENTER, 60, 45);
    lv_obj_set_style_text_font(lbl_spo2, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(lbl_spo2, lv_color_hex(0x3B82F6), 0);
    lv_label_set_text(lbl_spo2, "-- %");

    // Steps Counter (Bottom)
    lbl_steps = lv_label_create(scr);
    lv_obj_align(lbl_steps, LV_ALIGN_CENTER, 0, 85);
    lv_obj_set_style_text_font(lbl_steps, &lv_font_montserrat_16, 0);
    lv_obj_set_style_text_color(lbl_steps, lv_color_hex(0x10B981), 0);
    lv_label_set_text(lbl_steps, "0 steps");

    // Battery / Status (Top)
    lbl_battery = lv_label_create(scr);
    lv_obj_align(lbl_battery, LV_ALIGN_CENTER, 0, -85);
    lv_obj_set_style_text_font(lbl_battery, &lv_font_montserrat_14, 0);
    lv_obj_set_style_text_color(lbl_battery, lv_color_hex(0x9CA3AF), 0);
    lv_label_set_text(lbl_battery, "100%");

    ESP_LOGI(TAG, "Display and LVGL UI initialized successfully.");
}

void display_update_vitals(int hr, int spo2, int hrv, int stress, uint32_t steps, int battery, bool charging, float temp) {
    if (!lbl_hr) return;

    char buf[32];
    if (hr > 0) snprintf(buf, sizeof(buf), "â¥ %d", hr);
    else snprintf(buf, sizeof(buf), "â¥ --");
    lv_label_set_text(lbl_hr, buf);

    if (spo2 > 0) snprintf(buf, sizeof(buf), "O2 %d%%", spo2);
    else snprintf(buf, sizeof(buf), "O2 --%%");
    lv_label_set_text(lbl_spo2, buf);

    snprintf(buf, sizeof(buf), "%lu stp", (unsigned long)steps);
    lv_label_set_text(lbl_steps, buf);
    if (arc_steps) lv_arc_set_value(arc_steps, steps % 10000);

    snprintf(buf, sizeof(buf), "%d%% %s", battery, charging ? "⚡" : "");
    lv_label_set_text(lbl_battery, buf);
}

void display_set_watchface(int face_id) {
    // Face ID selector for alternative themes / layouts
}

void display_set_theme(int theme_id) {
    // Theme accent color selector
}
