use strict;
use Test::More tests => 5;

use Win32::Unicode;

can_ok 'Win32::Unicode', qw(
	printW
	sayW
	warnW
);

can_ok 'Win32::Unicode::Dir', qw(
	getcwdW
	chdirW
	mkdirW
	rmdirW
	rmtreeW
	findW
	open
	close
	fetch
	file_type
	file_size
);

can_ok 'Win32::Unicode::File', qw(
	file_type
	file_size
	touchW
	moveW
	copyW
	unlinkW
	renameW
);

can_ok 'Win32::Unicode::Encode', qw(
	utf16_to_utf8
	utf8_to_utf16
);

can_ok 'Win32::Unicode::Error', qw(
	errorW
);
