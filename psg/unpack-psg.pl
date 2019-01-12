#!/usr/bin/perl -w
$/=undef;#slurp
$xm=<>;

# tweakables
my $eoroff=$ENV{eoroff} || 45;
my $pattsize=$ENV{pattsize} || 32;
my $noteoff=$ENV{noteoff} || 43;
my $noteeor=$ENV{noteeor} || 23;
my $minieor=$ENV{minieor} || 13;

#$id=substr($xm,0,60);
$hlen=unpack'V',substr($xm,60,4);
$header=substr($xm,60,$hlen);
$npatts=unpack'v',substr($header,10,2);
$nchan=unpack'v',substr($header,8,2);

my $seqlen=unpack"v",substr($header,4,2);
my @seq=unpack"C$seqlen",substr($header,20);

use Data::Dumper;

print Dumper \@seq;

#my @chanmap=(1,2,3,0);
#my $noise=0;
#my $tune=1;
my @chanmap=(1,0,2,3);
my $noise=3;
my $tune=1;


print "$npatts patterns, $nchan channels\n";
$offset=60+$hlen;
my @patts;
my %notesused;

for (0..$npatts-1) {
    $plen=unpack'V',substr($xm,$offset,4);
    $patt=substr($xm,$offset,$plen);
    $nrows=unpack'v',substr($patt,5,2);
    $dlen=unpack'v',substr($patt,7,2);
    $data=substr($xm,$offset+$plen,$dlen);
    $poff=0;
    print "pattern $_, length $nrows\n";
    push @pattlen, $nrows;
    my @patt;
    for my $row (1..$nrows) {
	for my $chan (0..$nchan-1) {
	    my $newdata='';
	    $note=unpack'C',substr($data,$poff,1);
	    if ($note & 0x80) {
		$poff++;
		for(1..5) {
		    if ($note &1) {
			$foo=unpack'C',substr($data,$poff++,1);
			$newdata.=chr$foo;
		    } else {
			$newdata.="\0";
		    }
		    $note>>=1;
		}
	    } else {
		$newdata=substr($data,$poff,5);
		$poff+=5;
	    }
	    push @{$patt[$chanmap[$chan]]},$newdata;
#	    printf "%02x%02x%02x%02x%02x ", unpack"C5",$newdata;
	}
#	print "\n";
    }
    push @patts, \@patt;
    $offset+=$plen+$dlen;
}

my $speed=2;
my @out;

my @vol;
my @scvol=(15)x$nchan;



for my $seq (0..$seqlen-1) {
    my $patt=$seq[$seq];
    my @patt=@{$patts[$patt]};
    print "seq $seq patt $patt\n";
    
    for my $row (0..$pattlen[$seq[$seq]]-1) {
	my @newrow;
	for my $chan (0..$nchan-1) {
	    my @event=unpack"C5", $patts[$patt][$chan][$row];
	    printf "%02x%02x%02x%02x%02x ",@event;
	    my @newevent=(255,255,255,255);
	    if ($event[0]) {
		$newevent[0]=($event[0]-$noteoff)^$noteeor unless $chan==$noise;
		$notesused{$newevent[0]}++ if $chan!=$noise;
		if ($event[0]==0x61) {
		    $vol[$chan]=0;
		} else {
		    $vol[$chan]=64;
		}
	    }
	    if ($event[3]==12) {
		$vol[$chan]=$event[4];
	    }
	    if ($event[2]>=0x10 && $event[2]<=0x50) {
		$vol[$chan]=$event[2]-16;
	    }
	    
	    my $scvol=vol($vol[$chan]);
	    if ($scvol!=$scvol[$chan]) {
		$newevent[1]=$scvol[$chan]=$scvol;
	    }

	    if ($event[3]==0 && $event[4]) {
		die unless $event[0];
		$newevent[2]=($event[0]+($event[4]>>4)-$noteoff)^$noteeor;
		$notesused{$newevent[2]}++;
	    }
	    if ($event[3]==10) {
		die unless $event[4];
		$vol[$chan]-=$event[4];
		$vol[$chan]=0 if $vol[$chan]<0;
		
		my $scvol=vol($vol[$chan]);
		if ($scvol!=$scvol[$chan]) {
		    $newevent[3]=$scvol[$chan]=$scvol;
		}
	    }
	    push @newrow, \@newevent;
	    $out[$chan].=pack "C4",@newevent;

	}
	for my $chan (0..$nchan-1) {
	    printf "%02x%02x%02x%02x ", @{$newrow[$chan]};
	}
	print "\n";
    }
}

print (scalar keys %notesused," notes used\n");
print "note range: ",(join"-",(sort {$a<=>$b} keys %notesused)[0,-1]),"\n";
my @notes=sort {$notesused{$a}<=>$notesused{$b}} keys %notesused;
if (0) {
    my %noteinv;
    $noteinv{pack"C",$notes[$_]}=pack"C",$_ for 0..$#notes;
    $noteinv{"\xff"}="\xff";
    #use Data::Dumper;print Dumper \%noteinv;exit;
    #pack"C",$_
    # lookup
    for my $chan (0..$nchan-1) {
#    $out[$chan]=~s/(.)(.)/pack("C",$notes[{for(unpack"C",$1){$_]).$2/seg;#,"replaced\n";
	$out[$chan]=~s/(.)(.)/(defined($noteinv{$1}) or die unpack"C",$1),$noteinv{$1}.$2/seg;#,"replaced\n";
    }
    print join",",@notes;
    print "\nnotelen: ".scalar(@notes)."\n";
    my $notetable;
#for my @notes {
#    my $pitch=400/(2^(($_-16)/12));
#    
#pitchhi?I%=(p% AND 15) OR &80
#pitchlo?I%=(p% DIV 16) AND 63
}

$evlen=length($out[0]);
print "$evlen events used\n";
$evlen/=$pattsize;

#print $out[0];
#__END__

$out[$tune]=~s/\xff{416}$//s or die; # ewww

open F,">offsets";
# chunk
my %chunks;
for my $chan (0..$nchan-1) {
#    $pattdata.="\xcc\xcc";
    my $offset=0;
    my $ptr=0;
    my $last;
    my %chlen;
    while ($offset < length($out[$chan])) {
	my $chunk=substr($out[$chan], $offset, $pattsize);
	$offset+=$pattsize;
	$inchunks++;
	if (!$chunks{$chunk}) { # add
#	    $data=$chunk;
	    $data=rle($chunk);#."\xdd";

	    $chunks{$chunk}=length($pattdata);
	    $pattdata.=$data;
	    $chend{$chunk}=length($pattdata);
	}
#	print F ($chunks{$chunk}-$chend{$last}."\n");
	if ($chunks{$chunk}>>8==$chend{$last}>>8 &&
	    $chunks{$chunk}!=$chend{$last}) {
	    printf F "%02x\n",($chunks{$chunk}^$chend{$last});
	}

	if ($last && $chend{$last}==$chunks{$chunk}) {
	    $table[$chan].=pack"C",255;
#	} elsif ($last && 
#		 $chunks{$chunk}-$chend{$last}<64 &&
#		 $chunks{$chunk}-$chend{$last}>=-64) {
	} elsif ($last && 
		 $chunks{$chunk}>>8==$chend{$last}>>8 &&
		 ($chunks{$chunk}^$chend{$last})>=$eoroff &&
		 ($chunks{$chunk}^$chend{$last})<$eoroff+64) {
	    $table[$chan].=pack"C",($chunks{$chunk}^$chend{$last})-$eoroff;
	} else {
#	    $table[$chan].=pack"CC",$chunks{$chunk} &0xff,$chunks{$chunk}>>8;
	    my $off=$chunks{$chunk};#^$chan*0x100;
#	    print "off $off chan $chan\n";
#	    die if $off<0;
	    $table[$chan].=pack"CC",($off &0x3f)|0x40,$off>>6;
	}

	$last=$chunk;
    }
    $table[$chan]=rle($table[$chan]);
}
print "$inchunks chunks in, ".(scalar keys %chunks)." chunks out, size=$pattsize\n";
my $plen=length $pattdata;
my $tlen=length(join'',@table);
my $len=length($table[0])/2;
print "table len $tlen, pattern data $plen, total ".($tlen+$plen)."\n";
print "len%=$len\n";
print "pattsize%=".$pattsize/$speed."\n";

my $loc=0x2000;
$loc+=$plen;
for (0..$nchan) {
    printf "$_: %x\n",$loc;
    $loc+=length($table[$_]);
}


for (0..$nchan-1) {
    open my $file, ">psgtable$_";
    print $file $table[$_];
}
open my $file, ">psgpattdata";
print $file $pattdata;



open my $file, ">psgnotetable";
print $file $notedata;


sub rle {
#    return $_[0];
    my @data=unpack"C*",$_[0];

	    my $count=0;
	    my $data;
	    for my $byte (@data) {
		if ($byte==255) {
		    $count++;
		    my $a=unpack"C",substr($data,-1,1);
		    if ($count==8) {
			$data.=pack"C",0x87;
			$count=0;
		    } elsif (length($data) && $a>=0 && $a<=0xf && $a!=$minieor && $count==7) {
			chop $data;
			$data.=pack"C",0x87|(($a^$minieor)<<3);
#			print "7 mini!\n";
			$count=0;
		    }
		} else {
		    die if $byte & 0x80;
		    if ($count) {
			die if $count>7;
#			if ($byte>0 && $byte<=0xf && $count<7) {
#			    $data.=pack"C",0x80|($byte<<3)|($count);
#			} else 

			my $a=unpack"C",substr($data,-1,1);
			if (length($data) && $a>=0 && $a<=0xf && $a!=$minieor) {
			    chop $data;
			    $data.=pack"C",0x80|(($a^$minieor)<<3)|($count);
			} else {
			    $data.=pack"C",0x80|($count-1);
			}
			$count=0;
		    }
		    $data.=pack"C",$byte;
		}
	    }

	    if ($count) {
		die if $count>7;
		my $a=unpack"C",substr($data,-1,1);
		if (length($data) && $a>=0 && $a<=0xf && $a!=$minieor) {
		    chop $data;
		    $data.=pack"C",0x80|(($a^$minieor)<<3)|($count);
		} else {
		    $data.=pack"C",0x80|($count-1);
		}
	    }
    return $data;
}    

#sub vol { $a=15-int( (($_[0]/64)**.8)*15+.4 ); }#print "q=$_[0] vol=$a\n";}
sub vol {for (0..15) { if ($_[0]>=((64,51,40,32,25,20,16,13,10,8,6,5,4,3,2,0)[$_])) { print "q=$_[0] vol=$_\n" if 0;return $_; } } }
