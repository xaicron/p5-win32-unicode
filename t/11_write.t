use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Test::Flatten;
use File::Temp qw/tempdir tempfile/;
use Win32::Unicode::File;

my $dir = tempdir() or die $!;
my $write_file = File::Spec->catfile("$dir/森鷗外.txt");

ok my $wfile = Win32::Unicode::File->new;
isa_ok $wfile, 'Win32::Unicode::File';

# OO test
subtest OO => sub {
    ok $wfile->open(w => $write_file);
    ok $wfile->binmode(':utf8');
    ok $wfile->write('0123456789');
    ok $wfile->seek(0, 2);
    is $wfile->tell, 10;
    ok $wfile->close;
    
    done_testing;
};

subtest tie => sub {
    ok open $wfile, '>', $write_file;
    ok binmode $wfile, ':utf8';
    ok print $wfile '0123456789';
    ok seek($wfile, 0, 2);
    is tell $wfile, 10;
    ok close $wfile;
    
    done_testing;
};

Win32::Unicode::Dir::rmtreeW($dir);

done_testing;
