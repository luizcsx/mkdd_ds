ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitPro")
endif

include $(DEVKITARM)/ds_rules

TARGET      := mkddds
BUILD       := build
SOURCES     := source
INCLUDES    := include build
GFXDIR      := gfx

GAME_TITLE  := MARIOKART
GAME_CODE   := MKDD
MAKER_CODE  := 00

ARCH    := -mthumb -mthumb-interwork

CFLAGS  := -g -Wall -O2\
           -march=armv5te -mtune=arm946e-s -fomit-frame-pointer\
           -ffast-math \
           $(ARCH)

CFLAGS  += $(INCLUDE) -D__NDS__ -DARM9
CXXFLAGS    := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS := -g $(ARCH)
LDFLAGS  = -specs=$(DEVKITPRO)/calico/share/ds9.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS    := -lnds9 -lcalico_ds9 -lmm9
LIBDIRS := $(LIBNDS) $(DEVKITPRO)/calico

ARM7ELF := $(firstword $(shell find $(DEVKITPRO) -type f -name 'ds7_sphynx.elf' 2>/dev/null))
ifeq ($(strip $(ARM7ELF)),)
ARM7ELF := $(firstword $(shell find $(DEVKITPRO) -type f \( -name 'ds7*.elf' -o -name 'default.elf' -o -name '*arm7*.elf' \) 2>/dev/null))
endif

ifeq ($(strip $(ARM7ELF)),)
$(error "Nenhum arquivo ARM7 (.elf) válido foi encontrado em $(DEVKITPRO)")
endif

$(info ARM7 selecionado automaticamente: $(ARM7ELF))

ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT   :=  $(CURDIR)/$(TARGET)
export PROJROOT := $(CURDIR)

export LD      := $(CC)

export VPATH   := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
                   $(foreach dir,$(GFXDIR),$(CURDIR)/$(dir))

export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

PNGFILES   := $(foreach dir,$(GFXDIR),$(notdir $(wildcard $(dir)/*.png)))
GFXCFILES  := $(PNGFILES:.png=.c)
GFXHFILES  := $(PNGFILES:.png=.h)

export OFILES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o) \
                  $(GFXCFILES:.c=.o)

export SRCCFILES := $(CFILES)
export GFXHFILES  := $(GFXHFILES)

export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
                   -I$(CURDIR)/$(BUILD) \
                   -I$(LIBNDS)/include \
                   -I$(DEVKITPRO)/calico/include

export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).elf $(TARGET).nds $(TARGET).arm9

else

DEPENDS := $(OFILES:.o=.d)

all: $(OUTPUT).nds

$(PROJROOT)/build/dummy_arm7.bin:
	@mkdir -p $(PROJROOT)/build
	@echo "int main(void) { return 0; }" > $(PROJROOT)/build/dummy_arm7.c
	$(CC) -specs=$(DEVKITPRO)/calico/share/ds7.specs $(PROJROOT)/build/dummy_arm7.c -o $(PROJROOT)/build/dummy_arm7.elf
	$(OBJCOPY) -O binary $(PROJROOT)/build/dummy_arm7.elf $@

$(OUTPUT).nds: $(OUTPUT).arm9 $(PROJROOT)/build/dummy_arm7.bin
	ndstool -c $(OUTPUT).nds -9 $(OUTPUT).arm9 \
		-7 $(PROJROOT)/build/dummy_arm7.bin \
		-g $(GAME_CODE) $(MAKER_CODE) "$(GAME_TITLE)" \
		-b $(PROJROOT)/icon.bmp "$(GAME_TITLE);MKDDDS;$(TARGET)"

$(OUTPUT).arm9: $(OUTPUT).elf
	$(OBJCOPY) -O binary $< $@

$(OUTPUT).elf: $(OFILES)

$(SRCCFILES:.c=.o): $(GFXHFILES)

%.c %.h: %.png %.grit
	grit $< -ff $(word 2,$^) -o$*

%.o: %.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(CFLAGS) -c $< -o $@

%.o: %.s
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(ASFLAGS) -c $< -o $@

-include $(DEPENDS)

endif
