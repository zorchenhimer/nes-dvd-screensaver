export PATH := $(PATH):../tools/cc65/bin:../tools/ld65-labels

# Assembler and linker paths
CA = ca65
LD = ld65

# Mapper configuration for linker
NESCFG = nes_000.cfg

# any CHR files included
CHR = dvd.chr

# Name of the destination rom, minus the extension
NAME = dvd

# List of all the sources files
SOURCES = main.asm nes2header.inc

# misc
RM = rm

.PHONY: clean default

default: all
all: bin/$(NAME).nes

clean:
	-$(RM) bin/*.*

bin/:
	mkdir bin

bin/$(NAME).o: bin/ $(SOURCES) $(CHR)
	$(CA) -g \
		-t nes \
		-o bin/$(NAME).o\
		-l bin/$(NAME).lst \
		main.asm

bin/$(NAME).nes: bin/$(NAME).o $(NESCFG)
	$(LD) -o bin/$(NAME).nes \
		-C $(NESCFG) \
		-m bin/$(NAME).nes.map -vm \
		-Ln bin/$(NAME).labels \
		--dbgfile bin/$(NAME).nes.dbg \
		bin/$(NAME).o
