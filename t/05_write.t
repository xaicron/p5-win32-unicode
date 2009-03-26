use strict;
use warnings;
use Test::More tests => 6;

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

my $str = 'ぁぃぅぇぉ';
{
	# print
	my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
	binmode $fh, ":utf8";
	ok printW $fh, $str;
	close $fh;
	
	open $fh, "<:utf8", $filename or die "$!";
	my $buff = do { local $/; <$fh> };
	is $buff, $str;
	close $fh;
}

{
	# printf
	my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
	binmode $fh, ":utf8";
	ok printfW $fh, $str;
	close $fh;
	
	open $fh, "<:utf8", $filename or die "$!";
	my $buff = do { local $/; <$fh> };
	is $buff, $str;
	close $fh;
}

{
	# say
	my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";
	binmode $fh, ":utf8";
	ok sayW $fh, $str;
	close $fh;
	
	open $fh, "<:utf8", $filename or die "$!";
	my $buff = do { local $/; <$fh> };
	is $buff, "$str\n";
	close $fh;
}
