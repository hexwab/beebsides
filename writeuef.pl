#!/usr/bin/perl -w
use Digest::CRC qw[crc];
print "UEF File!\x00\x01\x00";
chunk(0x110,pack"v",100); # carrier

undef $/;
$data=<>;
$fn="BSides";
$load=0xffff0600;
$exec=0xffff0620;
$blkno=0;
$blklen=length$data;
$flags=0x80; #81;
my $header=$fn.pack"CVVvvCV",0,
    $load,$exec,$blkno,$blklen,$flags,0;
$header='*'.$header.pack"n",crc($header,16,0,0,0,0x1021,0,0);

$data.=pack"n",crc($data,16,0,0,0,0x1021,0,0);
#print $data;
chunk(0x100,$header.$data);

chunk(0x110,pack"v",500); # carrier

open F, "bsidesdecr" or die $!;
$raw = <F>;
#chunk(0x100,$raw);

#chunk(0x110,pack"v",100); # carrier

open F, "<player.exo" or die $!;
$raw .= <F>;
#chunk(0x100,$raw);

#chunk(0x110,pack"v",1000); # carrier

# exomizer level  /w/bsides.raw.beebed@0x3380 -o /w/bsides.raw.beebed.exo
open F, "<bsides.raw.beebed.exo" or die $!;
$raw .= <F>;
chunk(0x100,$raw);

sub chunk {
    my ($id,$data)=@_;
    print pack"vV",$id,length$data;
    print $data;
}