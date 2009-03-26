use strict;
use warnings;
use Test::More tests => 5;
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
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my $str = " I \x{2665} Perl";

ok printW($str), "printW";
ok printfW($str), "printW";
ok sayW($str), "sayW";
ok warnW($str), "warnW";
dies_ok { dieW($str) } "dieW";
