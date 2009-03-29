use strict;
use warnings;
use Test::Base;
use Test::Exception;

use Win32::Unicode::File;

plan tests => (1 * blocks) + 1;

dies_ok { Win32::Unicode::File::filename_normalize() };

sub normalize { Win32::Unicode::File::filename_normalize(shift) }

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
