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
our @EXPORT_OK = qw/filename_nomalize/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.06';

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

#sub open {
#	my $class =shift;
#	&_croakW("Usage: $class->open('attrebute', 'filename')") unless @_ == 2;
#	my $attr = shift;
#	my $file = utf8_to_utf16(catfile shift ) . NULL;
#	
#	bless { }, $class;
#}
#
#sub close {
#
#}
#
#sub seek {
#
#}
#
#sub flock {
#
#}
#
#sub read {
#
#}
#
#sub read_line {
#
#}
#
#sub slurp {
#
#}

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
	my ($from, $to) = &_file_name_validete(shift, shift);
	my $over = shift || 0;
	
	$from = utf8_to_utf16($from) . NULL;
	$to   = utf8_to_utf16($to) . NULL;
	
	return $CopyFile->Call($from, $to, !$over) ? 1 : 0;
}

# move file
sub moveW {
	&_croakW('Usage: moveW(from, to [, over])') if @_ < 2;
	my ($from, $to) = &_file_name_validete(shift, shift);
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
	&_croakW('from is a undefined values') unless defined $_[0];
	&_croakW('to is a undefined values')   unless defined $_[1];
	
	my $from = catfile shift;
	my $to = shift;
	
	if ($to =~ $back_to_dir or $to =~ $in_dir or &file_type(d => $to)) {
		$to = catfile $to, basename($from);
	}
	$to = catfile $to;
	
	return $from, $to;
}

my %win32_taboo = (
	'\\' => '￥',
	'/'  => '／',
	':'  => '：',
	'*'  => '＊',
	'?'  => '？',
	'"'  => '″',
	'<'  => '＜',
	'>'  => '＞',
	'|'  => '｜',
);

sub filename_normalize {
	my $file_name = shift;
	&_croakW('Usage: filename_nomalize($file_name)') unless defined $file_name;
	$file_name =~ s#([\\\/\:\*\?\"\<\>|])#$win32_taboo{$1}#ge;
	return $file_name;
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
=head1 NAME

Win32::Unicode::File.pm - Unicode string file utility.

=head1 SYNOPSIS

  use Win32::Unicode::File;
  
  my $file = "I \x{2665} Perl";
  
  unlinkW $file or dieW errorW;
  copyW $from, $to or dieW errorW;
  moveW $from, $to or dieW errorW;
  file_type f => $file ? 'ok' : 'no file';
  my $size = file_size $file;
  touchW $new_file;

=head1 DESCRIPTION

Win32::Unicode::Dir is Unicode string file utility.
It was a great help to the core module.

=head1 METHODS

=over

=item B<unlinkW($file)>

Like unlink.

  unlinkW $file or dieW errorW;

=item B<copyW($from, $to)>

Like File::Copy::copy.

  copyW $from, $to or dieW errorW;

=item B<moveW($from, $to)>

Like File::Copy::move.

  moveW $from, $to or dieW errorW;

=item B<renameW($from, $to)>

Alias of moveW.

=item B<touchW($file)>

Like shell command touch.

  touchW $file or dieW errorW;

=item B<file_type('attribute', $file_or_dir)>

Get windows file type

  # attributes
  f => file
  d => directory
  s => system
  r => readonly
  h => hidden
  a => archive
  n => normal
  t => temporary
  c => compressed
  o => offline
  i => not content indexed
  e => encrypted
  
  if (file_type d => $file_ro_dir) {
     # hogehoge
  }
  
  elsif (file_type fr => $file_or_dir) { # file type 'file' and 'readonly'
     # fugagufa
  }

=item B<file_size($file)>

Get file size.
near C<-s $file>

  my $size = file_size $file or dieW errorW;

=item B<filename_normalize($filename)>

Normalize the characters are not allowed in the file name.

  my $nomalized_file_name = filename_normalize($filename);

=item B<error()>

get error message.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@gmail.comE<gt>

=head1 SEE ALSO

L<Win32>
L<Win32::API>
L<Win32API::File>
L<Win32::Unicode>
L<Win32::Unicode::File>
L<Win32::Unicode::Encode>
L<Win32::Unicode::Error>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
