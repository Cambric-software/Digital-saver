#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdbool.h>
#include <stdint.h>

#define DISP_HOR_RES 360
#define DISP_VER_RES 360

typedef enum {
    WATCHFACE_ANALOG_CLASSIC = 0,
    WATCHFACE_DIGITAL_MINIMAL = 1,
    WATCHFACE_FITNESS_PRO     = 2,
    WATCHFACE_CYBER_PIXEL     = 3,
    WATCHFACE_CHRONO_DASH     = 4,
    WATCHFACE_COUNT
} watchface_id_t;

typedef enum {
    THEME_CAMBRIC_AMBER = 0,
    THEME_CYBER_CYAN    = 1,
    THEME_EMERALD_GREEN = 2,
    THEME_CRIMSON_RED   = 3,
    THEME_NEO_VIOLET    = 4,
    THEME_MONOCHROME    = 5,
    THEME_COUNT
} theme_palette_t;

typedef enum {
    COMPLICATION_STEPS = 0,
    COMPLICATION_HEART_RATE,
    COMPLICATION_SPO2,
    COMPLICATION_BATTERY,
    COMPLICATION_CALORIES,
    COMPLICATION_HRV,
    COMPLICATION_NONE
} complication_type_t;

typedef struct {
    watchface_id_t watchface;
    theme_palette_t theme;
    complication_type_t slot_top;
    complication_type_t slot_bottom;
    complication_type_t slot_left;
    complication_type_t slot_right;
    uint8_t brightness_pct;
    bool always_on_display;
    bool show_seconds_hand;
} watch_ui_config_t;

void display_init(void);
void display_update_vitals(int hr, int spo2, int hrv, int stress, uint32_t steps, int battery, bool charging, float temp);
void display_set_watchface(watchface_id_t face_id);
void display_set_theme(theme_palette_t theme_id);
void display_set_brightness(uint8_t pct);
void display_set_complication(int slot_index, complication_type_t comp);
void display_toggle_aod(bool enable);
watch_ui_config_t* display_get_config(void);

#endif /* DISPLAY_H */
