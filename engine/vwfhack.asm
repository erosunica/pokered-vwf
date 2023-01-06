; VWF HAX
HackPredef:: ; lazyness wins again
    ld a, [wHackPredef]
    dec a
    jp z, VWFAdvice ; 1
    dec a
    jp z, ScrollAdvice ; 2
    dec a
    jp z, EnableVWF ; 3
    dec a
    jp z, DisableVWF; 4
    ret

VWFAdvice:
    ld a, [wHackOldA]
    push af
    push bc
    push de
    ld [wVWFCharacter], a
    push hl
    ld d,h
    ld e,l
	call WriteLetter
	pop hl
	pop de
	pop bc
	pop af
	inc hl
	call PrintLetterDelay
	ret

ScrollAdvice:
    push bc
    push de
    push hl
    ld a, [wVWFCurRow]
    and a
    jr nz, .OtherRow
    call ScrollTextBox
    call Delay3
    call SwapTextBox

    ; XXX ugly:
    ld hl,$8c00
    ld c, $12
    ld b, $2d ; this bank
    ld de, $7000
    call CopyVideoData
    
    call Delay3
    call Delay3

    ld a, $01
    ld [wVWFCurRow], a
    ld a, $00
    ld [wVWFCurTileNum], a
    ;ld a, $00
    ld [wVWFLetterNum], a
    ld [wVWFCurTileCol], a



    
    jr .Done
.OtherRow
    call ScrollSwapTextBox
    call Delay3
    call NormalTextbox

    ; XXX ugly:
    ld hl,$8d20
    ld c, $12
    ld b, $2d ; this bank
    ld de, $7000
    call CopyVideoData

    call Delay3
    call Delay3
    
    ld a, $00
    ld [wVWFCurRow], a
    ld [wVWFLetterNum], a
    ld [wVWFCurTileCol], a
    ld a, $12
    ld [wVWFCurTileNum], a
    ;ld a, $00
    
    
.Done
    pop hl
    ld hl, $c4ba
    pop de
    pop bc
    ret

EnableVWF:
    ld a, 1
    ld [wVWFEnabled], a
    ret
    
DisableVWF:
    xor a
    ld [wVWFEnabled], a
    ld de, .stop
	dec de
    ret

.stop:
	text_end

VWFFont:: INCBIN "gfx/font/vwffont.1bpp"
    
VWFTable:
    db $8, $7, $7, $7, $6, $6, $7, $6, $6, $6, $8, $6, $8, $7, $7, $6
    db $8, $7, $7, $6, $7, $8, $8, $8, $8, $8, $6, $6, $6, $6, $6, $6
    db $7, $6, $6, $6, $6, $6, $6, $5, $2, $3, $5, $2, $6, $5, $6, $5
    db $5, $5, $5, $5, $5, $6, $6, $6, $5, $5, $7, $6, $6, $6, $6, $8
    db $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
    db $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0, $0
    db $0, $0, $0, $7, $8, $8, $8, $7, $4, $3, $8, $8, $8, $8, $8, $8
    db $8, $8, $8, $8, $4, $8, $8, $8, $8, $8, $8, $8, $8, $8, $8, $8
    
NormalTextbox:
    ld a, $c0
    ld hl, $c4a5
    call ClearLine
    call OverwriteLine
    call ClearLine
    call OverwriteLine
    ret

ScrollTextBox:
    ld a, $c0
    ld hl, $c4a5
    call OverwriteLine
    call ClearLine
    call OverwriteLine
    call ClearLine
    ret
    
SwapTextBox:
    ld a, $d2
    ld hl, $c4a5
    call ClearLine
    call OverwriteLine
    ld a, $c0
    call ClearLine
    call OverwriteLine
    ret
    
ScrollSwapTextBox:
    ld a, $d2
    ld hl, $c4a5
    call OverwriteLine
    call ClearLine
    ld a, $c0
    call OverwriteLine
    call ClearLine
    ret
    
OverwriteLine:
    ld b, $12
.loop
    ld [hli], a
    inc a
    dec b
    jp nz, .loop
    ld c, $02
    ld b, $0
    add hl, bc
    ret

ClearLine:
    push af
    ld b, $12
    ld a, $7f
.loop
    ld [hli],a
    dec b
    jp nz, .loop
    ld c, $02
    ld b, $0
    add hl, bc
    pop af
    ret
    
ClearVariableTiles: ; This is not optimized at all.
    push af
    ld a, $00
    ld [wVWFLetterNum], a
    ld [wVWFCurTileNum], a
    ld [wVWFCurTileRow], a
    ld [wVWFCurTileCol], a
    ld [wVWFCurRow], a ; This should probably be reset elsewhere..
    ld hl,$8c00
    ld c, $24
    ld b, $2d ; this bank
    ld de, $7000
    call CopyVideoData
    pop af
    ret
    
CopyColumn:
    ; b = source column
    ; c = dest column
    ; de = source number
    ; hl = dest number
    push hl
    push de
    ld a, $08
    ld [wVWFCurTileRow], a
.Copy
    ld a, [de]
    and a, b
    jr nz, .CopyOne
.CopyZero
    ld a, %11111111
    xor c
    and [hl]
    jp .Next
.CopyOne
    ld a, c
    or [hl]
.Next
    ld [hli],a
    inc de
    ld a, [wVWFCurTileRow]
    dec a
    ld [wVWFCurTileRow], a
    jp nz, .Copy
    pop de
    pop hl
    ret
    
    
WriteLetter:
    ; Store the original tile location.
    ld hl, wVWFTileLoc1
    ld [hl], d
    inc hl
    ld [hl], e
    
    ; Check if VWF is enabled, bail if not.
    ld a, [wVWFEnabled]
    dec a
    jr z, .IsDialogue
    jp .NotDialogue
.IsDialogue
    ; Get the tile offset from the address.  This is kind of a hack.
    ld a, e
    sub a, $b9
    ld e, a
    ld a, d
    sbc a, $c4
    ld d, a
    and a
    jp nz,.NotDialogue
    
    ld a, e
    and a
    jr nz, .NotFirstLocation
    ; If at the beginning of the first line, clear VWF data.
    ld [wVWFLetterNum], a
    call ClearVariableTiles
    call NormalTextbox
    jr .DialogueAfterTileWrite
    
.NotFirstLocation
    cp $28
    jr c, .Dialogue
    sub $16
    cp $12
    jp nz, .NotNewLine
    ld [wVWFLetterNum], a
    ld a, $12
    ld [wVWFLetterNum], a
    ld [wVWFCurTileNum], a
    ld a, $00
    ld [wVWFCurTileRow], a
    ld [wVWFCurTileCol], a
    ;ld a, [W_VWF_PREVIOUSLINE]
    ;dec a
    jr nz, .LastLineWasFirst
    ld [wVWFLetterNum], a
    ;ld [W_VWF_PREVIOUSLINE], a
    jp .DialogueAfterTileWrite
.NotNewLine
    cp $22
    jr nc, .Dialogue
    ld a, $00
    ld [wVWFLetterNum], a
    jr .DialogueAfterTileWrite
.LastLineWasFirst
    ld a, $1
    ;ld [W_VWF_PREVIOUSLINE], a
    jp .DialogueAfterTileWrite
.Dialogue
    ld [wVWFLetterNum], a
.DialogueAfterTileWrite
    ; Store the character tile in BUILDAREA1.
    ld a, [wVWFCharacter]
    sub a, $80
    ld hl, VWFFont
    ld b, 0
    ld c, a
    ld a, $8
    call AddNTimes
    ld bc, $0008
    ld a, BANK(VWFFont)
    ld de, wVWFBuildArea1
    call FarCopyData; copy bc source bytes from a:hl to de
    
    ld a, $1
    ld [wVWFNumTilesUsed], a
    
    ; Get the character length from the width table.
    ; Space is a special case.
    ld a, [wVWFCharacter]
    sub a, $80
    cp a, $ff
    jr nz, .NotSpace
    ld a, $06
    ld [wVWFCharacterWidth], a
    jp .WidthWritten
.NotSpace
    ld c, a
    ld b, $00
    ld hl, VWFTable
    add hl, bc
    ld a, [hl]
    ld [wVWFCharacterWidth], a
.WidthWritten
    ; Set up some things for building the tile.
    ; Special cased to fix column $0, which is invalid (not a power of 2)
    ld de, wVWFBuildArea1
    ld hl, wVWFBuildArea3
    ;ld b, a
    ld b, %10000000
    ld a, [wVWFCurTileCol]
    and a
    jr nz, .ColumnIsFine
    ld a, $80
.ColumnIsFine
    ld c, a ; a
.DoColumn
    ; Copy the column.
    call CopyColumn
    rr c
    jr c, .TileOverflow
    rrc b
    ld a, [wVWFCharacterWidth]
    dec a
    ld [wVWFCharacterWidth], a
    jr nz, .DoColumn 
    jr .Done
.TileOverflow
    ld c, $80
    ld a, $2
    ld [wVWFNumTilesUsed], a
    ld hl, wVWFBuildArea4
    jr .ShiftB
.DoColumnTile2
    call CopyColumn
    rr c
.ShiftB
    rrc b
    ld a, [wVWFCharacterWidth]
    dec a
    ld [wVWFCharacterWidth], a
    jr nz, .DoColumnTile2
.Done
    ld a, c
    ld [wVWFCurTileCol], a
    
    ;ld de, wVWFBuildArea1
    ;ld hl, wVWFBuildArea3

    ; Get the tilemap offset.
    ld hl, $8c00
    ld a, [wVWFCurTileNum]
    ld b, $0
    ld c, a
    ld a, 16
    call AddNTimes
    
    ld b, $0
    
    ; Write the new tile(s)
    ld a, [wVWFNumTilesUsed]
    ld c, a
    ld de, wVWFBuildArea3
    call CopyVideoDataDouble ; copy (c * 8) source bytes from b:de to hl during V-blank

    ld a, [wVWFNumTilesUsed]
    dec a
    dec a
    jr nz, .SecondAreaUnused
    
    ; If we went over one tile, make sure we start with it next time
    ld a, [wVWFCurTileNum]
    inc a
    ld [wVWFCurTileNum], a
    ld a, $00
    ld hl, wVWFBuildArea4
    ld de, wVWFBuildArea3
    ld bc, $0008
    call FarCopyData ; XXX don't use far
    ld hl, wVWFBuildArea4
    ld a, $0
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a ; lazy
    

.SecondAreaUnused
    ; If we went over the last character allocated for VWF tiles, wrap around.
    ; This is an error handler; ideally it wouldn't happen.
    ld a, [wVWFCurTileNum]
    cp $22
    jr c, .Return
    ld a, $00
    ld [wVWFCurTileNum], a ; Prevent overflow
.Return
    ret
.NotDialogue
    ; We're not within dialogue, so let's do what the original code would.
    ld a, [wVWFTileLoc1]
    ld h, a
    ld a, [wVWFTileLoc2]
    ld l, a
    ld a, [wVWFCharacter]
    ld [hl], a
    ret
