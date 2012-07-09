use strict;
use warnings;
use utf8;
use lib 't/lib';
use Test::More;
use Test::Exception;
use Test::Win32::Unicode::Util;

use File::Temp qw/tempdir tempfile/;
use File::Basename qw/fileparse/;
use File::Spec;

use Win32::Unicode::Dir;
use Win32::Unicode::File;

subtest 'mkdir/rmdir' => sub {
    safe_dir {
        my $dirname = "I \x{2665} Perl";
        
        ok mkdirW($dirname), "mkdirW will be success";
        ok !mkdirW($dirname), "exsists directory";
        
        ok rmdirW($dirname), 'rmdir will be success';
        ok !rmdirW($dirname), 'directory not found';
    };
    
    done_testing;
};

subtest 'mkdir/rmdir using $_' => sub {
    safe_dir {
        local $_ = "I \x{2665} Perl";
        
        ok mkdirW, "mkdirW will be success";
        ok !mkdirW, "exsists directory";
        
        ok rmdirW, 'rmdir will be success';
        ok !rmdirW, 'directory not found';
    };
    
    done_testing;
};

subtest 'chdir/getcwd' => sub {
    safe_dir {
        my $cwd = shift;
        my $dirname = "I \x{2665} Perl";
        mkdirW $dirname;
        
        ok chdirW($dirname), "chdirW will be success";
        
        SKIP: {
            skip 'only MSWIN32', 1 if CYGWIN;
            is(File::Spec->catfile(getcwdW), File::Spec->catfile($cwd, $dirname), "getcwdW will be success");
        };
        
        ok chdirW('..'), 'parent directory chdir';
        rmdirW $dirname;
    };
    
    done_testing;
};

subtest 'file_list/dir_list' => sub {
    safe_dir {
        my $cwd = shift;
        my $tmpdir = 'test';
        my ($dir, $file) = ("dir_\x{2665}", "file_\x{2665}");
        
        mkdirW $tmpdir;
        mkdirW "$tmpdir/$dir";
        touchW "$tmpdir/$file";
        
        is_deeply [dir_list $tmpdir], [$dir], 'get all directorys';
        is_deeply [file_list $tmpdir], [$file], 'get all files';
        
        rmdirW "$tmpdir/$dir";
        unlinkW "$tmpdir/$file";
        rmdirW $tmpdir;
    };
    
    done_testing;
};

subtest 'exceptions' => sub {
    open STDERR, '>', File::Spec->devnull or die $!;
    dies_ok { chdirW } 'chdirW must be directory specified';
    done_testing;
};

done_testing;

__END__
ok mkdirW($dirname);
ok mkdirW("$dirname/森鴎外");
ok touchW("$dirname/森鴎外/$dirname.txt");
ok touchW("$dirname/森鴎外/0");

my $file_names = +{"森鴎外" => 1, "$dirname.txt" => 1, "0" => 1};
findW(sub {
    my $arg = shift;
    ok $file_names->{$_}++;
    is $_, $arg->{file};
    is $Win32::Unicode::Dir::name, $arg->{path};
    is $Win32::Unicode::Dir::cwd, $arg->{cwd};
}, $dirname);

finddepthW(sub {
    my $arg = shift;
    ok $file_names->{$_}++;
    is $_, $arg->{file};
    is $Win32::Unicode::Dir::name, $arg->{path};
    is $Win32::Unicode::Dir::cwd, $arg->{cwd};
}, $dirname);

is_deeply +{"森鴎外" => 3, "$dirname.txt" => 3, "0" => 3}, $file_names;

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

$tmpdir = tempdir(CLEANUP => 1);
chdir $tmpdir;

# Exeption Tests
dies_ok { rmtreeW() };
dies_ok { mkpathW() };

dies_ok { cptreeW() };
dies_ok { cptreeW('from') };
dies_ok { cptreeW('from', 'to') };

dies_ok { mvtreeW() };
dies_ok { mvtreeW('from') };
dies_ok { mvtreeW('from', 'to') };

dies_ok { findW(sub {}, 'aaa') };

done_testing;
