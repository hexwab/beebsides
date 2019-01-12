org $600
music_loaded=&b9

.start	
.basic
	equb 13,$07,$e3,$07,$d6,$b8,$50,13,255
.reloc	
	jsr $ffec
	tay
	sta $80
	tsx
	lda $100,X
	sta $81
.relocloop
	lda ($80),Y
	sta $60D,Y
	iny
	bne relocloop
	jmp main
.main
	sei
	;LDA #&7F
        ;STA &FE4E ; R14=Interrupt Enable (disable all interrupts)
	;LDA &FE44 ; clear
	lda #$72
	lda #1
	jsr $fff4
	sec
	ror $ff
	lda #126
	jsr $fff4
	ldy #3
.loop
	lda vdutab,Y
	jsr $ffcb
	dey
	bpl loop
	ldy #13
.regloop
	sty &FE00
	lda regs,Y
	sta &FE01
	dey
	bne regloop
	lda #10
	sta $fe00
	sta $fe01
	LDA #&85:STA &FE10
	LDA #&D5:STA &FE08
	ldy #0
	sty music_loaded
.loadinitial
	jsr get_crunched_byte
	sta $400,Y
	iny
	bne loadinitial
	jsr decrunch
	jsr playinit
	jsr decrunch
.go
;;	lda #$9c
;;	sta $fe20
;;	clc
;;	lda #0
;; .palloop
;; 	sta $fe21
;; 	adc #$10
;; 	bcs done
;; 	bpl palloop
;; 	ora #$0f
;; 	bne palloop ;always
.done
	jmp runner
.regs
	equb 127: equb 72:equb 94: equb &28
	equb 38: equb 0: equb 34: equb 36
	equb 0: equb 7: equb 0: equb 0
	equb 6: equb &70
.vdutab
	equb 21,0,22
.get_crunched_byte
	PHP
	LDA music_loaded
	BEQ nopoll
	LDA #&40
        BIT &FE4D
	BEQ nopoll
	JSR poll
.nopoll	LDA &FE08
	AND #1
	BEQ get_crunched_byte+1
	LDA &FE09
	PLP
	RTS
.tabl_bit
        equb %11100001, %10001100, %11100010
.end
save "loader",start,end
INCLUDE "bsidesdecr.s"
INCLUDE "psg/psgplay.s"
