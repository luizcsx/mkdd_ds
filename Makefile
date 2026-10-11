ifeq ($(strip $(DEVKITARM)),)
$(error Defina DEVKITARM no ambiente)
endif
ifeq ($(strip $(DEVKITPRO)),)
$(error Defina DEVKITPRO no ambiente)
endif

TARGET      := mkddds
BUILD       := build
SOURCES     := source

GAME_TITLE  := MARIOKART
GAME_CODE   := MKDD
MAKER_CODE  := 00
GAME_ICON   := icon.bmp

CC      := $(DEVKITARM)/bin/arm-none-eabi-gcc
OBJCOPY := $(DEVKITARM)/bin/arm-none-eabi-objcopy
LIBNDS  := $(DEVKITPRO)/libnds
CALICO  := $(DEVKITPRO)/calico

SPECS9  := $(CALICO)/share/ds9.specs
SPECS7  := $(LIBNDS)/specs/ds7.specs

ARCH9   := -march=armv5te -mtune=arm946e-s
CFLAGS  := -g -Wall -O2 -fomit-frame-pointer -ffast-math $(ARCH9) \
           -specs=$(SPECS9) -D__NDS__ -D__ARM9__ -DARM9 \
           -Iinclude -I$(LIBNDS)/include -I$(CALICO)/include -I$(BUILD)
LDFLAGS := -specs=$(SPECS9) -g $(ARCH9) -Wl,-Map,$(BUILD)/$(TARGET).map
LIBS    := -L$(LIBNDS)/lib -L$(CALICO)/lib -Wl,--start-group -lnds9 -lcalico_ds9 -lmm9 -Wl,--end-group

CFILES   := $(wildcard $(SOURCES)/*.c)
PNGFILES := $(wildcard gfx/*.png)
GFXHDRS  := $(patsubst gfx/%.png,$(BUILD)/%.h,$(PNGFILES))
OBJS     := $(patsubst $(SOURCES)/%.c,$(BUILD)/%.o,$(CFILES)) \
            $(patsubst gfx/%.png,$(BUILD)/%.o,$(PNGFILES))

.SECONDARY:
.PHONY: all clean variantes

all: $(TARGET).nds

$(BUILD)/custom_arm7.bin: source_arm7.c | $(BUILD)
	$(CC) -O2 -march=armv4t -mtune=arm7tdmi -specs=ds7.specs $< -L$(LIBNDS)/lib -lnds7 -o $(BUILD)/custom_arm7.elf
	$(OBJCOPY) -O binary $(BUILD)/custom_arm7.elf $@

$(TARGET).nds: $(BUILD)/$(TARGET).elf $(BUILD)/custom_arm7.bin $(GAME_ICON)
	LC_ALL=C.UTF-8 ndstool -c $@ -9 $< -7 $(BUILD)/custom_arm7.bin -b $(GAME_ICON) "$(GAME_TITLE);MKDDDS;$(TARGET)" -g $(GAME_CODE) $(MAKER_CODE) "MARIOKART"

$(BUILD)/$(TARGET).elf: $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) $(LIBS) -o $@

$(BUILD)/%.o: $(SOURCES)/%.c $(GFXHDRS) | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: $(BUILD)/%.s
	$(CC) $(ARCH9) -x assembler-with-cpp -c $< -o $@

$(BUILD)/%.s $(BUILD)/%.h: gfx/%.png | $(BUILD)
	grit $< -gb -gB8 -gT FF00FF -m! -fts -o$(BUILD)/$*

$(BUILD):
	mkdir -p $@

variantes: $(TARGET).nds
	@mkdir -p $(BUILD)/variantes
	cp $(TARGET).nds $(BUILD)/variantes/$(TARGET)_funcional.nds

clean:
	rm -rf $(BUILD) $(TARGET).nds
