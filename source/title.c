#include <nds.h>
#include "title.h"

#include "Title_t_screen.h"
#include "Title_b_screen.h"

void title_init(void) {
    videoSetMode(MODE_5_2D);
    vramSetBankA(VRAM_A_MAIN_BG);

    videoSetModeSub(MODE_5_2D);
    vramSetBankC(VRAM_C_SUB_BG);

    int bg_main = bgInit(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0);
    int bg_sub  = bgInitSub(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0);

    dmaCopy(Title_t_screenBitmap, bgGetGfxPtr(bg_main), Title_t_screenBitmapLen);
    dmaCopy(Title_b_screenBitmap, bgGetGfxPtr(bg_sub),  Title_b_screenBitmapLen);
}

AppState title_update(void) {
    scanKeys();
    u32 keys = keysDown();

    if (keys & (KEY_A | KEY_START)) {
        return STATE_MAIN_MENU;
    }

    return STATE_TITLE;
}
