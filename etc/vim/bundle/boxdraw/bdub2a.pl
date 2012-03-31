# Convert +-| style drawings into utf characters
# BoxDraw-unicode-box to ascii
# 2003-11-25 12:48:17 -- created by nsg

use 5.8.0;
use strict;
use utf8;
# binmode (STDOUT, ":utf8"); # incompatible with perl 5.6.1
# binmode (STDIN, ":utf8"); # incompatible with perl 5.6.1

while(<STDIN>) {
  my $l=length;
  tr/┌┬┐╓╥╖╒╤╕╔╦╗├┼┤╟╫╢╞╪╡╠╬╣└┴┘╙╨╜╘╧╛╚╩╝/++++++++++++++++++++++++++++++++++++/;
  tr/═─│║/\-\-\|\|/;
  printf "%03d ",$l;
  print ;
}

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

