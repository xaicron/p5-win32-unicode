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

our @EXPORT = qw/safe_dir CYGWIN/;

use Win32::Unicode::Console;
tie *Foo, 'Win32::Unicode::Console::Tie';
Test::More->builder->$_(\*Foo) for qw/output failure_output todo_output/;

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

1;
