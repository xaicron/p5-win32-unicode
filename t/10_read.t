use strict;
use warnings;
use utf8;
use Test::More tests => 24;
use Test::Exception;
use Win32::Unicode::Console;

my $wuct = 'Win32::Unicode::Console::Tie';
tie *{Test::More->builder->output}, $wuct;
tie *{Test::More->builder->failure_output}, $wuct;
tie *{Test::More->builder->todo_output}, $wuct;

use Win32::Unicode::File;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

my $dir = 't/10_read';
my $heart_file = File::Spec->catfile("$dir/test.txt");

ok my $wfile = Win32::Unicode::File->new;
isa_ok $wfile, 'Win32::Unicode::File';

# OO test
{
	ok $wfile->open(r => $heart_file);
	is $wfile->file_name, $heart_file;
	ok $wfile->binmode(':utf8');
	is $wfile->read(my $buff, 10), 10;
	is $buff, '0123456789';
	ok $wfile->seek(0, 0);
	is $wfile->readline(), "0123456789\n";
	is $wfile->readline(), "はろーわーるど\n";
	is $wfile->tell(), file_size $wfile->file_name;
	ok not $wfile->getc();
	ok $wfile->close;
}

# tie test
{
	ok open $wfile, '<', $heart_file;
	is $wfile->file_name, $heart_file;
	ok binmode $wfile, ':utf8';
	is read($wfile, my $buff, 10), 10;
	is $buff, '0123456789';
	ok seek($wfile, 0, 0);
	is readline($wfile), "0123456789\n";
	is <$wfile>, "はろーわーるど\n";
	is tell($wfile), file_size $wfile->file_name;
	ok not getc($wfile);
	ok close $wfile;
}
