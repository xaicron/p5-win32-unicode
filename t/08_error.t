use strict;
use warnings;
use Test::More tests => 4;

use Win32::Unicode;

ok Win32::Unicode::Error::error;
ok Win32::Unicode::Dir::error;
ok Win32::Unicode::File::error;
ok errorW;
