.include "nes2header.inc"

nes2mapper 0
nes2prg 2 * 16 * 1024
nes2chr 1 *  8 * 1024
nes2mirror 'V'
nes2tv 'N'
nes2end

.segment "TILES"
    .incbin "dvd.chr"

.segment "VECTORS"
    .word NMI
    .word RESET
    .word RESET

.segment "ZEROPAGE"
sleeping:   .res 1

.segment "BSS"
PaletteRAM:         .res 32

.segment "OAM"
SpriteZero:     .res 4
Sprites:        .res 252

.segment "PAGE1"

.segment "PAGE0"
RESET:
    sei
    cld

    ldx #$40
    stx $4017
    ldx #$FF
    txs
    inx

    stx $2000
    stx $2001
    stx $4010

:   bit $2002
    bpl :-

@clr:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne @clr

:   bit $2002
    bpl :-

    lda #$20
    sta $2006
    lda #$00
    sta $2006

    ldx #32
    ldy #30
BgInitLoop:
    sta $2007
    dex
    bne BgInitLoop
    dey
    beq @done
    ldx #32
    jmp BgInitLoop
@done:

    lda #$24
    sta $2006
    lda #$00
    sta $2006

    ldx #32
    ldy #30
BgInitLoop2:
    sta $2007
    dex
    bne BgInitLoop2
    dey
    beq @done
    ldx #32
    jmp BgInitLoop2
@done:

    lda #$23
    sta $2006
    lda #$C0
    sta $2006

    lda #$00
    ldx #64
AttrLoop:
    sta $2007
    dex
    bne AttrLoop

    lda #$27
    sta $2006
    lda #$C0
    sta $2006

    lda #$00
    ldx #64
AttrLoop2:
    sta $2007
    dex
    bne AttrLoop2

    jsr LoadPalettes

; Load first row
    ldx #0
    lda #10
SpLoopRow1:
    

    lda #$18
    sta Sprites+1

    lda #%00011110
    sta $2001

    lda #%10000000
    sta $2000

; TODO: Setup sprites

DoFrame:
    ; TODO: move and calc wall collision

WaitFrame:
    lda #1
    sta sleeping

:   lda sleeping
    bne :-

    jmp DoFrame

NMI:
    pha
    txa
    pha

    bit $2002
    lda #$00
    sta $2003
    lda #$02
    sta $4014

    lda #$3F
    sta $2006
    lda #$00
    sta $2006
    ldx #31
@loop:
    lda PaletteRAM, x
    sta $2007
    dex
    lda PaletteRAM, x
    sta $2007
    dex
    lda PaletteRAM, x
    sta $2007
    dex
    lda PaletteRAM, x
    sta $2007
    dex
    bpl @loop

    bit $2002
    lda #$00
    sta $2005
    sta $2005

    lda #%10000000
    sta $2000

    pla
    tax
    pla
    rti

LoadPalettes:
    ldx #31
    ldy #0
@loop:
    lda PaletteData, y
    sta PaletteRAM, x
    dex
    iny
    cpy #32
    bne @loop
    rts

PaletteData:
    .byte $0F,$30,$30,$30, $0F,$04,$34,$24, $0F,$15,$0F,$0F, $0F,$11,$11,$11
    .byte $0F,$00,$10,$30, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11
    .byte $EA, $EA

DVDPals:
