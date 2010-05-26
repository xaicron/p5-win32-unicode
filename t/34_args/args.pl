use strict;
use warnings;
use utf8;
use Win32::Unicode::Native;
open my $fh, '>', $ARGV[0] or die $!;
print $fh $ARGV[1];
close $fh;
