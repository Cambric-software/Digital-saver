#include "lvgl.h"
#include <stdio.h>
#include <unistd.h>

static void btn_event_cb(lv_event_t *e) {
    lv_event_code_t code = lv_event_get_code(e);
    if (code == LV_EVENT_CLICKED) {
        LV_LOG_USER("Button clicked");
    }
}

static void create_clock_face(void) {
    lv_obj_t *scr = lv_scr_act();
    lv_obj_t *label = lv_label_create(scr);
    lv_label_set_text(label, "Veyro\n12:00");
    lv_obj_set_style_text_align(label, LV_TEXT_ALIGN_CENTER, 0);
    lv_obj_center(label);
}

static void create_menu(void) {
    lv_obj_t *scr = lv_scr_act();
    lv_obj_t *btn = lv_btn_create(scr);
    lv_obj_set_size(btn, 120, 50);
    lv_obj_align(btn, LV_ALIGN_BOTTOM_MID, 0, -20);
    lv_obj_add_event_cb(btn, btn_event_cb, LV_EVENT_ALL, NULL);

    lv_obj_t *btn_label = lv_label_create(btn);
    lv_label_set_text(btn_label, "Apps");
    lv_obj_center(btn_label);
}

int main(void) {
    lv_init();
    // TODO: init display driver for 1.43" AMOLED (QSPI/MIPI).
    // TODO: init touch driver.

    create_clock_face();
    create_menu();

    while (1) {
        lv_timer_handler();
        usleep(5000);
    }
    return 0;
}