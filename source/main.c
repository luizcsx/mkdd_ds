#include <nds.h>

void vblankHandler(void) {
    soundVirtualVBlank();
}

int main(void) {
    readUserSettings();
    ledBlink(0);
    irqInit();
    irqSet(IRQ_VBLANK, vblankHandler);
    irqEnable(IRQ_VBLANK);
    
    while (1) {
        swiWaitForVBlank();
    }
    return 0;
}
