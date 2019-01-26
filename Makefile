all: wav

# dependencies
UEFWALK=/home/HEx/uefwalk-1.50/
EXOMIZER=exomizer
BEEBASM=beebasm
BEM=/w/b-em/b-em
BBCIM=bbcim

# targets
wav: bsides.wav

test: bsides.uef boottape.ssd
	${BEM} -tape bsides.uef -disc boottape.ssd -autoboot

bsides.wav: bsides.uef
	${UEFWALK}/uefwalk --output=bitstream --quiet bsides.uef \
	| ${UEFWALK}/kleen/bitclean --verbose --text-input - \
	| sox -t raw -c 1 -L -b 16 -e signed -r 44100 - -t wav bsides.wav


bsides.uef: loader exodecr bsides.raw.beebed.exo player.exo
	perl writeuef.pl <loader >bsides.uef

loader: beebsides.s psg/psgdata
	${BEEBASM} -i beebsides.s -v >listing

player.exo: player
	${EXOMIZER} level player@0x2000 -o player.exo

bsides.raw: bsideslogo5.png
	pngtopnm $< |ppmtopgm | pgmtopbm |perl -e '<>;<>;undef$$/;print<>' |perl -pe'$$_^="\xff"x length'>$@

boottape.ssd: boottape boottape.inf
	-rm -f boottape.ssd
	${BBCIM} -a boottape.ssd boottape

bsides.raw.beebed: bsides.raw
	perl img.pl <bsides.raw >bsides.raw.beebed

bsides.raw.beebed.exo: bsides.raw.beebed
	${EXOMIZER} level bsides.raw.beebed@0x3000 -o bsides.raw.beebed.exo

psg/psgdata:
	cd psg;	perl unpack-psg.pl <psgyay.xm;cat psgpattdata psgtable? >psgdata

clean:
	-rm -f bsides.uef loader bsidesdecr bsides.raw.beebed.exo \
		bsides.raw.beebed bsides.raw player player player.exo \
		psg/psgdata psg/psgtable? psg/psgpattdata
