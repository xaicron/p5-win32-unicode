package Win32::Unicode::Native;

use strict;
use warnings;
use 5.008001;
use Exporter 'import';

our $VERSION = '0.01';

use Win32::Unicode::Console ':all';
use Win32::Unicode::File ':all';
use Win32::Unicode::Dir ':all';
use Win32::Unicode::Error ();

our @EXPORT = qw{
	error
	file_size
	file_type
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
	my $fh = Win32::Unicode::File->new;
	$fh->open($_[1], $_[2]);
	return $_[0] = $fh;
}

sub close {
	my $fh = $_[0];
	$fh->close;
	$_[0] = undef;
}

# Win32::Unicode::Dir
$sub_export->(qw{
	mkdirW
	rmdirW
	chidirW
	findW
	finddepthW
	mkpathW
	rmtreeW
	mvtreeW
	cptreeW
	getcwdW
});

sub opendir {
	my $dh = Win32::Unicode::Dir->new;
	$dh->open($_[1]);
	return $_[0] = $dh;
}

sub closedir {
	my $dh = $_[0];
	$dh->close;
	$_[0] = undef;
}

sub readdir {
	my $dh = shift;
	return $dh->fetch;
};

# Win32::Unicode::Error
*error = \&Win32::Unicode::Error::errorW;

1;
__END__
