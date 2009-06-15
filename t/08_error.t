use strict;
use warnings;
use Test::More tests => 4;
use Win32::Unicode::Console;

my $wuct = 'Win32::Unicode::Console::Tie';
tie *{Test::More->builder->output}, $wuct;
tie *{Test::More->builder->failure_output}, $wuct;
tie *{Test::More->builder->todo_output}, $wuct;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

use Win32::Unicode;

ok Win32::Unicode::Error::error;
ok Win32::Unicode::Dir::error;
ok Win32::Unicode::File::error;
ok errorW;
