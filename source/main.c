#include <nds.h>
#include "title.h"

int main(void) {
    AppState state = STATE_TITLE;

    title_init();

    while (1) {
        switch (state) {
            case STATE_TITLE:
                state = title_update();
                break;

            case STATE_MAIN_MENU:
                break;
        }

        swiWaitForVBlank();
    }

    return 0;
}
