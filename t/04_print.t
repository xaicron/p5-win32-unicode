use strict;
use warnings;
use utf8;
use Test::More tests => 5;
use Test::Exception;
use Test::Output;
use Win32::Unicode;

my $str = " I \x{2665} Perl";

TODO: {
	local $TODO = 'ToDo';
	stdout_is { printW($str) }  $str;
	stdout_is { printfW("[%s]", $str) } "[$str]" ;
	stdout_is { sayW($str) } "$str\n";
};

ok warnW($str), "warnW";
dies_ok { dieW($str) } "dieW";
