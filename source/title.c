#include <nds.h>
#include "title.h"

#include "Title_t_screen.h"
#include "Title_b_screen.h"

void title_init(void) {
    videoSetMode(MODE_FB0);
    vramSetBankA(VRAM_A_LCD);

    videoSetModeSub(MODE_FB0);
    vramSetBankC(VRAM_C_SUB_BG);

    int bg_main = bgInit(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0);
    int bg_sub  = bgInitSub(3, BgType_Bmp16, BgSize_B16_256x256, 0, 0);

    dmaCopy(title_topBitmap,    bgGetGfxPtr(bg_main), title_topBitmapLen);
    dmaCopy(title_bottomBitmap, bgGetGfxPtr(bg_sub),  title_bottomBitmapLen);
}

AppState title_update(void) {
    scanKeys();
    u32 keys = keysDown();

    if (keys & (KEY_A | KEY_START)) {
        return STATE_MAIN_MENU;
    }

    return STATE_TITLE;
}
