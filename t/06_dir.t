use strict;
use warnings;
use Test::More tests => 63;
use Test::Exception;

local $^W; # -w switch off ( Win32::API::Struct evil warnings stop!! )

use Win32::Unicode::Dir;
use Win32::Unicode::File;
use utf8;
use File::Temp qw/tempdir tempfile/;
use File::Basename qw/fileparse/;

my ($fh, $filename) = tempfile("tempXXXX", DIR => tempdir(CLEANUP => 1)) or die "$!";

my ($name, $path) = fileparse $filename;

$path =~ s/\\$//;

ok my $wdir = Win32::Unicode::Dir->new;
isa_ok $wdir, 'Win32::Unicode::Dir';
ok $wdir->open($path);
is $wdir->fetch, '.';
is $wdir->fetch, '..';
is $wdir->fetch, $name;
ok $wdir->close;

ok chdirW($path);
is getcwdW, $path;

my $dirname = "I \x{2665} Perl";

ok mkdirW($dirname);
ok not mkdirW($dirname);

ok rmdirW($dirname);
ok not rmdirW($dirname);


ok mkdirW($dirname);
ok mkdirW("$dirname/森鴎外");
ok touchW("$dirname/森鴎外/$dirname.txt");

my $i = 0;
my @file_names = ("森鴎外", "$dirname.txt");
findW(sub {
	my $arg = shift;
	is $_, $file_names[$i++];
	is $_, $arg->{file};
	is $Win32::Unicode::Dir::name, $arg->{path};
	is $Win32::Unicode::Dir::cwd, $arg->{cwd};
}, $dirname);

finddepthW(sub {
	my $arg = shift;
	is $_, $file_names[--$i];
	is $_, $arg->{file};
	is $Win32::Unicode::Dir::name, $arg->{path};
	is $Win32::Unicode::Dir::cwd, $arg->{cwd};
}, $dirname);

ok rmtreeW($dirname);

my $make_path = "$dirname/森鷗外/\x{2603}/ect";
ok mkpathW($make_path);
touchW("$make_path/\x{2600}.txt");

my @dir_list;
ok findW(sub { push @dir_list, $_ }, $dirname);

ok cptreeW($dirname, "test");

my @cp_list;
ok findW(sub { push @cp_list, $_ }, 'test');

is_deeply \@dir_list, \@cp_list;

my @cp_list2;
ok findW(sub { push @cp_list2, $_ }, 'test');

ok findW(sub { unlinkW $_ }, 'test');
ok cptreeW($dirname, "$dirname/../test", 1);
is_deeply \@dir_list, \@cp_list2;

ok rmtreeW('test');

ok mvtreeW($dirname, 'test');

my @mv_list;
ok findW(sub { push @mv_list, $_ }, 'test');
is_deeply \@dir_list, \@mv_list;

my $_10byte_file = Win32::Unicode::Dir::catfile(getcwdW, "test/10byte.txt");
open my $fh2, ">", $_10byte_file or die "$_10byte_file $!";
print $fh2 "0123456789";
close $fh2;
is dir_size('test'), 10;

rmtreeW($dirname);
rmtreeW('test');

# Exeption Tests
dies_ok { mkdirW() };
dies_ok { rmdirW() };
dies_ok { rmtreeW() };
dies_ok { mkpathW() };

dies_ok { cptreeW() };
dies_ok { cptreeW('from') };
dies_ok { cptreeW('from', 'to') };

dies_ok { mvtreeW() };
dies_ok { mvtreeW('from') };
dies_ok { mvtreeW('from', 'to') };

dies_ok { chdirW() };
dies_ok { Win32::Unicode::Dir->open()  };
dies_ok { Win32::Unicode::Dir->fetch() };
dies_ok { Win32::Unicode::Dir->close() };

dies_ok { dir_size() };

dies_ok { findW(sub {}, 'aaa') };
