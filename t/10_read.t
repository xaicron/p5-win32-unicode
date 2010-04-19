use strict;
use warnings;
use utf8;
use Test::More tests => 29;
use Test::Exception;

local $^W; # -w switch off ( Win32::API::Struct evil warnings stop!! )

use Win32::Unicode::File ':all';

my $dir = 't/10_read';
my $read_file = File::Spec->catfile("$dir/test.txt");

ok my $wfile = Win32::Unicode::File->new;
isa_ok $wfile, 'Win32::Unicode::File';

use Data::Dumper;
# OO test
{
    ok $wfile->open(r => $read_file);
    is $wfile->file_path, File::Spec->catfile(Win32::Unicode::Dir::getcwdW() . "/$read_file");
    ok $wfile->binmode(':utf8');
    is $wfile->read(my $buff, 10), 10;
    is $buff, '0123456789';
    ok $wfile->seek(0, 0);
    is $wfile->readline(), "0123456789\n";
    is $wfile->readline(), "はろーわーるど\n";
    is $wfile->tell(), file_size $wfile->file_path;
    ok $wfile->seek(0, 0);
    is scalar @{[$wfile->readline()]}, 2;
    ok not $wfile->getc();
    ok $wfile->eof();
    my $data = $wfile->slurp;
    {
        use bytes;
        is length($data), file_size($wfile);
    }
    ok $wfile->close;
}

# tie test
{
    ok open $wfile, '<:raw', $read_file;
    ok binmode $wfile, ':utf8';
    is read($wfile, my $buff, 10), 10;
    is $buff, '0123456789';
    ok seek($wfile, 0, 0);
    is readline($wfile), "0123456789\n";
    is <$wfile>, "はろーわーるど\n";
    is tell($wfile), file_size $wfile->file_path;
    ok not getc($wfile);
    ok eof($wfile);
    my $data = slurp($wfile);
    {
        use bytes;
        is length($data), file_size($wfile);
    }
    ok close $wfile;
}
