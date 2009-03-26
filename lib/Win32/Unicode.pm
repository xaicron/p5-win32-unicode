package Win32::Unicode;

use strict;
use warnings;
use 5.008_001;
use Win32::API ();
use Exporter 'import';

use Win32::Unicode::Console ':all';
use Win32::Unicode::File ':all';
use Win32::Unicode::Dir ':all';
use Win32::Unicode::Error ':all';

# export subs
our @EXPORT = (
	@Win32::Unicode::Console::EXPORT,
	@Win32::Unicode::File::EXPORT,
	@Win32::Unicode::Dir::EXPORT,
	@Win32::Unicode::Error::EXPORT,
);

our @EXPORT_OK = (
	@Win32::Unicode::Console::EXPORT_OK,
	@Win32::Unicode::File::EXPORT_OK,
	@Win32::Unicode::Dir::EXPORT_OK,
	@Win32::Unicode::Error::EXPORT_OK,
);

our %EXPORT_TAGS = (
	$Win32::Unicode::Console::EXPORT_TAGS{all},
	$Win32::Unicode::File::EXPORT_TAGS{all},
	$Win32::Unicode::Dir::EXPORT_TAGS{all},
	$Win32::Unicode::Error::EXPORT_TAGS{all},
);
our $VERSION = '0.05';

1;
__END__
=head1 NAME

Win32::Unicode.pm - Unicode string to console out

=head1 SYNOPSIS

  use Win32::Unicode;
  
  my $flaged_utf8_str = "I \x{2665} Perl";
  
  # stdout unicode string
  printW $flaged_utf8_str;
  
  # stderr unicode string
  warnW $flaged_utf8_str;

=head1 DESCRIPTION

Wn32::Unicode provides Unicode String to console out.
This module is by default C<printW> and C<warnW> export functions.

C<printW> and C<warnW> PerlIO has not passed.
However, when the file is redirected to the C<CORE:: print> and C<CORE:: warn> switches.

=head1 METHODS

=over

=item printW

Unicode string to console out.
Like print.

=item warnW

Unicode string to console out.
Like warn.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32>
L<Win32::API>
L<Win32::Unicode::Dir>
L<Win32::Unicode::File>
L<Win32::Unicode::Encode>
L<Win32::Unicode::Error>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
