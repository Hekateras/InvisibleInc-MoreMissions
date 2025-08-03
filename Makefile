#
# To get started, copy makeconfig.example.mk as makeconfig.mk and fill in the appropriate paths.
#
# build: Build all the zips and kwads
# install: Copy mod files into a local installation of Invisible Inc
# rar: Update the pre-built rar
#

include makeconfig.mk

.PHONY: build install clean distclean cleanOut
.SECONDEXPANSION:

ensuredir = @mkdir -p $(@D)

files := modinfo.txt scripts.zip gui.kwad moremissions_anims.kwad sound.kwad oil_fx.kwad
outfiles := $(addprefix out/, $(files))
installfiles := $(addprefix $(INSTALL_PATH)/, $(files))
ifneq ($(INSTALL_PATH2),)
	installfiles += $(addprefix $(INSTALL_PATH2)/, $(files))
endif

build: $(outfiles)
install: build $(installfiles)

$(installfiles): %: out/$$(@F)
	$(ensuredir)
	cp $< $@

clean: cleanOut
cleanOut:
	-rm out/*

distclean:
	-rm -f $(INSTALL_PATH)/*.kwad $(INSTALL_PATH)/*.zip
ifneq ($(INSTALL_PATH2),)
	-rm -f $(INSTALL_PATH2)/*.kwad $(INSTALL_PATH2)/*.zip
endif

rar: build
	mkdir -p out/MoreMissions
	cp modinfo.txt out/MoreMissions/
	cp out/scripts.zip out/MoreMissions/
	cp out/gui.kwad out/MoreMissions/
	cp out/moremissions_anims.kwad out/MoreMissions/
	cd out && rar a ../MoreMissions\ V.0.3.rar \
		MoreMissions/modinfo.txt \
		MoreMissions/scripts.zip \
		MoreMissions/gui.kwad \
		MoreMissions/moremissions_anims.kwad

#
# kwads and contained files
#

anims := $(patsubst %.anim.d,%.anim,$(shell find anims -type d -name "*.anim.d"))
# Omit "menu pages" folder. Make doesn't support spaces in filenames
guis := $(shell find gui -type f -name "*.lua") \
        $(shell find gui -not -path "gui/images/gui/menu pages/*" -type f -name "*.png" )
sounds := $(shell find sound -type f -name "*.fdp") \
          $(shell find sound -type f -name "*.fev") \
					$(shell find sound -type f -name "*.fsb")

$(anims): %.anim: $(wildcard %.anim.d/*.xml $.anim.d/*.png)
	cd $*.anim.d && zip ../$(notdir $@) *.xml *.png

out/gui.kwad out/moremissions_anims.kwad out/sound.kwad: $(anims) $(guis) $(sounds)
	mkdir -p out
	$(KWAD_BUILDER) -i build.lua -o out

out/oil_fx.kwad: oil_fx.kwad
	$(ensuredir)
	cp oil_fx.kwad out/oil_fx.kwad

#
# scripts
#

out/scripts.zip: $(shell find scripts -type f -name "*.lua")
	mkdir -p out
	cd scripts && zip -r ../$@ . -i '*.lua'

out/modinfo.txt: modinfo.txt
	mkdir -p out
	cp modinfo.txt out/modinfo.txt
