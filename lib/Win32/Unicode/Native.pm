package Win32::Unicode::Native;

use strict;
use warnings;
use 5.008003;
use Exporter 'import';

our $VERSION = '0.12';

use Win32::Unicode::Console ':all';
use Win32::Unicode::File ':all';
use Win32::Unicode::Dir ':all';
use Win32::Unicode::Error ();

our @EXPORT = qw{
	error
	file_size
	file_type
	dir_size
	open
	close
	opendir
	closedir
	readdir
};

my $sub_export = sub {
	for my $method (@_) {
		my ($func) = $method =~ /^(.*)W$/;
		no strict 'refs';
		*{"$func"} = \&{"$method"};
		push @EXPORT, $func;
	}
};

# Win32::Unicode::Console
$sub_export->(qw{
	printfW
	warnW
	dieW
	sayW
});

binmode STDOUT => ':utf8';
tie *STDOUT, 'Win32::Unicode::Console::Tie';

# Win32::Unicode::File
$sub_export->(qw{
	unlinkW
	renameW
	copyW
	moveW
	touchW
});

sub open {
	local $Carp::CarpLevel = 1;
	my $fh = Win32::Unicode::File->new;
	$fh->open($_[1], $_[2]) or return;
	return $_[0] = $fh;
}

sub close {
	local $Carp::CarpLevel = 1;
	my $fh = $_[0];
	$fh->close or return;
	$_[0] = undef;
	return 1;
}

# Win32::Unicode::Dir
$sub_export->(qw{
	mkdirW
	rmdirW
	chdirW
	findW
	finddepthW
	mkpathW
	rmtreeW
	mvtreeW
	cptreeW
	getcwdW
});

sub opendir {
	local $Carp::CarpLevel = 1;
	my $dh = Win32::Unicode::Dir->new;
	return unless $dh->open($_[1]);
	return $_[0] = $dh;
}

sub closedir {
	local $Carp::CarpLevel = 1;
	my $dh = $_[0];
	$dh->close or return;
	$_[0] = undef;
	return 1;
}

sub readdir {
	local $Carp::CarpLevel = 1;
	my $dh = shift;
	return $dh->fetch;
};

# Win32::Unicode::Error
*error = \&Win32::Unicode::Error::errorW;

1;
__END__
=head1 NAME

Win32::Unicode::Native.pm - override some default method

=head1 SYNOPSIS

  use Win32::Unicode::Native;
  
  print $flagged_utf8;
  
  open my $fh, '<', $unicode_file_name or die error;
  
  opendir my $dh, $unicode_dir_name or die error;
  
=head1 DESCRIPTION

Wn32::Unicode is a perl unicode-friendly wrapper for win32api.
This module standard functions override.
But it's limited to just using Win32.

Many features easy to use Perl because I think it looks identical to the standard function.

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Unicode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
