ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# TARGET, dirs
#---------------------------------------------------------------------------------
TARGET      := mkddds
BUILD       := build
SOURCES     := source
INCLUDES    := include build
GFXDIR      := gfx

#---------------------------------------------------------------------------------
# Game / ROM header info
#---------------------------------------------------------------------------------
GAME_TITLE  := MARIOKART
GAME_CODE   := MKDD
MAKER_CODE  := 00

#---------------------------------------------------------------------------------
# flags
#---------------------------------------------------------------------------------
ARCH    := -mthumb -mthumb-interwork

CFLAGS  := -g -Wall -O2\
           -march=armv5te -mtune=arm946e-s -fomit-frame-pointer\
           -ffast-math \
           $(ARCH)

CFLAGS  += $(INCLUDE) -DARM9
CXXFLAGS    := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS := -g $(ARCH)
LDFLAGS  = -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS    := -lnds9 -lmm9
LIBDIRS := $(LIBNDS)

#---------------------------------------------------------------------------------
# no need to edit below this line
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT  :=  $(CURDIR)/$(TARGET)

export VPATH   := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
                   $(foreach dir,$(GFXDIR),$(CURDIR)/$(dir))

export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES     := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

# PNGs em gfx/ viram .c/.h via grit (regra abaixo); listamos aqui pra
# garantir que entrem na build como fonte gerada.
PNGFILES   := $(foreach dir,$(GFXDIR),$(notdir $(wildcard $(dir)/*.png)))
GFXCFILES  := $(PNGFILES:.png=.c)

export OFILES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o) \
                  $(GFXCFILES:.c=.o)

export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
                   -I$(CURDIR)/$(BUILD) \
                   -I$(LIBNDS)/include

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

$(OUTPUT).nds: $(OUTPUT).arm9
	ndstool -c $(OUTPUT).nds -9 $(OUTPUT).arm9 \
		-b $(wildcard $(CURDIR)/icon.bmp) "$(GAME_TITLE);MKDDDS;$(TARGET)" \
		-g $(GAME_CODE) $(MAKER_CODE)

$(OUTPUT).arm9: $(OUTPUT).elf
	$(OBJCOPY) -O binary $< $@

$(OUTPUT).elf: $(OFILES)

%.c %.h: %.png %.grit
	grit $< -ff$(subst .c,.grit,$(subst %,%,$*.grit)) -o$*

%.o: %.c
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(CFLAGS) -c $< -o $@

%.o: %.s
	@echo $(notdir $<)
	$(CC) -MMD -MP -MF $(DEPSDIR)/$*.d $(ASFLAGS) -c $< -o $@

-include $(DEPENDS)

endif
