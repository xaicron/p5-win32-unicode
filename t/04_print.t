use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use Test::Output;

binmode Test::More->builder->output, ":encoding(cp932)";
binmode Test::More->builder->failure_output, ":encoding(cp932)";
binmode Test::More->builder->todo_output, ":encoding(cp932)";

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

use Win32::Unicode;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $str = " I \x{2665} Perl";

stdout_is { printW($str) }  $str;
stdout_is { printfW("[%s]", $str) } "[$str]" ;
stdout_is { sayW($str) } "$str\n";

ok warnW($str), "warnW";
dies_ok { dieW($str) } "dieW";
