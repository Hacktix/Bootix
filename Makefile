RGBASM = rgbasm
RGBLINK = rgblink

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -x

bootix_dmg.bin: bootix_dmg.o
	$(RGBLINK) $(LDFLAGS) -o $@ $^

bootix_dmg.o: bootix_dmg.asm
	$(RGBASM) $(ASFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM_F) bootix_dmg.o bootix_dmg.bin