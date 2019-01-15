all: bsides.uef

test: bsides.uef
	/w/b-em/b-em -tape bsides.uef

bsides.uef: loader bsidesdecr bsides.raw.beebed.exo player.exo
	perl writeuef.pl <loader >bsides.uef

loader: bsidesyes.s
	beebasm -i bsidesyes.s -v >listing

player.exo: player
	exomizer level player@0x2000 -o player.exo

bsides.raw: bsideslogo5.png
	pngtopnm $< |ppmtopgm | pgmtopbm |perl -e '<>;<>;undef$$/;print<>' |perl -pe'$$_^="\xff"x length'>$@

bsides.raw.beebed: bsides.raw
	perl img.pl <bsides.raw >bsides.raw.beebed

bsides.raw.beebed.exo: bsides.raw.beebed
	exomizer level bsides.raw.beebed@0x3000 -o bsides.raw.beebed.exo

clean:
	-rm -f bsides.uef loader bsidesdecr bsides.raw.beebed.exo \
		bsides.raw.beebed bsides.raw player player player.exo
