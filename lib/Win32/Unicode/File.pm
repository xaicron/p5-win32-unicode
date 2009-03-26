package Win32::Unicode::File;

use strict;
use warnings;
use 5.008_001;
use Win32::API ();
use Win32API::File ();
use Carp ();
use File::Spec::Functions qw/catfile/;
use File::Basename qw/basename/;
use Exporter 'import';

use Win32::Unicode::Error;
use Win32::Unicode::Encode;
use Win32::Unicode::Constant;

our @EXPORT = qw/file_type file_size copyW moveW unlinkW touchW renameW/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.04';

my %ATTRIBUTES = (
	s => FILE_ATTRIBUTE_SYSTEM,
	r => FILE_ATTRIBUTE_READONLY,
	h => FILE_ATTRIBUTE_HIDDEN,
	d => FILE_ATTRIBUTE_DIRECTORY,
	a => FILE_ATTRIBUTE_ARCHIVE,
	n => FILE_ATTRIBUTE_NORMAL,
	t => FILE_ATTRIBUTE_TEMPORARY,
	c => FILE_ATTRIBUTE_COMPRESSED,
	o => FILE_ATTRIBUTE_OFFLINE,
	i => FILE_ATTRIBUTE_NOT_CONTENT_INDEXED,
	e => FILE_ATTRIBUTE_ENCRYPTED,
);

my $PathFileExists = Win32::API->new('shlwapi.dll',
	'PathFileExistsW',
	'P',
	'I',
);

my $PathIsDirectory = Win32::API->new('shlwapi.dll',
	'PathIsDirectoryW',
	'P',
	'I',
);

my $GetFileAttributes = Win32::API->new('kernel32.dll',
	'GetFileAttributesW',
	'P',
	'N',
);

my $CopyFile = Win32::API->new('kernel32.dll',
	'CopyFileW',
	['P', 'P', 'I'],
	'I',
);

my $MoveFile = Win32::API->new('kernel32.dll',
	'MoveFileW',
	['P', 'P'],
	'I'
);

=pod
sub open {
	my $class =shift;
	&_croakW("Usage: $class->open('attrebute', 'filename')") unless @_ == 2;
	my $attr = shift;
	my $file = utf8_to_utf16(catfile shift ) . NULL;
	
	bless { }, $class;
}

sub close {

}

sub seek {

}

sub flock {

}

sub read {

}

sub read_line {

}

sub slurp {

}
=cut

sub file_type {
	&_croakW('Usage: type(attribute, file_or_dir_name)') unless @_ == 2;
	my $attr = shift;
	my $file = catfile shift;
	
	my $get_attr = &_get_file_type($file);
	for (split //, $attr) {
		if ($_ eq 'f') {
			return 0 unless &_is_file($file);
			next;
		}
		
		unless (defined $ATTRIBUTES{$_}) {
			Carp::carp "unkown attribute '$_'";
			next;
		}
		return 0 unless $get_attr & $ATTRIBUTES{$_};
	}
	return 1;
}

sub file_size {
	my $file = shift;
	&_croakW('Usage: file_size(filename)') unless defined $file;
	$file = catfile $file;
	
	return 0 unless &file_type(f => $file);
	
	my $handle = Win32API::File::CreateFileW(
		utf8_to_utf16($file) . NULL,
		GENERIC_READ,
		FILE_SHARE_READ,
		[],
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		[],
	);
	
	return 0 if $handle == INVALID_VALUE;
	
	my $size = Win32API::File::getFileSize($handle);
	
	if ($size == INVALID_VALUE) {
		warn 'Could not get file size - ' . errorW;
		return 0;
	}
	
	Win32API::File::CloseHandle($handle);
	
	return $size;
}

# like unix touch command
sub touchW {
	my $file = shift;
	&_croakW('Usage: touchW(filename)') unless defined $file;
	$file = catfile $file;
	return Win32::CreateFile($file) ? 1 : 0;
}

# like CORE::unlink
sub unlinkW {
	my $file = shift;
	&_croakW('Usage: unlinkW(filename)') unless defined $file;
	$file = utf8_to_utf16(catfile $file) . NULL;
	return Win32API::File::DeleteFileW($file) ? 1 : 0;
}

# like File::Copy::copy
sub copyW {
	&_croakW('Usage: copyW(from, to [, over])') if @_ < 2;
	my $from = catfile shift;
	my $to = &_file_name_validete($from, shift);
	my $over = shift || 0;
	
	$from = utf8_to_utf16($from) . NULL;
	$to   = utf8_to_utf16($to) . NULL;
	
	return $CopyFile->Call($from, $to, !$over) ? 1 : 0;
}

# move file
sub moveW {
	&_croakW('Usage: moveW(from, to [, over])') unless @_ < 2;
	my $from = catfile shift;
	my $to = &_file_name_validete($from, shift);
	my $over = shift || 0;
	
	unless ($MoveFile->Call(utf8_to_utf16($from) . NULL, utf8_to_utf16($to) . NULL)) {
		return 0 unless &copyW($from, $to, $over);
		return 0 unless &unlinkW($from);
	};
	
	return 1;
}
*renameW = \&moveW;

my $back_to_dir = qr/^\.\.$/;
my $in_dir      = qr#[\\/]$#;

sub _file_name_validete {
	&_croakW('Usage: _file_name_validete(from, to)') unless @_ == 2;
	my $from = shift;
	my $to = shift;
	
	if ($to =~ $back_to_dir or $to =~ $in_dir or &file_type(d => $to)) {
		$to = catfile $to, basename($from);
	}
	$to = catfile $to;
	
	return $to;
}

sub error {
	return errorW;
}

sub _get_file_type {
	my $file = shift;
	my $buff = BUFF;
	$file = utf8_to_utf16($file) . NULL;
	my $result = $GetFileAttributes->Call($file);
	if ($result == INVALID_VALUE) {
		return 0;
	}
	return $result;
}

sub _is_file {
	my $file = shift;
	my $tmp_file = utf8_to_utf16($file) . NULL;
	if ($PathFileExists->Call($tmp_file)) {
		return 1 unless &_is_dir($file);
	};
	return 0
}

sub _is_dir {
	my $file = shift;
	$file = utf8_to_utf16($file) . NULL;
	return $PathIsDirectory->Call($file);
}

sub _croakW {
	Win32::Unicode::Console::_row_warn(@_);
	die Carp::shortmess();
}

1;
__END__
