package Win32::Unicode::Console;

use strict;
use warnings;
use 5.008_001;
use utf8;
use Carp ();
use Win32::API ();
use Exporter 'import';

use Win32::Unicode::Encode;
use Win32::Unicode::Constant;

# export subs
our @EXPORT = qw/printW printfW warnW sayW dieW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.05';

# GetStdHandle
my $GetStdHandle = Win32::API->new('kernel32.dll',
	'GetStdHandle',
	'N',
	'N',
) or die ": $^E";

# WriteConsole
my $WriteConsole = Win32::API->new('kernel32.dll',
	'WriteConsoleW',
	[qw(N P N N P)],
	'I',
) or die "WriteConsole: $^E";

# ConsoleOut
my $ConsoleOut = sub {
	my $handle = $GetStdHandle->Call(shift);
	return 0 unless @_;
	
	# 1968 prove only?
	return print @_ if $handle != shift and $handle != 1968;
	
	my $str = join '', @_;
	
	for (my $i = MAX_BUFFER_SIZE; $i < length($str);) {
		my $tmp_str = substr($str, 0, $i);
		substr($str, 0, $i) = '';
		
		my $buff = 0;
		$WriteConsole->Call($handle, utf8_to_utf16($tmp_str), length($tmp_str), $buff, NULL);
	}
	
	if ($str) {
		my $buff = 0;
		$WriteConsole->Call($handle, utf8_to_utf16($str), length($str), $buff, NULL);
	}
};

# print Unicode to Console
sub printW {
	if (&_is_file_handle($_[0])) {
		my $fh = shift;
		print {$fh} join "", @_;
		return 1;
	}
	
	$ConsoleOut->(STD_OUTPUT_HANDLE, CONSOLE_OUTPUT_HANDLE, @_);
	
	return 1;
}

# printf Unicode to Console
sub printfW {
	if (&_is_file_handle($_[0])) {
		my $fh = shift;
		&printW($fh, sprintf shift, @_)
	}
	
	else {
		&printW(sprintf shift, @_);
	}
}

sub _is_file_handle {
	ref $_[0] eq 'GLOB' and ref(*{$_[0]}{IO}) =~ /^IO::/ ? 1 : 0;
}

# say Unicode to Console
sub sayW {
	&printW(@_, "\n");
}

# warn Unicode to Console
sub warnW {
	$ConsoleOut->(STD_ERROR_HANDLE, CONSOLE_ERROR_HANDLE, Carp::shortmess(@_));
	return 1;
}

# die Unicode to Console
sub dieW {
	local $SIG{__DIE__} = sub { &warnW(@_) };
	die @_;
}

sub _row_warn {
	$ConsoleOut->(STD_ERROR_HANDLE, CONSOLE_ERROR_HANDLE, @_);
	return 1;
}

1;
__END__
=head1 NAME

Win32::Unicode::Console.pm - Unicode string to console out

=head1 SYNOPSIS

  use Win32::Unicode::Console;
  
  my $flaged_utf8_str = "I \x{2665} Perl";
  
  # stdout unicode string
  printW $flaged_utf8_str;
  
  # stderr unicode string
  warnW $flaged_utf8_str;

=head1 DESCRIPTION

Wn32::Unicode::Console provides Unicode String to console out.
This module is by default C<printW> and C<warnW> export functions.

C<printW> and C<warnW> PerlIO has not passed.
However, when the file is redirected to the C<CORE:: print> and C<CORE:: warn> switches.

=head1 METHODS

=over

=item printW

Unicode string to console out.
Like print.

=item printfW

Unicode string to console out.
Like printf.

=item sayW

Unicode string to console out.
Like Perl6 say.

=item warnW

Unicode string to console out.
Like warn.

=item dieW

Unicode string to console out.
Like die.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32::Unicode>
L<Win32::API>

=cut
