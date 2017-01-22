#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
#
# NO_SMDH: if set to anything, no SMDH file is generated.
# APP_TITLE is the name of the app stored in the SMDH file (Optional)
# APP_DESCRIPTION is the description of the app stored in the SMDH file (Optional)
# APP_AUTHOR is the author of the app stored in the SMDH file (Optional)
# ICON is the filename of the icon (.png), relative to the project folder.
#   If not set, it attempts to use one of the following (in this order):
#     - <Project name>.png
#     - icon.png
#     - <libctru folder>/default_icon.png
#---------------------------------------------------------------------------------

TARGET		:=	$(notdir $(CURDIR))
BUILD		:=	build
SOURCES		:=	source source/libs/lua source/modules source/objects source/libs/luaobj source/libs/tremor
DATA		:=	data
INCLUDES	:=	source source/libs/lua source/modules source/objects source/libs/luaobj source/libs/tremor source/libs/sf2dlib/include source/libs/sftdlib/include source/libs/sfillib/include

APP_TITLE	:=	JETSKI 3DS
APP_AUTHOR	:=	'ElementalCode' Milton Candelero
APP_DESCRIPTION	:=	A small game made for GGJ 2017.

ICON := meta/icon.png
BANNER := meta/banner.png
JINGLE := meta/jingle.wav
LOGO := meta/logo.bcma.lz

# CIA Options

APP_PRODUCT_CODE := CTR-P-LP
APP_UNIQUE_ID := 0x6D119
APP_SYSTEM_MODE := 64MB
APP_SYSTEM_MODE_EXT := Legacy
APP_ROMFS_DIR := $(TOPDIR)/game

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH	:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard

CFLAGS	:=	-g -Wall -O2 -mword-relocations \
			-fomit-frame-pointer -ffast-math \
			$(ARCH)

CFLAGS	+=	$(INCLUDE) -DARM11 -D_3DS

CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS	:=	-g $(ARCH)
LDFLAGS	=	-specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS	:= -lsfil -lpng -ljpeg -lz -lsf2d -lcitro3d -lctru -lm -lsftd -lfreetype -logg

UNAME := $(shell uname)

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS	:= $(CTRULIB) $(PORTLIBS) $(CURDIR)/source/libs/libsf2d $(CURDIR)/source/libs/libsfil $(CURDIR)/source/libs/libsftd $(CURDIR)/source/libs/tremor


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

CFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES	:=	$(addsuffix .o,$(BINFILES)) \
			$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE	:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
			$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
			-I$(CURDIR)/$(BUILD)

export LIBPATHS	:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.png)
	ifneq (,$(findstring $(TARGET).png,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).png
	else
		ifneq (,$(findstring icon.png,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.png
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_SMDH)),)
	export _3DSXFLAGS += --smdh=$(CURDIR)/$(TARGET).smdh
endif

.PHONY: $(BUILD) clean all

#---------------------------------------------------------------------------------

all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

build-sf2dlib:
	@make -C source/libs/libsf2d build

build-sftdlib:
	@make -C source/libs/libsftd build

build-sfillib:
	@make -C source/libs/libsfil build

build-all:
	@echo Building sf2dlib...
	@make build-sf2dlib
	@echo Building sftdlib...
	@make build-sftdlib
	@echo Building sfillib...
	@make build-sfillib
	@echo Building LovePotion...
	@make build

#---------------------------------------------------------------------------------
clean:
	@rm -fr $(BUILD) $(TARGET).3dsx $(OUTPUT).smdh $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia icon.bin banner.bin

clean-sf2dlib:
	@make -C source/libs/libsf2d clean

clean-sftdlib:
	@make -C source/libs/libsftd clean

clean-sfillib:
	@make -C source/libs/libsfil clean

clean-all:
	@echo Cleaning sf2dlib...
	@make clean-sf2dlib
	@echo Cleaning sftdlib...
	@make clean-sftdlib
	@echo Cleaning sfillib...
	@make clean-sfillib
	@echo Cleaning LovePotion...
	@make clean

#---------------------------------------------------------------------------------
install:
	@$(TOPDIR)/tools/ftp-copy

#---------------------------------------------------------------------------------
banner:
	@$(TOPDIR)/tools/bannertool

#---------------------------------------------------------------------------------
else

DEPENDS	:=	$(OFILES:.o=.d)

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
ifeq ($(strip $(NO_SMDH)),)
$(OUTPUT).3dsx	:	$(OUTPUT).smdh icon.bin banner.bin $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia
else
$(OUTPUT).3dsx	:	icon.bin banner.bin $(OUTPUT).elf $(OUTPUT)-stripped.elf $(OUTPUT).bin $(OUTPUT).3ds $(OUTPUT).cia
endif

#---------------------------------------------------------------------------------
icon.bin	:	
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/bannertool makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/bannertool makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
else
	@$(TOPDIR)/tools/windows/bannertool.exe makesmdh -s $(APP_TITLE) -l $(APP_TITLE) -p $(APP_AUTHOR) -i $(TOPDIR)/$(ICON) -o $(TOPDIR)/icon.bin -f visible allow3d
endif

#---------------------------------------------------------------------------------
banner.bin	:	
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/bannertool makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/bannertool makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
else
	@$(TOPDIR)/tools/windows/bannertool.exe makebanner -i $(TOPDIR)/$(BANNER) -a $(TOPDIR)/$(JINGLE) -o $(TOPDIR)/banner.bin
endif

#---------------------------------------------------------------------------------
$(OUTPUT).elf	:	$(OFILES)
#---------------------------------------------------------------------------------

#---------------------------------------------------------------------------------
$(OUTPUT)-stripped.elf : $(OUTPUT).elf
#---------------------------------------------------------------------------------
	@cp -f $(OUTPUT).elf $(OUTPUT)-stripped.elf
	@arm-none-eabi-strip $(OUTPUT)-stripped.elf

#---------------------------------------------------------------------------------
$(OUTPUT).bin	:	
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/3dstool -cvtf romfs $(OUTPUT).bin --romfs-dir $(TOPDIR)/game
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/3dstool -cvtf romfs $(OUTPUT).bin --romfs-dir $(TOPDIR)/game
else
	@$(TOPDIR)/tools/windows/3dstool.exe -cvtf romfs $(OUTPUT).bin --romfs-dir $(TOPDIR)/game
endif
	@echo RomFS packaged ...

#---------------------------------------------------------------------------------
$(OUTPUT).3ds	:	$(OUTPUT)-stripped.elf $(OUTPUT).bin icon.bin banner.bin
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/makerom -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/makerom -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin -exefslogo -target t -romfs "$(OUTPUT).bin"
else
	@$(TOPDIR)/tools/windows/makerom.exe -f cci -o $(OUTPUT).3ds -DAPP_ENCRYPTED=true -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
endif
	@echo 3DS packaged ...

#---------------------------------------------------------------------------------
$(OUTPUT).cia	:	$(OUTPUT)-stripped.elf $(OUTPUT).bin icon.bin banner.bin
#---------------------------------------------------------------------------------
ifeq ($(UNAME), Linux)
	@$(TOPDIR)/tools/linux/makerom -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
else ifeq ($(UNAME), Darwin)
	@$(TOPDIR)/tools/osx/makerom -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -banner $(TOPDIR)/banner.bin -exefslogo -target t -romfs "$(OUTPUT).bin"
else
	@$(TOPDIR)/tools/windows/makerom.exe -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false -DAPP_UNIQUE_ID=$(APP_UNIQUE_ID) -elf $(OUTPUT)-stripped.elf -rsf "$(TOPDIR)/meta/workarounds/workaround.rsf" -icon $(TOPDIR)/icon.bin -logo "$(TOPDIR)/logo.bcma.lz" -banner $(TOPDIR)/banner.bin  -exefslogo -target t -romfs "$(OUTPUT).bin"
endif
	@echo CIA packaged ...


#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.jpeg.o :	%.jpeg
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.png.o	:	%.png
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.ttf.o	:	%.ttf
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
%.lua.o	:	%.lua
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

# WARNING: This is not the right way to do this! TODO: Do it right!
#---------------------------------------------------------------------------------
%.vsh.o	:	%.vsh
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@picasso -o $(notdir $<).shbin $<
	@bin2s $(notdir $<).shbin | $(PREFIX)as -o $@
	@echo "extern const u8" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(notdir $<).shbin | tr . _)`.h
	@echo "extern const u8" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(notdir $<).shbin | tr . _)`.h
	@echo "extern const u32" `(echo $(notdir $<).shbin | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(notdir $<).shbin | tr . _)`.h

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------
