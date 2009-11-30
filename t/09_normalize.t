use strict;
use warnings;
use utf8;
use Test::Base;
use Test::Exception;

use Win32::Unicode::File qw/filename_normalize/;

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
