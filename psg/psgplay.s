org &2000
.playstart
INCBIN "psg/psgdata"
{
ptr=&b0
seqptr=&b8
count=&c0
seqlen=&c8
temp=&cA
chan=&cB
chan4=&cC
evcount=&cD
octnum=&cA
pitchlo=&cE
pitchhi=&cF
.vol
ORA lookup-4,X ;get channel number into top nybble
ORA     #&10    ;
.write
LDY     #&FF    ;System VIA port A all outputs
STY     &FE43   ;set
STA     &FE4F   ;output A on port A
INY             ;Y=0
STY     &FE40   ;enable sound chip
NOP
NOP
NOP
NOP
LDY     #&08
STY     &FE40
RTS
.pitch
LDY     #&00
STY     octnum
.octloop
CMP     #&0C
BCC     nooct
INC     octnum
SBC     #&0C
BNE     octloop
.nooct
TAY
CPY #5
LDA     lotable,Y
STA     pitchlo
LDY #3
BCC pitchnoinc
DEY
.pitchnoinc
STY     pitchhi
.octshift
LDY octnum
BEQ     octshiftdone
.octshiftloop
LSR     pitchhi
ROR     pitchlo
DEY
BNE     octshiftloop
.octshiftdone
LDA     pitchlo
AND     #&0F
ORA     lookup-4,X
JSR     write
LDA     pitchlo
LSR     pitchhi
ROR A
LSR     pitchhi
ROR A
LSR A
LSR A
JMP write
.lotable
EQUB &F0:EQUB &B7:EQUB &82:EQUB &4F
EQUB &20:EQUB &F3:EQUB &C8:EQUB &A0
EQUB &7B:EQUB &57:EQUB &35:EQUB &16

.lookup
EQUB &E0
EQUB &C0
EQUB &A0
EQUB &80 
.rle
\ chan in A
TAY
LDX count,Y
BNE docount
ASL A
TAX
LDA (ptr,X)
INC ptr,X
BNE noover
INC ptr+1,X
.noover
CMP #0
BPL exit
.prepcount
TAX
AND #7
STA count,Y
TXA
AND #&78
BEQ do255
TXA
LSR A
LSR A
LSR A
AND #15
EOR #13 \minieor
RTS

.docount
DEX
STX count,Y
.do255
LDA #255
.exit
RTS

.chaninit
LDA #3
STA chan
LDA #7
STA chan4
RTS

.*playinit
PHP:PHA:TXA:PHA:TYA:PHA
        LDA #&7F
        STA &FE4E ; R14=Interrupt Enable (disable all interrupts)

        LDA #&C0
        STA &FE4E ; R14=Interrupt Enable (enable timer 1)

        LDA #64
        STA &FE4B ; R11=Auxillary Control Register (timer 1 latch mode)

        LDX #&60
        STX &FE44 ; R4=T1 Low-Order Latches (write)
        STX &FE45 ; R5=T1 High-Order Counter


LDA #&E4
JSR write

.tuneloop
LDX #initend-initdata
.initloop
LDA initdata,X
STA seqptr,X
DEX
BPL initloop

.go
JSR chaninit

.ptrloop
LDA chan4
JSR rle
BMI noseq

\lo
ASL A
BPL dooff
ASL A
STA temp
LDA chan4
JSR rle

\hi
TAY
LDA chan
ASL A
TAX
TYA
\CLC
\ADC #(patt% DIV256)*4
ORA #&80
LSR A
ROR temp
LSR A
STA ptr+1,X
\lo
LDA temp
ROR A
STA ptr,X

.noseq
DEC chan4
DEC chan
BPL ptrloop

\RTS

.patt
LDA #16 \pattsize%
STA evcount

.event
PLA:TAY:PLA:TAX:PLA:PLP:RTS
.*poll
PHP:PHA:TXA:PHA:TYA:PHA
.delay
	LDA &FE44 \clear

JSR chaninit

.loop
LDA chan
CMP #2
BNE always
LDX seqlen
CPX #14
BMI skipvol
.always
JSR rle
BMI skipnote
EOR #23 \noteeor
LDX chan4
\ASL A
\ASL A
JSR pitch
.skipnote
LDA chan
JSR rle
BMI skipvol
LDX chan4
JSR vol
.skipvol
DEC chan4
DEC chan
BPL loop
DEC evcount
BNE event

DEC seqlen

BNE go

\BEQ nogo
\JMP go
\.nogo

\DEC seqlen+1
\BNE go
JMP tuneloop

.dooff
LSR A
CLC
ADC #45 \ eoroff
STA temp
LDA chan
ASL A
TAX
LDA ptr,X
EOR temp
STA ptr,X
JMP noseq

.initdata
\EQUW &367E \seq3
\EQUW &351C \seq0
\EQUW &3576 \seq1
\EQUW &3603 \seq2

EQUW &2619
EQUW &24B6
EQUW &2542
EQUW &2596

EQUD 0 \chan counts
EQUD 0 \seq counts
EQUB 140 \seqlen
.initend
.*standalone
	SEI
	JSR playinit
.*runner
	LDA #$45:STA &FE10
.runloop
	LDA #&40
        BIT &FE4D
	beq runner
	jsr poll
	bne runloop
;SEI
;	JSR playinit
;.runloop
;	JSR poll
;	JMP runloop
.playend
SAVE "player",playstart,playend,standalone
}
