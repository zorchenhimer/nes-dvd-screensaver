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

; These are the center of the metasprite.  Don't have to worry about
; wrap-around then. The bounding box will have a buffer of a few sprites.
SpriteX:    .res 1
SpriteY:    .res 1

; TODO: make these "decimal"? eg, 21 == 2.1
X_SPEED = 1
Y_SPEED = 1

TmpId:  .res 1
TmpX:   .res 1

controller:     .res 1
controllerTmp:  .res 1
controllerOld:  .res 1
btnPressedMask: .res 1

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

; Walls
W_TOP       = 26
W_BOTTOM    = 210
W_LEFT      = 32
W_RIGHT     = 224

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

; Sprite setup
    ; Move sprite zero out of the way
    lda #$FF
    sta SpriteZero

    ;lda #$18
    ;sta Sprites+1
    lda #$10
    sta TmpId
    lda #$00
    sta TmpX

    lda #128
    sta SpriteX
    lda #110
    sta SpriteY

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
    bit Directions
    bmi @down
    ; up
    dec SpriteY
    jmp @updateHoriz

@down:
    inc SpriteY

@updateHoriz:
    bit Directions
    bvs @right
    ; left
    dec SpriteX
    jmp @updateDone

@right:
    inc SpriteX

@updateDone:
    jsr UpdateSprites

    jmp (CheckVert)
FlipVertDone:

    jmp (CheckHoriz)
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

    dec sleeping

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
    lda #W_LEFT
    cmp SpriteX
    bcc :+

    lda #<CheckRight
    sta CheckHoriz
    lda #>CheckRight
    sta CheckHoriz+1
    jmp FlipHoriz

:   jmp FlipHorizDone

CheckRight:
    lda SpriteX
    cmp #W_RIGHT
    bcc :+

    lda #<CheckLeft
    sta CheckHoriz
    lda #>CheckLeft
    sta CheckHoriz+1
    jmp FlipHoriz

:   jmp FlipHorizDone

CheckTop:
    lda #W_TOP
    cmp SpriteY
    bcc :+

    lda #<CheckBottom
    sta CheckVert
    lda #>CheckBottom
    sta CheckVert+1
    jmp FlipVert

:   jmp FlipVertDone

CheckBottom:
    lda SpriteY
    cmp #W_BOTTOM
    bcc :+

    lda #<CheckTop
    sta CheckVert
    lda #>CheckTop
    sta CheckVert+1
    jmp FlipVert

:   jmp FlipVertDone

FlipVert:
    jsr CyclePalette

    bit Directions
    bpl @down
    lda Directions
    and #%01000000
    sta Directions
    jmp FlipVertDone

@down:
    lda Directions
    eor #%10000000
    sta Directions
    jmp FlipVertDone

FlipHoriz:
    jsr CyclePalette

    bit Directions
    bvc @left
    lda Directions
    and #%10000000
    sta Directions
    jmp FlipHorizDone

@left:
    lda Directions
    eor #%01000000
    sta Directions
    jmp FlipHorizDone

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
    sta PaletteRAM+11, y
    inx
    dey
    bne @loop

    ; increment index for next call
    inc PaletteIndex
    lda PaletteIndex
    cmp #DVDPalsLength
    bne @nowrap
    ; wrap if we're past the end of the palette list
    lda #0
    sta PaletteIndex

@nowrap:
    rts

; Load SpriteX and SpriteY and set the correct values for all of the sprites
UpdateSprites:
    lda SpriteY
    sec
    sbc #20
    clc

; Set Y
    ldx #0
@loopRow0Y:
    sta Sprites, x
    inx
    inx
    inx
    inx
    cpx #32
    bne @loopRow0Y

    clc
    adc #$10

    ldx #0
@loopRow1Y:
    sta Sprites+32, x
    inx
    inx
    inx
    inx
    cpx #32
    bne @loopRow1Y

    clc
    adc #$10

    ldx #0
@loopRow2Y:
    sta Sprites+64, x
    inx
    inx
    inx
    inx
    cpx #32
    bne @loopRow2Y

; Set X
    lda SpriteX
    sec
    sbc #32
    sta TmpX
    clc

    ldx #3
@loopRow0X:
    sta Sprites, x
    adc #8
    inx
    inx
    inx
    inx
    cpx #35
    bne @loopRow0X

    clc
    lda TmpX
    ldx #3
@loopRow1X:
    sta Sprites+32, x
    adc #8
    inx
    inx
    inx
    inx
    cpx #35
    bne @loopRow1X

    clc
    lda TmpX
    ldx #3
@loopRow2X:
    sta Sprites+64, x
    adc #8
    inx
    inx
    inx
    inx
    cpx #35
    bne @loopRow2X

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
    .byte $0F, $14, $24, $34
DVDPalsEnd:

DVDPalsLength = (DVDPalsEnd - DVDPals) / 4
