# outlines groups of similar characters
# 2003-11-24 15:07:28 Created by nsg
# 2004-06-18 14:29:45 changed hex boxset to x; added double, horz, vert boxsets
use strict;
use utf8;
use Getopt::Std;

our (
  $opt_s, # boxset (x=hex)
  $opt_d, # double each input character
  $opt_e, # output encoding
);
getopts("s:de:");
$opt_s='s' if '' eq $opt_s;
$opt_e='utf8' if '' eq $opt_e;

binmode (STDIN, ":encoding($opt_e)");
binmode (STDOUT, ":encoding($opt_e)");
#binmode (STDOUT, ":encoding(utf8)");
my $p='';

my %boxset=(
# 1|.,'}\u{25',"1 (_2 ]\ o_utf8) {~ 4#.2*#:i.16
 's'=>" \x{2502}\x{2500}\x{2514}\x{2502}\x{2502}\x{250c}\x{251c}\x{2500}\x{2518}\x{2500}\x{2534}\x{2510}\x{2524}\x{252c}\x{253c}\n",
 'd'=>" \x{2551}\x{2550}\x{255a}\x{2551}\x{2551}\x{2554}\x{2560}\x{2550}\x{255d}\x{2550}\x{2569}\x{2557}\x{2563}\x{2566}\x{256c}\n",
 'h'=>" \x{2502}\x{2550}\x{2558}\x{2502}\x{2502}\x{2552}\x{255e}\x{2550}\x{255b}\x{2550}\x{2567}\x{2555}\x{2561}\x{2564}\x{256a}\n",
 'v'=>" \x{2551}\x{2500}\x{2559}\x{2551}\x{2551}\x{2553}\x{255f}\x{2500}\x{255c}\x{2500}\x{2568}\x{2556}\x{2562}\x{2565}\x{256b}\n",
);

my $BOX=$boxset{$opt_s} || $boxset{'s'};

# corners/splits:
#  ┌┬┐╓╥╖╒╤╕╔╦╗ 6ec
#  ├┼┤╟╫╢╞╪╡╠╬╣ 7fd
#  └┴┘╙╨╜╘╧╛╚╩╝ 3b9
# round corners:
# 256d  256e
# 2570  256f
# horizontal
#  ═ ─
# vertical
#  │ ║

while(<STDIN>){
  chomp;
  s/./$&$&/g if $opt_d;
  process_line();
  $p=$_;
}
$_='';
process_line();

sub process_line
{
  my $out;
  my $l=length;
  $l=length($p) if length($p)>$l;
  for my$i(0..$l) {
    my $c=0;
    $c|=1 if sc($p,$i-1) ne sc($p,$i);
    $c|=2 if sc($p,$i) ne sc($_,$i);
    $c|=4 if sc($_,$i) ne sc($_,$i-1);
    $c|=8 if sc($_,$i-1) ne sc($p,$i-1);
    $out.=substr($BOX,$c,1) if 'x' ne $opt_s;
    $out.=sprintf"%1x",$c if 'x' eq $opt_s;
  }
  print "$out\n";
}

sub sc # (str, index)
{
  return ' ' if 0>$_[1] || $_[1]>=length($_[0]);
  return substr($_[0],$_[1],1);
}
