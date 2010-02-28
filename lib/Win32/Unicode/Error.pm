package Win32::Unicode::Error;

use strict;
use warnings;
use 5.008003;
use Win32::API ();
use Carp ();
use Exporter 'import';

our $VERSION = '0.14';

use Win32::Unicode::Console;
use Win32::Unicode::Constant;
use Win32::Unicode::Encode;

# export subs
our @EXPORT    = qw/errorW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

my $GetLastError = Win32::API->new('kernel32.dll',
    'GetLastError',
    '',
    'I',
) or die $^E;

my $FormatMessage = Win32::API->new('kernel32.dll', 
    'FormatMessageW',
    [qw/I P I I P I P/],
    'I',
) or die $^E;

sub error {
    shift;
    my $buff = BUFF;
    my $result = $FormatMessage->Call(
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        $GetLastError->Call(),
        LANG_USER_DEFAULT,
        $buff,
        length($buff),
        NULL,
    );
    
    $buff = unpack "A520", $buff;
    return utf16_to_utf8($buff);
}

sub errorW {
    return __PACKAGE__->error;
}

1;
__END__
=head1 NAME

Win32::Unicode::Error.pm - return error message.

=head1 SYNOPSIS

  use Win32::Unicode;
  
  # stdout unicode string
  mkdirW($exists_dir) or die errorW
  
=head1 DESCRIPTION

Wn32::Unicode::Error is retrun to Win32API error message.

=head1 METHODS

=over

=item error

OO.

=item errorW

function.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32::Unicode>
L<Win32::Unicode::Dir>
L<Win32::Unicode::File>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
