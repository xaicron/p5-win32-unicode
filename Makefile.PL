use inc::Module::Install;
name 'Win32-Unicode';
all_from 'lib/Win32/Unicode.pm';

requires 'Win32::API';
requires 'Win32API::File';
requires 'File::Spec::Functions';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
test_requires  'Test::Output';
test_requires  'Test::Base';
use_test_base;
auto_include;
WriteAll;
