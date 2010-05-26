use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw/tempdir tempfile/;
use Win32::Unicode::Constant qw/CYGWIN/;
use Encode;

my $tmpdir = tempdir CLEANUP => 1;
my ($tfh, $exe) = tempfile('tempXXXX', DIR => $tmpdir);

my $code = do {
    local $/;
    open my $fh, '<', 't/34_args/args.pl' or die $!;
    <$fh>;
};

print $tfh <<"CODE";
#!$^X
$code
CODE

close $tfh;

chmod 755, $exe;

if ($^O eq 'MSWin32') {
    system 'pl2bat', $exe and die $?;
    $exe =~ s/\.pl/.bat/;
}

my $argv = "てすと";
my $enc = CYGWIN ? 'utf8' : 'cp932';
ok !system "$exe", "$tmpdir/out", encode($enc => $argv);

open my $fh, '<:utf8', "$tmpdir/out" or die $!;
is <$fh>, $argv;
close $fh;

done_testing;
