#ifndef TITLE_H
#define TITLE_H

typedef enum {
    STATE_TITLE,
    STATE_MAIN_MENU,
} AppState;

void title_init(void);

AppState title_update(void);

#endif
