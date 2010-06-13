use strict;
use Test::More;
use Test::Exception;
use Test::SharedFork;

use Win32::Unicode;
use utf8;
use File::Temp qw/tempdir/;

{
    my $tmpdir = tempdir CLEANUP => 1;
    
    touchW "$tmpdir/read" or die $!;
    my $fh = Win32::Unicode::File->new;
    $fh->open(r => "$tmpdir/read") or die $!;
    
    ok $fh->flock(1);
    ok $fh->unlock;
    ok $fh->flock(2);
    ok $fh->unlock;
    ok $fh->flock(5);
    ok $fh->unlock;
    ok $fh->flock(6);
    ok $fh->flock(8);
    
    $fh->close;
};

{
    my $tmpdir = tempdir CLEANUP => 1;
    
    touchW "$tmpdir/write" or die $!;
    my $fh = Win32::Unicode::File->new;
    $fh->open(w => "$tmpdir/write") or die $!;
    
    ok $fh->flock(1);
    ok $fh->unlock;
    ok $fh->flock(2);
    ok $fh->unlock;
    ok $fh->flock(5);
    ok $fh->unlock;
    ok $fh->flock(6);
    ok $fh->flock(8);
    
    $fh->close;
};

# うごかん＞＜
{
    my $tmpdir = tempdir CLEANUP => 1;
    
    touchW "$tmpdir/wait" or die $!;
    my $fh = Win32::Unicode::File->new;
    $fh->open(w => "$tmpdir/wait") or die $!;
    print $fh "test";
    $fh->close;
    
    $fh->open(r => "$tmpdir/wait") or die $!;
    ok $fh->flock(1), 'parent flock 1';
    
    my $pid = fork;
    if ($pid == 0) {
        my $fh2 = Win32::Unicode::File->new;
        $fh2->open(r => "$tmpdir/wait") or die $!;
        ok tied(*$fh2)->{_handle} ne tied(*$fh)->{_hanlde}, 'child handle';
        ok !$fh2->flock(1), 'child flock 1';
        ok !$fh2->readline, 'child readline';
        ok !$fh2->unlock, 'child unlock';
        exit;
    }
    elsif ($pid) {
        wait;
    }
    else {
        die $!;
    }
}

done_testing;
