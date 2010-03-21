use strict;
use Test::More tests => 26;
use Test::Exception;

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir tempfile/;

close STDERR; # warnings to be quiet

{
	my $dir = 't/07_files';
	my $cmd = 'attrib';
	
	ok file_type(d => $dir), "dir";
	ok file_type(f => "$dir/file.txt"), "file";
	ok file_type(d => "$dir/dir"), "dir";
	
	{
		system $cmd, '+H', "$dir/hidden.txt" and die "Oops!!";
		system $cmd, '+H', "$dir/hidden" and die "Oops!!";
		ok file_type(hf => "$dir/hidden.txt"), "hidden file";
		ok file_type(hd => "$dir/hidden"), "hidden dir";
	}
	
	{
		system $cmd, '+R', "$dir/read_only.txt" and die "Oops!!";
		system $cmd, '+R', "$dir/read_only" and die "Oops!!";
		ok file_type(rf => "$dir/read_only.txt"), "read only file";
		ok file_type(rd => "$dir/read_only"), "read only dir";
	}
	
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
