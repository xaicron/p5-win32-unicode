use inc::Module::Install;
name 'Win32-Unicode';
all_from 'lib/Win32/Unicode.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
test_requires  'Test::Output';
use_test_base;
auto_include;
WriteAll;
