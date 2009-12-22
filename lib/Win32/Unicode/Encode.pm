package Win32::Unicode::Encode;

use strict;
use warnings;
use 5.008001;
use Encode ();
use Exporter 'import';

# export subs
our @EXPORT = qw/utf16_to_utf8 utf8_to_utf16/;

our $VERSION = '0.11';

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

1;
__END__
=head1 NAME

Win32::Unicode::Encode.pm - encode and decode util

=head1 SYNOPSIS

    use Win32::Unicode::Encode;

    my $utf16 = utf8_to_utf16($utf8);
    my $utf8  = utf16_to_utf8($utf16);

=head1 DESCRIPTION

This module is by default C<utf8_to_utf16> and C<utf16_to_utf8> export functions.

=head2 FUNCTIONS

=over

=item utf8_to_utf16

=item utf16_to_utf8

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Encode>
L<Win32::Unicode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
