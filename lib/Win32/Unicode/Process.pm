package Win32::Unicode::Process;

use strict;
use warnings;
use 5.008003;
use Win32::API ();
use Win32API::File ();
use Carp ();
use Exporter 'import';

use Win32::Unicode::Util;
use Win32::Unicode::Constant;
use Win32::Unicode::Define;

# export subs
our @EXPORT    = qw/systemW execW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.18';

# cmd path
my $SHELL = do {
    my $path = catfile($ENV{ComSpec} || 'C:/WINDOWS/system32/cmd.exe');
    utf8_to_utf16($path) . NULL;
};

sub systemW {
    my $pi = _create_process(@_) or return 1;
    Win32API::File::CloseHandle($pi->{hThread});
    WaitForInputIdle->Call($pi->{hProcess}, INFINITE);
    WaitForSingleObject->Call($pi->{hProcess}, INFINITE);
    Win32API::File::CloseHandle($pi->{hProcess});
    
    return 0;
}

sub execW {
    my $pi = _create_process(@_) or return 1;
    Win32API::File::CloseHandle($pi->{hThread});
    Win32API::File::CloseHandle($pi->{hProcess});
    
    return 0;
}

sub _create_process {
    my $cmd = shift || return;
    my @args;
    for (@_) {
        my $arg = $_;
        $arg =~ s/^"|"$//g;     # trim qquote
        $arg =~ s/"/\"/g;       # escape qquote
        push @args, qq{"$arg"};
    }
    
    $cmd = utf8_to_utf16("/x /c $cmd @args") . NULL; # mybe security hole :-(
    
    my $si = Win32::API::Struct->new('STARTUPINFO');
    my $pi = Win32::API::Struct->new('PROCESS_INFORMATION');
    
    CreateProcess->Call(
        $SHELL,
        $cmd,
        0,
        0,
        FALSE,
        NORMAL_PRIORITY_CLASS,
        0,
        0,
        $si,
        $pi,
    ) or return;
    
    return $pi;
}

1;

__END__
