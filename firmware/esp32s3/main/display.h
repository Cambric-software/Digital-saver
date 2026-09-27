#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdbool.h>
#include <stdint.h>

#define DISP_HOR_RES 360
#define DISP_VER_RES 360

void display_init(void);
void display_update_vitals(int hr, int spo2, int hrv, int stress, uint32_t steps, int battery, bool charging, float temp);
void display_set_watchface(int face_id);
void display_set_theme(int theme_id);

#endif /* DISPLAY_H */
