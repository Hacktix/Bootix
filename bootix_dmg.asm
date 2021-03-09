INCLUDE "inc/hardware.inc"

SCX_MAX_OFF     EQU $10
ANIM_TIMEOUT    EQU 28
SOUND_TIMEOUT_1 EQU 39
SOUND_TIMEOUT_2 EQU 394

SECTION "Bootrom", ROM0[0]
    ; Initialize SP
    ld sp, $FFFE

    ; Clear VRAM
    ld hl, $9FFF
ClearVRAM:
    xor a
    ld [hld], a
    bit 7, h
    jr nz, ClearVRAM

    ; Initialize Audio
    ld c, $11
    ld hl, rAUDENA
    ld a, AUDENA_ON
    ld [hld], a
    ldh [$ff00+c], a
    inc c
    ld a, $F3
    ld [hld], a
    ldh [$ff00+c], a
    inc c
    ld a, $77
    ld [hld], a
    ldh [$ff00+c], a

    ; Decode logo and load into VRAM
    ld de, $0104
    ld hl, $8010
DecodeLoop:
    ; Decode first 4 bits of byte
    ld a, [de]
    call LoadLogoNibble

    ; Decode second 4 bits of byte
    ld a, [de]
    swap a
    call LoadLogoNibble
    
    ; Loop if necessary
    inc de
    ld a, e
    cp $34
    jr nz, DecodeLoop

    ; Load Trademark Symbol into VRAM
    ld de, TrademarkLogo
    ld b, 8
TrademarkLoadLoop:
    ld a, [de]
    inc de
    ld [hli], a
    inc hl
    dec b
    jr nz, TrademarkLoadLoop

    ; Initialize tilemap (Row 1)
    ld hl, $9904
    ld bc, $010C
    call LogoMapInit
    ; Trademark Symbol
    ld a, $19
    ld [hl], a

    ; Initialize Tilemap (Row 2)
    ld hl, $9924
    ld c, $0C
    call LogoMapInit

    ; Initialize LCDC
    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON
    ldh [rLCDC], a

    ; Play intro animation
    ld b, SCX_MAX_OFF
    ld de, FadeValues
IntroAnimLoop:
    ; Set SCX to OFFSET
    ld a, b
    ldh [rSCX], a
    dec b

    ; Update BGP Fade
    ld a, e
    cp LOW(FadeValues+4)
    jr z, .skipFade
    ld a, [de]
    ldh [rBGP], a
    inc de
.skipFade

    ; Wait...
    ld c, ANIM_TIMEOUT
    call DoTimeout
    
    ; Set SCX to -OFFSET
    xor a
    sub b
    ldh [rSCX], a
    dec b

    ; Wait... (Return to loop if OFFSET != 0)
    ld c, ANIM_TIMEOUT
    call DoTimeout
    xor a
    or b
    jr nz, IntroAnimLoop
    ldh [rSCX], a

    ; Play sound 1
    ld a, $83
    call PlaySound
    
    ; Wait...
    ld c, SOUND_TIMEOUT_1
    call DoTimeout

    ; Play sound 2
    ld a, $C1
    call PlaySound
    
    ; Wait...
    ld de, SOUND_TIMEOUT_2
LongWaitLoop:
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, LongWaitLoop
    dec de
    ld a, d
    or e
    jr nz, LongWaitLoop

    ; Finalize Bootrom
    jr EndBootrom

PlaySound:
    ld c, $13
    ld [$ff00+c], a
    inc c
    ld a, $87
    ld [$ff00+c], a
    ret

    ; Routine for waiting a certain amount of time
DoTimeout:
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, DoTimeout
    dec c
    jr nz, DoTimeout
    ret

    ; Routine for loading logo tile numbers into VRAM
LogoMapInit:
    ld a, b
    ld [hli], a
    inc b
    dec c
    jr nz, LogoMapInit
    ret

    ; Routine for converting logo byte to VRAM data
LoadLogoNibble:
    ld b, a
    ld c, $04
    xor a
.bitShiftLoop
    push bc
    rl b
    rla 
    pop bc
    rl b
    rla 
    dec c
    jr nz, .bitShiftLoop
    ld [hli], a
    inc hl
    ld [hli], a
    inc hl
    ret

    ; Trademark Logo
TrademarkLogo:
    db $3C, $42, $B9, $A5, $B9, $A5, $42, $3C

    ; BGP Fade Values
FadeValues:
    db %00000000, %01010100, %10101000, %11111100

    ; Mandatory Copyright Notice
    db "BOOTIX.DMG v1.2", 0

EndBootrom:
    ; Initialize registers
    ld a, $FF
    add $01
    dec bc
    ld e, $D8
    ld hl, $014D

; Pad remaining space with NOP
ds $100-@-4, 0

    ; Disable Bootrom
    ld a, $01
    ldh [$FF50], a