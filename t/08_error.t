use strict;
use warnings;
use Test::More tests => 4;

binmode Test::More->builder->output, ":encoding(cp932)";
binmode Test::More->builder->failure_output, ":encoding(cp932)";
binmode Test::More->builder->todo_output, ":encoding(cp932)";

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

use Win32::Unicode;

ok Win32::Unicode::Error::error;
ok Win32::Unicode::Dir::error;
ok Win32::Unicode::File::error;
ok errorW;
