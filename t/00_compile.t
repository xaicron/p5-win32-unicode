use strict;
use Test::More tests => 3;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

BEGIN {
	use_ok 'Win32::Unicode';
	use_ok 'Win32::Unicode::Dir';
	use_ok 'Win32::Unicode::File';
}
