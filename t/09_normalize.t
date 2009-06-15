use strict;
use warnings;
use utf8;
use Test::Base;
use Test::Exception;
use Win32::Unicode::Console;

my $wuct = 'Win32::Unicode::Console::Tie';
tie *{Test::More->builder->output}, $wuct;
tie *{Test::More->builder->failure_output}, $wuct;
tie *{Test::More->builder->todo_output}, $wuct;

use Win32::Unicode::File qw/filename_normalize/;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

plan tests => (1 * blocks) + 1;

dies_ok { filename_normalize() };

sub normalize { filename_normalize(shift) }

filters {
	input    => [qw/chomp normalize/],
	expected => [qw/chomp/],
};

run_is;

__END__
=== test [ \ ]
--- input
test_is_\_filename.txt
--- expected
test_is_￥_filename.txt

=== test [ / ]
--- input
test_is_/_filename.txt
--- expected
test_is_／_filename.txt

=== test [ : ]
--- input
test_is_:_filename.txt
--- expected
test_is_：_filename.txt

=== test [ * ]
--- input
test_is_*_filename.txt
--- expected
test_is_＊_filename.txt

=== test [ ? ]
--- input
test_is_?_filename.txt
--- expected
test_is_？_filename.txt

=== test [ " ]
--- input
test_is_"_filename.txt
--- expected
test_is_″_filename.txt

=== test [ < ]
--- input
test_is_<_filename.txt
--- expected
test_is_＜_filename.txt

=== test [ > ]
--- input
test_is_>_filename.txt
--- expected
test_is_＞_filename.txt

=== test [ | ]
--- input
test_is_|_filename.txt
--- expected
test_is_｜_filename.txt
