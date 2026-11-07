#include "display.h"
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
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

/* ─────────────────────────────────────────────────────────────────────── */
/*  THEMES                                                                  */
/* ─────────────────────────────────────────────────────────────────────── */

/* Six palettes. Every face is built from these colours, so switching a theme
 * repaints all five faces instead of only the one on screen. */
typedef struct {
    uint32_t bg;
    uint32_t surface;
    uint32_t primary;
    uint32_t secondary;
    uint32_t text;
    uint32_t muted;
} palette_t;

static const palette_t g_palettes[THEME_COUNT] = {
    [THEME_CAMBRIC_AMBER] = {0x0A0E17, 0x161C28, 0xF59E0B, 0xFBBF24, 0xFFFFFF, 0x9CA3AF},
    [THEME_CYBER_CYAN]    = {0x061018, 0x0E2230, 0x22D3EE, 0x67E8F9, 0xECFEFF, 0x7DD3FC},
    [THEME_EMERALD_GREEN] = {0x06130D, 0x0F2419, 0x10B981, 0x34D399, 0xECFDF5, 0x86EFAC},
    [THEME_CRIMSON_RED]   = {0x150608, 0x2A0F13, 0xEF4444, 0xF87171, 0xFFF1F2, 0xFCA5A5},
    [THEME_NEO_VIOLET]    = {0x0D0718, 0x1D1230, 0xA855F7, 0xC084FC, 0xF5F3FF, 0xD8B4FE},
    [THEME_MONOCHROME]    = {0x000000, 0x141414, 0xFFFFFF, 0xD4D4D4, 0xFFFFFF, 0x9CA3AF},
};

/* ─────────────────────────────────────────────────────────────────────── */
/*  FACE STATE                                                              */
/* ─────────────────────────────────────────────────────────────────────── */

typedef struct {
    lv_obj_t *scr;
    lv_obj_t *time;
    lv_obj_t *date;
    lv_obj_t *hr;
    lv_obj_t *spo2;
    lv_obj_t *steps;
    lv_obj_t *bat;
    lv_obj_t *note;
    lv_obj_t *arc_steps;
    lv_obj_t *arc_hr;
    lv_obj_t *arc_spo2;
    lv_obj_t *bar_steps;
    lv_obj_t *bar_bat;
    lv_obj_t *hand_h;
    lv_obj_t *hand_m;
    lv_obj_t *hand_s;
    lv_point_t h_pts[2];
    lv_point_t m_pts[2];
    lv_point_t s_pts[2];
} face_ui_t;

static face_ui_t g_faces[WATCHFACE_COUNT];
static watchface_id_t g_current_face = WATCHFACE_ANALOG_CLASSIC;
static theme_palette_t g_current_theme = THEME_CAMBRIC_AMBER;
static bool g_ui_ready = false;
static uint8_t g_brightness_pct = 60;

#define DISP_CENTER (DISP_HOR_RES / 2)

static const char *const k_days[7] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
static const char *const k_months[12] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

/* ─────────────────────────────────────────────────────────────────────── */
/*  SMALL BUILDERS                                                          */
/* ─────────────────────────────────────────────────────────────────────── */

static lv_obj_t *mk_label(lv_obj_t *parent, const char *text,
                          const lv_font_t *font, lv_color_t color,
                          lv_align_t align, lv_coord_t x, lv_coord_t y) {
    lv_obj_t *l = lv_label_create(parent);
    lv_label_set_text(l, text);
    lv_obj_set_style_text_font(l, font, 0);
    lv_obj_set_style_text_color(l, color, 0);
    lv_obj_align(l, align, x, y);
    return l;
}

static lv_obj_t *mk_panel(lv_obj_t *parent, lv_coord_t w, lv_coord_t h,
                          lv_coord_t radius, lv_color_t color,
                          lv_align_t align, lv_coord_t x, lv_coord_t y) {
    lv_obj_t *o = lv_obj_create(parent);
    lv_obj_remove_style_all(o);
    lv_obj_set_size(o, w, h);
    lv_obj_set_style_bg_color(o, color, 0);
    lv_obj_set_style_bg_opa(o, LV_OPA_COVER, 0);
    lv_obj_set_style_radius(o, radius, 0);
    lv_obj_clear_flag(o, LV_OBJ_FLAG_SCROLLABLE);
    lv_obj_clear_flag(o, LV_OBJ_FLAG_CLICKABLE);
    lv_obj_align(o, align, x, y);
    return o;
}

static lv_obj_t *mk_arc(lv_obj_t *parent, lv_coord_t size, lv_coord_t width,
                        lv_color_t track, lv_color_t indicator,
                        lv_align_t align, lv_coord_t x, lv_coord_t y) {
    lv_obj_t *a = lv_arc_create(parent);
    lv_obj_set_size(a, size, size);
    lv_obj_align(a, align, x, y);
    lv_arc_set_bg_angles(a, 135, 45);
    lv_arc_set_angles(a, 135, 45);
    lv_arc_set_range(a, 0, 100);
    lv_arc_set_value(a, 0);
    lv_obj_set_style_arc_color(a, track, LV_PART_MAIN);
    lv_obj_set_style_arc_width(a, width, LV_PART_MAIN);
    lv_obj_set_style_arc_color(a, indicator, LV_PART_INDICATOR);
    lv_obj_set_style_arc_width(a, width, LV_PART_INDICATOR);
    lv_obj_remove_style(a, NULL, LV_PART_KNOB);
    lv_obj_clear_flag(a, LV_OBJ_FLAG_CLICKABLE);
    return a;
}

static lv_obj_t *mk_bar(lv_obj_t *parent, lv_coord_t w, lv_coord_t h,
                        lv_color_t track, lv_color_t indicator,
                        lv_align_t align, lv_coord_t x, lv_coord_t y) {
    lv_obj_t *b = lv_bar_create(parent);
    lv_obj_set_size(b, w, h);
    lv_obj_align(b, align, x, y);
    lv_bar_set_range(b, 0, 100);
    lv_bar_set_value(b, 0, LV_ANIM_OFF);
    lv_obj_set_style_bg_color(b, track, LV_PART_MAIN);
    lv_obj_set_style_bg_opa(b, LV_OPA_COVER, LV_PART_MAIN);
    lv_obj_set_style_radius(b, h / 2, LV_PART_MAIN);
    lv_obj_set_style_border_width(b, 0, LV_PART_MAIN);
    lv_obj_set_style_bg_color(b, indicator, LV_PART_INDICATOR);
    lv_obj_set_style_bg_opa(b, LV_OPA_COVER, LV_PART_INDICATOR);
    lv_obj_set_style_radius(b, h / 2, LV_PART_INDICATOR);
    lv_obj_clear_flag(b, LV_OBJ_FLAG_CLICKABLE);
    return b;
}

static lv_obj_t *mk_line(lv_obj_t *parent, lv_color_t color, lv_coord_t width,
                         lv_point_t *pts) {
    lv_obj_t *l = lv_line_create(parent);
    lv_line_set_points(l, pts, 2);
    lv_obj_set_style_line_color(l, color, 0);
    lv_obj_set_style_line_width(l, width, 0);
    lv_obj_set_style_line_rounded(l, true, 0);
    return l;
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  FACE BUILDERS                                                           */
/* ─────────────────────────────────────────────────────────────────────── */

/* Face 1: Classic Analog Dial. Tick marks and three real hands. */
static void build_analog(face_ui_t *f, const palette_t *p) {
    f->scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(f->scr, lv_color_hex(p->bg), 0);

    /* 12 hour ticks, longer and brighter at the quarters. */
    static lv_point_t tick_pts[12][2];
    for (int i = 0; i < 12; i++) {
        float rad = (float)i * 30.0f * 3.14159265f / 180.0f;
        int outer = 158;
        int inner = (i % 3 == 0) ? 132 : 144;
        tick_pts[i][0].x = DISP_CENTER + (lv_coord_t)(sinf(rad) * inner);
        tick_pts[i][0].y = DISP_CENTER - (lv_coord_t)(cosf(rad) * inner);
        tick_pts[i][1].x = DISP_CENTER + (lv_coord_t)(sinf(rad) * outer);
        tick_pts[i][1].y = DISP_CENTER - (lv_coord_t)(cosf(rad) * outer);
        lv_obj_t *t = mk_line(f->scr, lv_color_hex(i % 3 == 0 ? p->primary : p->muted),
                              i % 3 == 0 ? 4 : 2, tick_pts[i]);
        (void)t;
    }

    f->hand_h = mk_line(f->scr, lv_color_hex(p->text), 7, f->h_pts);
    f->hand_m = mk_line(f->scr, lv_color_hex(p->text), 4, f->m_pts);
    f->hand_s = mk_line(f->scr, lv_color_hex(p->primary), 2, f->s_pts);

    /* Hub. */
    lv_obj_t *hub = mk_panel(f->scr, 14, 14, LV_RADIUS_CIRCLE,
                             lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 0);
    (void)hub;

    f->time = mk_label(f->scr, "--:--", &lv_font_montserrat_16,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 78);
    f->date = mk_label(f->scr, "", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 100);
    f->hr = mk_label(f->scr, "-- bpm", &lv_font_montserrat_14,
                     lv_color_hex(p->secondary), LV_ALIGN_CENTER, -92, -70);
    f->steps = mk_label(f->scr, "0", &lv_font_montserrat_14,
                        lv_color_hex(p->primary), LV_ALIGN_CENTER, 92, -70);
    f->bat = mk_label(f->scr, "--%", &lv_font_montserrat_14,
                      lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, -118);
}

/* Face 2: Minimal Sport. One large time and a quiet row of numbers. */
static void build_minimal(face_ui_t *f, const palette_t *p) {
    f->scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(f->scr, lv_color_hex(p->bg), 0);

    mk_panel(f->scr, 300, 2, 1, lv_color_hex(p->surface), LV_ALIGN_CENTER, 0, -76);

    f->time = mk_label(f->scr, "--:--", &lv_font_montserrat_36,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 0, -34);
    f->date = mk_label(f->scr, "", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 8);

    f->hr = mk_label(f->scr, "-- bpm", &lv_font_montserrat_16,
                     lv_color_hex(p->secondary), LV_ALIGN_CENTER, 0, 58);
    f->steps = mk_label(f->scr, "0 steps", &lv_font_montserrat_16,
                        lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 86);
    f->spo2 = mk_label(f->scr, "-- %", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 112);
    f->bat = mk_label(f->scr, "--%", &lv_font_montserrat_14,
                      lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, -118);
}

/* Face 3: Health Rings. Three concentric arcs for steps, HR and SpO2. */
static void build_fitness(face_ui_t *f, const palette_t *p) {
    f->scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(f->scr, lv_color_hex(p->bg), 0);

    f->arc_steps = mk_arc(f->scr, 320, 12, lv_color_hex(p->surface),
                          lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 0);
    lv_arc_set_range(f->arc_steps, 0, 10000);
    f->arc_hr = mk_arc(f->scr, 270, 12, lv_color_hex(p->surface),
                       lv_color_hex(p->secondary), LV_ALIGN_CENTER, 0, 0);
    lv_arc_set_range(f->arc_hr, 0, 200);
    f->arc_spo2 = mk_arc(f->scr, 220, 12, lv_color_hex(p->surface),
                         lv_color_hex(p->text), LV_ALIGN_CENTER, 0, 0);
    lv_arc_set_range(f->arc_spo2, 0, 100);

    f->time = mk_label(f->scr, "--:--", &lv_font_montserrat_28,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 0, -30);
    f->date = mk_label(f->scr, "", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 0);
    f->hr = mk_label(f->scr, "-- bpm", &lv_font_montserrat_16,
                     lv_color_hex(p->secondary), LV_ALIGN_CENTER, 0, 34);
    f->spo2 = mk_label(f->scr, "-- %", &lv_font_montserrat_14,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 0, 58);
    f->steps = mk_label(f->scr, "0 steps", &lv_font_montserrat_14,
                        lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 132);
    f->bat = mk_label(f->scr, "--%", &lv_font_montserrat_14,
                      lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, -132);
}

/* Face 4: Cyber Pixel. Grid, blocky panels and a bottom progress bar. */
static void build_cyber(face_ui_t *f, const palette_t *p) {
    f->scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(f->scr, lv_color_hex(p->bg), 0);

    /* A coarse grid, drawn as thin panels so it costs no image memory. */
    for (int i = 1; i < 6; i++) {
        mk_panel(f->scr, 1, 300, 0, lv_color_hex(p->surface),
                 LV_ALIGN_CENTER, -150 + i * 50, 0);
        mk_panel(f->scr, 300, 1, 0, lv_color_hex(p->surface),
                 LV_ALIGN_CENTER, 0, -150 + i * 50);
    }

    f->time = mk_label(f->scr, "--:--", &lv_font_montserrat_36,
                       lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, -46);
    f->date = mk_label(f->scr, "", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, -4);
    f->note = mk_label(f->scr, "SYS.ONLINE", &lv_font_montserrat_14,
                       lv_color_hex(p->secondary), LV_ALIGN_CENTER, 0, -124);

    f->hr = mk_label(f->scr, "HR --", &lv_font_montserrat_16,
                     lv_color_hex(p->secondary), LV_ALIGN_CENTER, -78, 58);
    f->spo2 = mk_label(f->scr, "O2 --", &lv_font_montserrat_16,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 78, 58);
    f->steps = mk_label(f->scr, "STP 0", &lv_font_montserrat_14,
                        lv_color_hex(p->primary), LV_ALIGN_CENTER, -78, 92);
    f->bat = mk_label(f->scr, "BAT --", &lv_font_montserrat_14,
                      lv_color_hex(p->muted), LV_ALIGN_CENTER, 78, 92);

    f->bar_steps = mk_bar(f->scr, 260, 8, lv_color_hex(p->surface),
                          lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 128);
}

/* Face 5: Chrono Dash. Four telemetry tiles and two bars. */
static void build_chrono(face_ui_t *f, const palette_t *p) {
    f->scr = lv_obj_create(NULL);
    lv_obj_set_style_bg_color(f->scr, lv_color_hex(p->bg), 0);

    f->time = mk_label(f->scr, "--:--", &lv_font_montserrat_28,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 0, -132);
    f->date = mk_label(f->scr, "", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, -104);

    lv_obj_t *t1 = mk_panel(f->scr, 140, 76, 12, lv_color_hex(p->surface),
                            LV_ALIGN_CENTER, -76, -34);
    lv_obj_t *t2 = mk_panel(f->scr, 140, 76, 12, lv_color_hex(p->surface),
                            LV_ALIGN_CENTER, 76, -34);
    lv_obj_t *t3 = mk_panel(f->scr, 140, 76, 12, lv_color_hex(p->surface),
                            LV_ALIGN_CENTER, -76, 54);
    lv_obj_t *t4 = mk_panel(f->scr, 140, 76, 12, lv_color_hex(p->surface),
                            LV_ALIGN_CENTER, 76, 54);

    f->hr = mk_label(t1, "-- bpm", &lv_font_montserrat_16,
                     lv_color_hex(p->secondary), LV_ALIGN_CENTER, 0, 0);
    f->spo2 = mk_label(t2, "-- %", &lv_font_montserrat_16,
                       lv_color_hex(p->text), LV_ALIGN_CENTER, 0, 0);
    f->steps = mk_label(t3, "0 steps", &lv_font_montserrat_16,
                        lv_color_hex(p->primary), LV_ALIGN_CENTER, 0, 0);
    f->bat = mk_label(t4, "--%", &lv_font_montserrat_16,
                      lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 0);

    f->bar_steps = mk_bar(f->scr, 130, 8, lv_color_hex(p->surface),
                          lv_color_hex(p->primary), LV_ALIGN_CENTER, -76, 104);
    f->bar_bat = mk_bar(f->scr, 130, 8, lv_color_hex(p->surface),
                        lv_color_hex(p->secondary), LV_ALIGN_CENTER, 76, 104);

    f->note = mk_label(f->scr, "TELEMETRY", &lv_font_montserrat_14,
                       lv_color_hex(p->muted), LV_ALIGN_CENTER, 0, 142);
}

static void build_face(int index, const palette_t *p) {
    face_ui_t *f = &g_faces[index];
    memset(f, 0, sizeof(*f));
    switch ((watchface_id_t)index) {
    case WATCHFACE_ANALOG_CLASSIC:  build_analog(f, p);  break;
    case WATCHFACE_DIGITAL_MINIMAL: build_minimal(f, p); break;
    case WATCHFACE_FITNESS_PRO:     build_fitness(f, p); break;
    case WATCHFACE_CYBER_PIXEL:     build_cyber(f, p);   break;
    case WATCHFACE_CHRONO_DASH:     build_chrono(f, p);  break;
    default:                        build_minimal(f, p); break;
    }
}

/** Build all five screens, then delete the previous ones.
 *
 *  Building before deleting keeps an active screen alive throughout. The
 *  previous screens are deleted only after the new one is loaded. */
static void rebuild_faces(void) {
    lv_obj_t *old[WATCHFACE_COUNT];
    for (int i = 0; i < WATCHFACE_COUNT; i++) old[i] = g_faces[i].scr;

    const palette_t *p = &g_palettes[g_current_theme];
    for (int i = 0; i < WATCHFACE_COUNT; i++) build_face(i, p);

    lv_scr_load(g_faces[g_current_face].scr);
    for (int i = 0; i < WATCHFACE_COUNT; i++) {
        if (old[i] != NULL) lv_obj_del(old[i]);
    }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  SPI / PANEL DRIVER                                                      */
/* ─────────────────────────────────────────────────────────────────────── */

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
    /* PIN_NUM_BCKL is owned by the LEDC channel configured in app_main.
     * Driving it as a plain GPIO here would detach the PWM. */

    // Hardware reset
    gpio_set_level(PIN_NUM_RST, 0);
    vTaskDelay(pdMS_TO_TICKS(100));
    gpio_set_level(PIN_NUM_RST, 1);
    vTaskDelay(pdMS_TO_TICKS(100));

    /* Backlight comes up at the default level through the LEDC channel. */
    display_set_brightness(g_brightness_pct);

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

    rebuild_faces();
    g_ui_ready = true;

    ESP_LOGI(TAG, "Display and LVGL UI initialized successfully.");
}

/* ─────────────────────────────────────────────────────────────────────── */
/*  RUNTIME UPDATES                                                         */
/* ─────────────────────────────────────────────────────────────────────── */

static void update_hands(face_ui_t *f, const struct tm *tm) {
    if (!f->hand_h || !f->hand_m || !f->hand_s) return;
    const float pi = 3.14159265f;

    float hour_deg   = (float)(tm->tm_hour % 12) * 30.0f + (float)tm->tm_min * 0.5f;
    float minute_deg = (float)tm->tm_min * 6.0f + (float)tm->tm_sec * 0.1f;
    float second_deg = (float)tm->tm_sec * 6.0f;

    struct { lv_obj_t *line; lv_point_t *pts; float deg; int len; } hands[3] = {
        {f->hand_h, f->h_pts, hour_deg, 70},
        {f->hand_m, f->m_pts, minute_deg, 96},
        {f->hand_s, f->s_pts, second_deg, 112},
    };
    for (int i = 0; i < 3; i++) {
        float rad = hands[i].deg * pi / 180.0f;
        hands[i].pts[0].x = DISP_CENTER;
        hands[i].pts[0].y = DISP_CENTER;
        hands[i].pts[1].x = DISP_CENTER + (lv_coord_t)(sinf(rad) * hands[i].len);
        hands[i].pts[1].y = DISP_CENTER - (lv_coord_t)(cosf(rad) * hands[i].len);
        lv_line_set_points(hands[i].line, hands[i].pts, 2);
    }
}

void display_set_time(uint32_t unix_time) {
    if (!g_ui_ready) return;
    time_t t = (time_t)unix_time;
    struct tm tm;
    gmtime_r(&t, &tm);

    char hhmm[8];
    char date[24];
    snprintf(hhmm, sizeof(hhmm), "%02d:%02d", tm.tm_hour, tm.tm_min);
    snprintf(date, sizeof(date), "%s %d %s", k_days[tm.tm_wday], tm.tm_mday,
             k_months[tm.tm_mon]);

    /* Update every face, not just the visible one, so switching faces shows
     * the right time immediately instead of waiting for the next second. */
    for (int i = 0; i < WATCHFACE_COUNT; i++) {
        face_ui_t *each = &g_faces[i];
        if (each->time) lv_label_set_text(each->time, hhmm);
        if (each->date) lv_label_set_text(each->date, date);
        update_hands(each, &tm);
    }
}

void display_update_vitals(int hr, int spo2, int hrv, int stress, uint32_t steps,
                           int battery, bool charging, float temp) {
    (void)hrv;
    (void)stress;
    (void)temp;
    if (!g_ui_ready) return;

    face_ui_t *f = &g_faces[g_current_face];
    if (!f->scr) return;

    char buf[32];
    if (f->hr) {
        if (hr > 0) snprintf(buf, sizeof(buf), "\xE2\x99\xA5 %d bpm", hr);
        else snprintf(buf, sizeof(buf), "\xE2\x99\xA5 -- bpm");
        lv_label_set_text(f->hr, buf);
    }
    if (f->spo2) {
        if (spo2 > 0) snprintf(buf, sizeof(buf), "O2 %d%%", spo2);
        else snprintf(buf, sizeof(buf), "O2 --%%");
        lv_label_set_text(f->spo2, buf);
    }
    if (f->steps) {
        snprintf(buf, sizeof(buf), "%lu steps", (unsigned long)steps);
        lv_label_set_text(f->steps, buf);
    }
    if (f->bat) {
        snprintf(buf, sizeof(buf), "%d%%%s", battery, charging ? " \xE2\x9A\xA1" : "");
        lv_label_set_text(f->bat, buf);
    }

    if (f->arc_steps) lv_arc_set_value(f->arc_steps, steps > 10000 ? 10000 : (int)steps);
    if (f->arc_hr) lv_arc_set_value(f->arc_hr, hr > 200 ? 200 : (hr < 0 ? 0 : hr));
    if (f->arc_spo2) lv_arc_set_value(f->arc_spo2, spo2 < 0 ? 0 : (spo2 > 100 ? 100 : spo2));
    if (f->bar_steps) lv_bar_set_value(f->bar_steps, (int)((steps % 10000) / 100), LV_ANIM_OFF);
    if (f->bar_bat) lv_bar_set_value(f->bar_bat, battery, LV_ANIM_OFF);
}

void display_set_watchface(watchface_id_t face_id) {
    if (face_id >= WATCHFACE_COUNT) face_id = WATCHFACE_ANALOG_CLASSIC;
    g_current_face = face_id;
    if (g_ui_ready && g_faces[face_id].scr) {
        lv_scr_load(g_faces[face_id].scr);
    }
}

void display_set_theme(theme_palette_t theme_id) {
    if (theme_id >= THEME_COUNT) return;
    g_current_theme = theme_id;
    if (!g_ui_ready) return;
    rebuild_faces();
}

void display_set_brightness(uint8_t pct) {
    if (pct > 100) pct = 100;
    if (pct < 1) pct = 1;
    g_brightness_pct = pct;
    /* 10-bit duty, matching the timer configured in app_main. */
    uint32_t duty = (uint32_t)((1023u * pct) / 100u);
    ledc_set_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0, duty);
    ledc_update_duty(LEDC_LOW_SPEED_MODE, LEDC_CHANNEL_0);
}

void display_set_complication(int slot_index, complication_type_t comp) {
    (void)slot_index;
    (void)comp;
}

void display_toggle_aod(bool enable) {
    (void)enable;
}

watch_ui_config_t* display_get_config(void) {
    static watch_ui_config_t cfg;
    cfg.watchface = g_current_face;
    cfg.theme = g_current_theme;
    cfg.brightness_pct = g_brightness_pct;
    return &cfg;
}
