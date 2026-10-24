#include "lvgl.h"
#include <stdio.h>
#include <unistd.h>

static void btn_event_cb(lv_event_t *e) {
    lv_event_code_t code = lv_event_get_code(e);
    if (code == LV_EVENT_CLICKED) {
        LV_LOG_USER("Button clicked");
    }
}

int main(void) {
    lv_init();
    // TODO: init display driver for 1.43" AMOLED (QSPI/MIPI).
    // TODO: init touch driver.

    lv_obj_t *label = lv_label_create(lv_scr_act());
    lv_label_set_text(label, "Veyro");
    lv_obj_align(label, LV_ALIGN_TOP_MID, 0, 20);

    lv_obj_t *btn = lv_btn_create(lv_scr_act());
    lv_obj_set_size(btn, 120, 50);
    lv_obj_center(btn);
    lv_obj_add_event_cb(btn, btn_event_cb, LV_EVENT_ALL, NULL);

    lv_obj_t *btn_label = lv_label_create(btn);
    lv_label_set_text(btn_label, "Tap");
    lv_obj_center(btn_label);

    while (1) {
        lv_timer_handler();
        usleep(5000);
    }
    return 0;
}