use strict;
use warnings;
use Test::More;

use Win32::Unicode::Process;

local $^W; # -w switch off ( Win32::API::Struct evil warnings stop!! )

ok !systemW 'echo hoge > nul';

done_testing;
