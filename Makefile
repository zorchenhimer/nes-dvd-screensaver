
# Assembler and linker paths
CA = c:/cc65/bin/ca65.exe
LD = c:/cc65/bin/ld65.exe

# Tool to generate credits data
#CR = go run ../credits/generate-credits.go
#CL = go run ../tools/ld65-labels/main.go
CL = ../../tools/ld65-labels/ld65-labels.exe

# Mapper configuration for linker
NESCFG = nes_000.cfg

# Name of the main source file, minus the extension

# any CHR files included
CHR = dvd.chr

NAME = dvd

# List of all the sources files
SOURCES = main.asm nes2header.inc

# misc
RM = rm

.PHONY: clean default cleanSym symbols

default: all
all: bin/$(NAME).nes bin/$(NAME).mlb
symbols: cleanSym bin/$(NAME).mlb

clean:
	-$(RM) bin/*.*
cleanSym:
	-$(RM) bin/*.mlb

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
		--dbgfile bin/$(NAME).nes.db \
		bin/$(NAME).o

bin/$(NAME).mlb: bin/$(NAME).nes.db
	$(CL) bin/$(NAME).nes.db

