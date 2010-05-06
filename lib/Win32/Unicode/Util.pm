package Win32::Unicode::Util;

use strict;
use warnings;
use 5.008003;
use Encode ();
use File::Basename qw/fileparse/;
use File::Spec::Win32;
use File::Spec::Cygwin;
use Exporter 'import';

use Win32::Unicode::Constant qw/CYGWIN _32INT _S32INT/;

File::Basename::fileparse_set_fstype('MSWIN32');

# export subs
our @EXPORT = qw/utf16_to_utf8 utf8_to_utf16 cygpathw to64int is64int catfile splitdir/;

# Unicode decoder
my $utf16 = Encode::find_encoding 'utf16-le';

sub utf16_to_utf8 {
    my $str = shift;
    return unless defined $str;
    return _denull($utf16->decode($str));
}

sub utf8_to_utf16 {
    my $str = shift;
    return unless defined $str;
    return $utf16->encode($str);
}

sub _denull {
    my $str = shift;
    $str =~ s/\x00//g;
    return $str;
}

sub to64int {
    my ($high, $low) = @_;
    
    use bigint;
    return (($high << 32) + $low);
}

sub is64int {
    $_[0] > _32INT or $_[0] < _S32INT;
}

sub cygpathw {
    require Win32::Unicode::Dir;
    
    my $path = shift;
    my ($name, $dir) = fileparse $path;
    
    $dir =~ s/^([A-Z]:)\./$1/i; # C:.\ => C:\
    
    my $current = Win32::Unicode::Dir::getcwdW() or return;
    CORE::chdir $dir or return;
    $dir = Win32::Unicode::Dir::getcwdW() or return;
    CORE::chdir $current or return;
    
    if (defined $name) {
        return catfile($dir, $name) if defined $dir;
        return $name;
    }
    
    return $dir;
}

sub catfile {
    my $path = File::Spec::Win32->catfile(@_);
    $path = File::Spec::Cygwin->catfile($path) if CYGWIN;
    return $path;
}

sub splitdir {
    return File::Spec::Win32->splitdir(@_);
}

1;
