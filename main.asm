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
sleeping:       .res 1
PaletteIndex:   .res 1

; bit 7 is vert:    0 up; 1 down
; bit 6 is horiz:   0 left; 1 right
Directions:     .res 1

; Pointers to check routines
CheckVert:      .res 2
CheckHoriz:     .res 2

; Make these the center of the metasprite or something.  Don't have to worry
; about wrap-around then. The bounding box will have a buffer of a few sprites.
SpriteX:    .res 1
SpriteY:    .res 1

; TODO: make these "decimal"? eg, 21 == 2.1
X_SPEED = 1
Y_SPEED = 1

TmpId:  .res 1
TmpX:   .res 1

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

    jsr LoadPalettes

    bit $2002
    lda #$3F
    sta $2006
    lda #$00
    sta $2006

    ldx #31
@palloop:
    lda PaletteRAM, x
    sta $2007
    dex
    bpl @palloop

; TODO: Setup sprites
; Load first row
;    ldx #0
;    lda #10
;SpLoopRow1:
;    

SpriteSetup:
    ;lda #$18
    ;sta Sprites+1
    lda #$10
    sta TmpId
    lda #$00
    sta TmpX

    ; Set initial vector to up left.
    lda #0
    sta Directions

    ; setup check routines
    lda #<CheckLeft
    sta CheckHoriz
    lda #>CheckLeft
    sta CheckHoriz+1

    lda #<CheckTop
    sta CheckVert
    lda #>CheckTop
    sta CheckVert+1

    clc
    ldy #$10    ; Y pos
    ldx #0      ; sprite byte index
@loop0:
    ; Y
    tya
    sta Sprites, x

    ; Tile
    inx
    lda TmpId
    sta Sprites, x
    adc #2
    sta TmpId

    inx     ; attr

    ; X
    inx
    lda TmpX
    sta Sprites, x
    adc #8
    sta TmpX

    ; next
    inx
    cpx #32
    bne @loop0

    clc
    lda #$00
    sta TmpX
    lda #$30
    sta TmpId
    ldy #$20
@loop1:
    ; Y
    tya
    sta Sprites, x

    ; Tile
    inx
    lda TmpId
    sta Sprites, x
    adc #2
    sta TmpId

    inx     ; attr

    ; X
    inx
    lda TmpX
    sta Sprites, x
    adc #8
    sta TmpX

    ; next
    inx
    cpx #64
    bne @loop1

    clc
    lda #$00
    sta TmpX
    lda #$50
    sta TmpId
    ldy #$30
@loop2:
    ; Y
    tya
    sta Sprites, x

    ; Tile
    inx
    lda TmpId
    sta Sprites, x
    adc #2
    sta TmpId

    inx     ; attr

    ; X
    inx
    lda TmpX
    sta Sprites, x
    adc #8
    sta TmpX

    ; next
    inx
    cpx #96
    bne @loop2

    ; Do this after all other init stuff
    lda #%00011110
    sta $2001

    lda #%10100000
    sta $2000

DoFrame:
    ; TODO: movement
    jmp (CheckVert)
CheckVertDone:
    beq FlipVertDone
    jsr FlipVert
FlipVertDone:

    jmp (CheckHoriz)
CheckHorizDone:
    beq FlipHorizDone
    jsr FlipHoriz
FlipHorizDone:

WaitFrame:
    lda #1
    sta sleeping

:   lda sleeping
    bne :-

    jmp DoFrame

NMI:
    ; only A and X are clobbered
    pha
    txa
    pha

    ; Sprites
    bit $2002
    lda #$00
    sta $2003
    lda #$02
    sta $4014

    ; Palettes.  TODO: only load up the palette we need
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

    ; Scroll stuff
    bit $2002
    lda #$00
    sta $2005
    sta $2005

    lda #%10100000
    sta $2000

    ; Restore A and X
    pla
    tax
    pla
    rti

; loads full palette
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

; TODO: These, lol. Setup a bounding box during init, and check SpriteX and
; SpriteY against it.
CheckLeft:
    lda #0
    jmp CheckHorizDone

CheckRight:
    lda #0
    jmp CheckHorizDone

CheckTop:
    lda #0
    jmp CheckVertDone

CheckBottom:
    lda #0
    jmp CheckVertDone

RtsTable:
    .word FlipVertDone-1
    .word FlipHorizDone-1

FlipVert:
    ; Setup RTS trick for CyclePalette
    ldx #0
    lda RtsTable+1, x
    pha
    lda RtsTable, x
    pha

    bit Directions
    bpl @down
    lda Directions
    and #%01000000
    sta Directions
    jmp CyclePalette

@down:
    lda Directions
    eor #%1000000
    sta Directions
    jmp CyclePalette

FlipHoriz:
    ; Setup RTS trick for CyclePalette
    ldx #2
    lda RtsTable+1, x
    pha
    lda RtsTable, x
    pha

    bit Directions
    bvc @left
    lda Directions
    and #%10000000
    sta Directions
    jmp CyclePalette

@left:
    lda Directions
    eor #%0100000
    sta Directions
    ;jmp CyclePalette

; loads the next sprite palette
CyclePalette:
    lda PaletteIndex
    ; multiply index by 4
    asl a
    asl a
    tax
    ldy #4  ; four bytes for the palette
@loop:
    lda DVDPals, x
    ; Load palette backwards into RAM.  The sprites will use the first palette
    sta PaletteRAM+12, y
    inx
    dey
    bne @loop

    ; increment index for next call
    inc PaletteIndex
    lda PaletteIndex
    cmp DVDPalsLength
    bcc @nowrap
    ; wrap if we're past the end of the palette list
    lda #0
    sta DVDPalsLength

@nowrap:
    rts

PaletteData:
    .byte $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F
    .byte $0F,$00,$10,$30, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F, $0F,$0F,$0F,$0F

DVDPals:
    .byte $0F, $00, $10, $20
    .byte $0F, $06, $16, $26
    .byte $0F, $13, $23, $33
    .byte $0F, $0a, $2a, $3a
    .byte $0F, $11, $21, $31
    .byte $0F, $15, $25, $35
    .byte $0f, $14, $24, $34
DVDPalsEnd:

DVDPalsLength = (DVDPalsEnd - DVDPals) / 4
