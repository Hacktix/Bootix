RGBASM = rgbasm
RGBLINK = rgblink

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -x

bootix_%.bin: bootix_%.o
	$(RGBLINK) $(LDFLAGS) -o $@ $^

bootix_%.o: bootix_%.asm
	$(RGBASM) $(ASFLAGS) -o $@ $<

all: $(addsuffix .bin, $(basename $(wildcard bootix_*.asm)))

.PHONY: clean
clean:
	$(RM_F) bootix_dmg.o bootix_dmg.bin