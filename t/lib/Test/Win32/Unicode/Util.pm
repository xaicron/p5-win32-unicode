package Test::Win32::Unicode::Util;

use strict;
use warnings;
use Exporter 'import';

use Cwd ();
use File::Temp qw/tempdir/;
use File::Spec;
use Carp;
use Test::More;

use constant CYGWIN => $^O eq 'cygwin';

our @EXPORT = qw/safe_dir dump_tree CYGWIN/;

use Win32::Unicode::Console;
tie *Foo, 'Win32::Unicode::Console::Tie';
binmode STDOUT => ':utf8';
Test::More->builder->$_(\*Foo) for qw/output failure_output todo_output/;

use Win32::Unicode::Dir;

sub safe_dir(&) {
    my $code = shift;
    my $cwd = Cwd::getcwd;
    my $tmpdir = tempdir CLEANUP => 1;
    
    chdir $tmpdir;
    local $@;
    eval { $code->($tmpdir) };
    chdir $cwd;
    croak $@ if $@;
}

sub dump_tree {
    my $dir = shift;
    unless ($ENV{HARNESS_ACTIVE}) {
        findW +{ wanted => sub { note $_ }, no_chdir => 1 }, $dir;
    }
}

1;
