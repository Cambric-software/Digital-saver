#include "lvgl.h"
#include <stdio.h>
#include <unistd.h>

int main(void) {
    lv_init();
    // TODO: init display and input drivers for the 1.43" AMOLED.
    lv_obj_t *label = lv_label_create(lv_scr_act());
    lv_label_set_text(label, "Veyro");
    lv_obj_center(label);

    while (1) {
        lv_timer_handler();
        usleep(5000);
    }
    return 0;
}