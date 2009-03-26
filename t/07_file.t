use strict;
use Test::More tests => 26;
use Test::Exception;

binmode Test::More->builder->output, ":encoding(cp932)";
binmode Test::More->builder->failure_output, ":encoding(cp932)";
binmode Test::More->builder->todo_output, ":encoding(cp932)";

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir tempfile/;

{
	my $dir = 't/07_files';
	ok file_type(d => $dir);
	ok file_type(f => "$dir/file.txt");
	ok file_type(d => "$dir/dir");
	ok file_type(hf => "$dir/hidden.txt");
	ok file_type(hd => "$dir/hidden");
	ok file_type(rf => "$dir/read_only.txt");
	ok file_type(rd => "$dir/read_only");
	is file_size("$dir/10byte.txt"), 10;
	ok not file_size("$dir");
	ok not file_type(t => '');
}

{
	my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
	my $filename = '森鷗外';
	
	ok touchW "$tmpdir/$filename";
	ok copyW "$tmpdir/$filename", "$tmpdir/$filename.txt";
	ok unlinkW "$tmpdir/$filename";
	ok moveW "$tmpdir/$filename.txt", "$tmpdir/$filename";
	ok renameW "$tmpdir/$filename", "$tmpdir/$filename.txt";
	ok unlinkW "$tmpdir/$filename.txt";
}

# exeption
{
	dies_ok { touchW() };
	dies_ok { unlinkW() };
	dies_ok { file_type() };
	dies_ok { file_type('t') };
	dies_ok { copyW() };
	dies_ok { copyW('test') };
	dies_ok { moveW() };
	dies_ok { moveW('test') };
	dies_ok { renameW() };
	dies_ok { renameW('test') };
}
