use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir/;
use Win32::Unicode::Constant qw/CYGWIN/;
use File::Copy qw/copy/;
use Encode;

my $tmpdir = tempdir CLEANUP => 1;
my $script = "$tmpdir/args.pl";
copy 't/34_args/args.pl', $script or die $!;

my $argv = "てすと";
my $enc = CYGWIN ? 'utf8' : 'cp932';
ok !system $^X, "$script", "$tmpdir/out", encode($enc => $argv);

open my $fh, '<:utf8', "$tmpdir/out" or die $!;
is <$fh>, $argv;
close $fh;

done_testing;
