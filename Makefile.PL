use inc::Module::Install;

name 'Win32-Unicode';
all_from 'lib/Win32/Unicode.pm';

use_ppport 3.19;
cc_warnings;

requires 'Win32API::File', '0.1101';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More', '0.96';
test_requires 'Test::Output';
test_requires 'Test::Exception';

cc_src_paths qw(xs);

auto_include;
auto_set_repository;

WriteAll;
