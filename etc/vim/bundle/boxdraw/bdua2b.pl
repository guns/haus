# Convert +-| style drawings into utf characters
# BoxDraw-unicode-ascii to box
# 2003-11-24 10:12:22 created by nsg
# 2003-11-25 13:16:17 renamed and small fix in "intelligence"
# 2004-06-18 14:18:11 boxsets
# 2004-06-21 21:41:30 hex input codes
use strict;
use utf8;
use 5.8.0;
use Getopt::Std;

our (
  $opt_s, # boxset 's', 'd', 'v' or 'h'
  $opt_x, # convert hex digits into appropriate bd characters
  $opt_t, # ternary codes ' ' .. 'p' 
);
getopts("s:xt");
$opt_s||='s';

my $o_utf8='--0251--001459--50585a----------0202----0c1c----525e------------51--51--53--5f--54--60------------------------------------------00185c--003468------------------1024----2c3c--------------------56--62--65--6b--------------------------------------------------505b5d----------506769----------5561------------646a------------57--63----------66--6c------------------------------------------------------------------01';

binmode (STDOUT, ":utf8");
my %boxset=(
# 1|.,'}\u{25',"1 (_2 ]\ o_utf8) {~ 4#.2*#:i.16
 's'=>" \x{2502}\x{2500}\x{2514}\x{2502}\x{2502}\x{250c}\x{251c}\x{2500}\x{2518}\x{2500}\x{2534}\x{2510}\x{2524}\x{252c}\x{253c}\n",
 'd'=>" \x{2551}\x{2550}\x{255a}\x{2551}\x{2551}\x{2554}\x{2560}\x{2550}\x{255d}\x{2550}\x{2569}\x{2557}\x{2563}\x{2566}\x{256c}\n",
 'h'=>" \x{2502}\x{2550}\x{2558}\x{2502}\x{2502}\x{2552}\x{255e}\x{2550}\x{255b}\x{2550}\x{2567}\x{2555}\x{2561}\x{2564}\x{256a}\n",
 'v'=>" \x{2551}\x{2500}\x{2559}\x{2551}\x{2551}\x{2553}\x{255f}\x{2500}\x{255c}\x{2500}\x{2568}\x{2556}\x{2562}\x{2565}\x{256b}\n",
);

my $BOX=$boxset{$opt_s} || $boxset{'s'};

my $prev='';
my $pprev='';
while(<STDIN>) {
  process_line();
}
process_line();

sub process_line
{
 my $out='';
 for(my $i=0; $i<length($prev); ++$i) {
   my $code=0;
   my $c=substr($prev,$i,1);
   if( $opt_x ) {
     $code=0;
     $code=hex($c) if $c=~/[[:xdigit:]]/;
   } elsif( $opt_t ) {
     $code=0;
     if( ord($c)>32 ) {
       $c=ord($c)-32;
       for(0..3){$code =($code>>2)+(($c%3)<<6); $c=int($c/3);}
       $c=chr(hex('25'.substr($o_utf8, $code*2,2)));
     }
     $code=0;
   } else {
     if( $c=~/[-+\|]/ ) {
       $code |= 1 if substr($pprev,$i  ,1)=~/[\|+]/ ;
       $code |= 2 if substr($prev ,$i+1,1)=~/[-+]/ ;
       $code |= 4 if substr($_    ,$i  ,1)=~/[\|+]/ ;
       $code |= 8 if substr($prev ,$i-1,1)=~/[-+]/ ;

       $code = 10 if $code && '-' eq $c;
       $code = 5 if $code && '|' eq $c;
     }
   }
   $out.=$code?substr($BOX,$code,1):$c;
 }
 print $out;
 $pprev=$prev;
 $prev=$_;
}

#
#  
#  0001 02
#  0010 00
#  0011 14
#  0100 02
#  0101 02
#  0110 0c
#  0111 1c
#  1000 00
#  1001 18
#  1010 00
#  1011 34
#  1100 10
#  1101 24
#  1110 2c
#  1111 3c
