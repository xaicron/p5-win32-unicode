use strict;
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

use Win32::Unicode::Encode;
use utf8;
use Encode qw/encode/;

my $utf8_str  = 'あかさたなｶｷｸｹｺ';
my $utf16_str = encode 'utf16-le', $utf8_str;

is(utf8_to_utf16($utf8_str), $utf16_str);
is(utf16_to_utf8($utf16_str), $utf8_str);
ok(not utf8_to_utf16);
ok(not utf16_to_utf8);
