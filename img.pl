#!/usr/bin/perl -w
undef $/;
$_=<>;
$x=576;
$y=272;
for $l (0..$y/8-1) { # char y
    for $m (0..$x/8-1) { # char x
	for $n (0..7) { # char row
	    print substr($_,$l*$x+$m+$x/8*$n,1);
	}
    }
}
