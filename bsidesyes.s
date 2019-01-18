org $500
music_loaded=&b9
progress_count=&9f
.start	
.basic
	equb 13,$07,$e3,$07,$d6,$b8,$50,13,255
.reloc	
	sec
	ror $ff
	lda #126
	jsr $fff4
	ldy #0
	sty $b9
	tsx
	lda $100,X
	sta $ba
.relocloop
	lda ($b9),Y
	sta start,Y
	iny
	bne relocloop
	jmp main
.main
	sei
	;; tape on
	LDA #&85:STA &FE10
	LDA #&D5:STA &FE08
	;sty music_loaded ;0
	;LDA #&7F
        ;STA &FE4E ; R14=Interrupt Enable (disable all interrupts)
	;LDA &FE44 ; clear
	ldy #vduend-vdutab
	sty progress_count
.vduloop
	lda vdutab,Y
	jsr $ffcb
	dey
	bpl vduloop
	;; cursor off: 8 bytes
	;lda #10
	;sta $fe00
	;sta $fe01
	;; sync: 12 bytes (+2)
;; .sync
;; 	ldy #2
;; .syncloop
;; 	jsr poll_things
;; 	cmp #$f7
;; 	bne sync
;; 	dey
;; 	bpl syncloop
.loadinitial
	jsr get_crunched_byte
	sta $400,Y
	dey
	bne loadinitial
	jsr decrunch
	jmp runner
.get_crunched_byte
	PHP
	DEC progress_count
	BNE poll_things
	LDA #'#'
.nop_this_out
	JSR &FFCB
	;lda #20
	sta progress_count
.poll_things
	LDA music_loaded
	BEQ nomusic
	JSR poll
.nomusic
	LDA &FE08
	LSR A
	BCC poll_things
	LDA &FE09
	PLP
	RTS
.vdutab
	equb '[',31,17,31,']',31,62,31,0,22
.vduend
;.tabl_bit
;        equb %11100001, %10001100, %11100010
.end
save "loader",start,end
INCLUDE "bsidesdecr.s"
INCLUDE "psg/psgplay.s"
