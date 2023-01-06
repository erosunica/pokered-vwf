; rst vectors

SECTION "rst0", ROM0[$0000]
	rst $38

	ds $08 - @, 0 ; unused

SECTION "rst8", ROM0[$0008]
	rst $38

	ds $10 - @, 0 ; unused

SECTION "rst10", ROM0[$0010]
	rst $38

	ds $18 - @, 0 ; unused

; VWF HAX
SECTION "rst18", ROM0[$0018]
	ld [wHackOldA], a
	ret

	ds $20 - @, 0 ; unused

; VWF HAX
SECTION "rst20", ROM0[$0020]
	ld [wHackPredef], a
	ldh a, [hLoadedROMBank]
	ld [wHackOldBank], a
	ld a, BANK(HackPredef)
	ld [MBC1RomBank], a
	ldh [hLoadedROMBank], a
	call HackPredef
	ld a, [wHackOldBank]
	ld [MBC1RomBank], a
	ldh [hLoadedROMBank], a
	ld a, [wHackOldA]
	ret

; memory for rst vectors $28-$38 used by VWF hack

	ds $40 - @, 0 ; unused


; Game Boy hardware interrupts

SECTION "vblank", ROM0[$0040]
	jp VBlank

	ds $48 - @, 0 ; unused

SECTION "lcd", ROM0[$0048]
	rst $38

	ds $50 - @, 0 ; unused

SECTION "timer", ROM0[$0050]
	jp Timer

	ds $58 - @, 0 ; unused

SECTION "serial", ROM0[$0058]
	jp Serial

	ds $60 - @, 0 ; unused

SECTION "joypad", ROM0[$0060]
	reti


SECTION "Header", ROM0[$0100]

Start::
; Nintendo requires all Game Boy ROMs to begin with a nop ($00) and a jp ($C3)
; to the starting address.
	nop
	jp _Start

; The Game Boy cartridge header data is patched over by rgbfix.
; This makes sure it doesn't get used for anything else.

	ds $0150 - @
