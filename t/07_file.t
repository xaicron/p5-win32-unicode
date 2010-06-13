use strict;
use Test::More;
use Test::Exception;

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir tempfile/;
use File::Spec;

open STDERR, '>', File::Spec->devnull;

subtest file_type => sub {
    my $dir = 't/07_files';
    my $cmd = 'attrib';
    
    ok file_type(d => $dir), "dir";
    ok file_type(f => "$dir/file.txt"), "file";
    ok file_type(d => "$dir/dir"), "dir";
    
    subtest hidden => sub {
        system $cmd, '+H', "$dir/hidden.txt" and die "Oops!!";
        system $cmd, '+H', "$dir/hidden" and die "Oops!!";
        ok file_type(hf => "$dir/hidden.txt"), "hidden file";
        ok file_type(hd => "$dir/hidden"), "hidden dir";
        
        done_testing;
    };
    
    subtest readonly => sub {
        system $cmd, '+R', "$dir/read_only.txt" and die "Oops!!";
        system $cmd, '+R', "$dir/read_only" and die "Oops!!";
        ok file_type(rf => "$dir/read_only.txt"), "read only file";
        ok file_type(rd => "$dir/read_only"), "read only dir";
        
        done_testing;
    };
    
    is file_size("$dir/10byte.txt"), 10;
    ok not file_size("$dir");
    ok not file_type(t => '');
    
    done_testing;
};

subtest simple => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $filename = '森鷗外';
    
    ok touchW "$tmpdir/$filename";
    ok copyW "$tmpdir/$filename", "$tmpdir/$filename.txt";
    ok unlinkW "$tmpdir/$filename";
    ok moveW "$tmpdir/$filename.txt", "$tmpdir/$filename";
    ok renameW "$tmpdir/$filename", "$tmpdir/$filename.txt";
    ok unlinkW "$tmpdir/$filename.txt";
    
    done_testing;
};

subtest '$_' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    local $_ = "$tmpdir/ほげ";
    ok touchW;
    ok unlinkW;
    
    done_testing;
};

subtest 'stat' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 ) or die $!;
    my $file = "$tmpdir/test";
    touchW $file;
    
    my @stat = CORE::stat $file;
    my @statW = statW $file;
    
    is $statW[7],  $stat[7];
    is $statW[8],  $stat[8];
    is $statW[9],  $stat[9];
    is $statW[10], $stat[10];
    
    TODO: {
        local $TODO = 'Unimplemented' if Win32::Unicode::Constant::CYGWIN;
        is $statW[1],  $stat[1];
        is $statW[4],  $stat[4];
        is $statW[5],  $stat[5];
        is $statW[11], $stat[11];
        is $statW[12], $stat[12];
    };
    
    TODO: {
        local $TODO = 'Unimplemented';
        is $statW[0], $stat[0];
        is $statW[2], $stat[2];
        is $statW[3], $stat[3];
        is $statW[6], $stat[6];
    };
    
    my $statW = statW $file;
    
    is $statW->{size},    $stat[7];
    is $statW->{atime},   $stat[8];
    is $statW->{mtime},   $stat[9];
    is $statW->{ctime},   $stat[10];
    
    TODO: {
        local $TODO = 'Unimplemented' if Win32::Unicode::Constant::CYGWIN;
        is $statW->{ino},     $stat[1];
        is $statW->{uid},     $stat[4];
        is $statW->{gid},     $stat[5];
        is $statW->{blksize}, $stat[11];
        is $statW->{blocks},  $stat[12];
    };
    
    TODO: {
        local $TODO = 'Unimplemented';
        is $statW->{dev},   $stat[0];
        is $statW->{mode},  $stat[2];
        is $statW->{nlink}, $stat[3];
        is $statW->{rdev},  $stat[6];
    };
    
    done_testing;
};

subtest exeption => sub {
    dies_ok { file_type() };
    dies_ok { file_type('t') };
    dies_ok { copyW() };
    dies_ok { copyW('test') };
    dies_ok { moveW() };
    dies_ok { moveW('test') };
    dies_ok { renameW() };
    dies_ok { renameW('test') };
    
    done_testing;
};

done_testing;
