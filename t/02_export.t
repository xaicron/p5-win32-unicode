use strict;
use Test::More tests => 22;

my $wuct = 'Win32::Unicode::Console::Tie';
tie *{Test::More->builder->output}, $wuct;
tie *{Test::More->builder->failure_output}, $wuct;
tie *{Test::More->builder->todo_output}, $wuct;

unless ($^O eq 'MSWin32') {
	plan skip_all => 'MSWin32 Only';
	exit;
}

use Win32::Unicode;

can_ok 'main', $_ for qw{
	printW printfW warnW sayW
	file_type file_size copyW moveW unlinkW touchW renameW
	mkdirW rmdirW getcwdW chdirW findW finddepthW mkpathW rmtreeW mvtreeW cptreeW dir_size
};
