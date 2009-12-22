package Win32::Unicode::File;

use strict;
use warnings;
use utf8;
use 5.008001;
use Win32::API ();
use Win32API::File ();
use Carp ();
use File::Spec::Functions qw/catfile/;
use File::Basename qw/basename/;
use Exporter 'import';
use IO::Handle;
use base qw/Tie::Handle/;

use Win32::Unicode::Error;
use Win32::Unicode::Encode;
use Win32::Unicode::Constant;

our @EXPORT = qw/file_type file_size copyW moveW unlinkW touchW renameW/;
our @EXPORT_OK = qw/filename_normalize slurp/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.11';

my %FILE_TYPE_ATTRIBUTES = (
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

sub new {
	my $class = shift;
	$class = ref $class || $class;
	
	my $self = IO::Handle::new($class);
	tie *$self, $class;
	
	if (@_) {
		return unless $self->open(@_);
	}
	
	return $self;
}

sub TIEHANDLE {
	my ($class, $win32_handle) = @_;
	$class = ref $class || $class;
	
	return bless {
		_handle  => $win32_handle,
		_binmode => 0,
	}, $class;
}

sub file_name {
	my $self = shift;
	return tied(*$self)->{_file_name};
}

sub file_path {
	my $self = shift;
	return tied(*$self)->{_file_path};
}

sub win32_handle {
	my $self = shift;
	_croakW("do not open filehandle") unless defined $self->{_handle};
	return $self->{_handle};
}

sub open {
	open($_[0], $_[1], $_[2]);
}

sub OPEN {
	my $self =shift;
	_croakW("Usage: $self->open('attrebute', 'filename')") unless @_ == 2;
	my $attr = shift;
	my $file = utf8_to_utf16(catfile shift ) . NULL;
	
	if ($attr =~ s/(:.*)$//) {
		$self->BINMODE($1);
	}
	
	my $handle = 
		$attr eq '<' || $attr eq 'r' || $attr eq 'rb' ? _create_file(
			$file,
			GENERIC_READ,
			OPEN_EXISTING,
		) :
		
		$attr eq '>' || $attr eq 'w' || $attr eq 'wb' ? _create_file(
			$file,
			GENERIC_WRITE,
			CREATE_ALWAYS,
		) :
		
		$attr eq '>>' || $attr eq 'a' ? _create_file(
			$file,
			GENERIC_WRITE,
			OPEN_ALWAYS,
		) :
		
		$attr eq '+<' || $attr eq 'r+' ? _create_file(
			$file,
			GENERIC_READ | GENERIC_WRITE,
			OPEN_EXISTING,
		) :
		
		$attr eq '+>' || $attr eq 'w+' ? _create_file(
			$file,
			GENERIC_READ | GENERIC_WRITE,
			CREATE_ALWAYS,
		) :
		
		$attr eq '+>>' || $attr eq 'a+' ? _create_file(
			$file,
			GENERIC_READ | GENERIC_WRITE,
			OPEN_ALWAYS,
		) :
		
		_croakW("'$attr' is unkown attribute")
	or return;
	
	return if $handle == INVALID_VALUE;
	
	$self->{_handle} = $handle;
	$self->BINMODE if $attr eq 'rb' or $attr eq 'wb';
	
	$self->SEEK(0, 2) if $attr eq '>>' || $attr eq 'a' || $attr eq '+>>' || $attr eq 'a+';
	
	$self->{_file_name} = utf16_to_utf8($file);
	
	require Win32::Unicode::Dir;
	$self->{_file_path} = File::Spec->rel2abs($self->{_file_name}, Win32::Unicode::Dir::getcwdW());
	
	return 1;
}

sub _create_file {
	my $file = shift;
	my $type = shift;
	my $disp = shift;
	
	return Win32API::File::CreateFileW(
		$file,
		$type,
		FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULLP,
		$disp,
		FILE_ATTRIBUTE_NORMAL,
		NULLP,
	);
}

sub close {
	close($_[0]);
}

sub CLOSE {
	my $self = shift;
	Win32API::File::CloseHandle($self->win32_handle);
	delete $self->{_handle};
}

sub getc {
	getc($_[0]);
}

sub read {
	read($_[0], $_[1], $_[2], $_[3]);
}

sub READ {
	my $self = shift;
	my $into = \$_[0]; shift;
	my $len = shift;
#	my $offset = shift;
	
	my $result = Win32API::File::ReadFile(
		$self->win32_handle,
		my $data,
		$len,
		my $bytes_read_num,
		NULLP,
	);
	
	$$into = $data if defined $data;
	
	if ($self->{_encode}) {
		$$into = $self->{_encode}->decode($$into);
	}
	
	return $bytes_read_num;
}

sub readline {
	my $self = shift;
	readline $self;
}

sub _readline {
	my $self = shift;
	
	my $encoder;
	if ($self->{_encode}) {
		$encoder = $self->{_encode};
		delete $self->{_encode};
	}
	
	my $line = '';
	while (index($line, $/) == $[ -1) {
		my $char = $self->GETC();
		last if not defined $char or $char eq '';
		$line .= $char;
	}
	
	$line =~ s/\r\n/\n/ unless $self->{_binmode};
	
	if ($encoder) {
		$line = $encoder->decode($line);
		$self->{_encode} = $encoder;
	}
	
	return $line eq '' ? undef : $line;
};

sub READLINE {
	my $self = shift;
	
	if (wantarray) {
		my @lines;
		while (my $line = $self->_readline) {
			push @lines, $line;
		}
		return @lines;
	}
	else {
		return $self->_readline;
	}
}

sub print {
	my $self = shift;
	tied(*$self)->write(@_);
}

sub printf {
	my $self = shift;
	my $format = shift;
	tied(*$self)->write(sprintf $format, @_);
}

sub write {
	my $self = shift;
	print {$self} @_;
}

sub WRITE {
	my ($self, $buff, $length, $offset) = @_;
	$offset = 0 unless defined $offset;
	
	$buff =~ s/\r?\n/\r\n/g unless $self->{_binmode};
	$buff = $self->{_encode}->encode($buff) if $self->{_encode};
	
	use bytes;
	Win32API::File::WriteFile(
		$self->win32_handle,
		$buff,
		length($buff),
		my $write_size,
		NULLP,
	);
	
	return $write_size;
}

sub seek {
	seek($_[0], $_[1], $_[2]);
}

sub SEEK {
	my $self = shift;
	my $low = shift;
	my $whence = shift;
	
	my $high = 0;
	$high = ~0 if $low < 0;
	
	Win32API::File::SetFilePointer($self->win32_handle, $low, $high, $whence);
}

sub tell {
	tell($_[0]);
}

sub TELL {
	return $_[0]->SEEK(0, 1);
}

#sub flock {
#
#}
#
#sub unlock {
#
#}

sub slurp {
	my $self = shift;
	$self = tied(*$self);
	
	my $size = Win32API::File::getFileSize($self->win32_handle) + 0;
	$self->SEEK(0, 0);
	$self->READ(my $buff, $size);
	return $buff;
}

sub binmode {
	binmode($_[0], $_[1]);
}

sub BINMODE {
	my $self = shift;
	my $layer = shift;
	
	if (not defined $layer or $layer eq 1) {
		$self->{_binmode} = 1;
		return 1;
	}
	
	if (defined $layer) {
		if ($layer =~ /:raw/) {
			$self->{_binmode} = 1;
		}
		
		if ($layer =~ /:(utf-?8)/i or $layer =~ /:encoding\(([^\)]+)\)/) {
			$self->{_encode} = Encode::find_encoding($1);
		}
		
		_croakW("Unknown layer $layer") unless $self->{_binmode} or $self->{_encode}
	}
	
	return 1;
}

sub eof {
	eof($_[0]);
}

sub EOF {
	my $self = shift;
	
	my $current = $self->TELL() + 0;
	my $end     = Win32API::File::getFileSize($self->win32_handle) + 0;
	
	return $current == $end;
}

#sub stat {
#
#}

sub file_type {
	_croakW('Usage: type(attribute, file_or_dir_name)') unless @_ == 2;
	my $attr = shift;
	my $file = catfile shift;
	
	my $get_attr = _get_file_type($file);
	for (split //, $attr) {
		if ($_ eq 'f') {
			return 0 unless _is_file($file);
			next;
		}
		
		unless (defined $FILE_TYPE_ATTRIBUTES{$_}) {
			Carp::carp "unkown attribute '$_'";
			next;
		}
		return 0 unless $get_attr & $FILE_TYPE_ATTRIBUTES{$_};
	}
	return 1;
}

sub file_size {
	my $file = shift;
	_croakW('Usage: file_size(filename)') unless defined $file;
	
	if (ref $file eq __PACKAGE__) {
		return Win32API::File::getFileSize(tied(*$file)->win32_handle) + 0;
	}
	
	$file = catfile $file;
	
	unless (file_type(f => $file)) {
#		_carpW("$file is not the file");
		return;
	}
	
	my $handle = Win32API::File::CreateFileW(
		utf8_to_utf16($file) . NULL,
		GENERIC_READ,
		FILE_SHARE_READ,
		NULLP,
		OPEN_EXISTING,
		FILE_ATTRIBUTE_NORMAL,
		NULLP,
	);
	
	return if $handle == INVALID_VALUE;
	
	my $size = Win32API::File::getFileSize($handle);
	Win32API::File::CloseHandle($handle);
	
	if ($size == INVALID_VALUE) {
		warn 'Could not get file size - ' . errorW;
		return;
	}
	
	return $size;
}

# like unix touch command
sub touchW {
	my $file = shift;
	_croakW('Usage: touchW(filename)') unless defined $file;
	$file = catfile $file;
	return Win32::CreateFile($file) ? 1 : 0;
}

# like CORE::unlink
sub unlinkW {
	my $file = shift;
	_croakW('Usage: unlinkW(filename)') unless defined $file;
	$file = utf8_to_utf16(catfile $file) . NULL;
	return Win32API::File::DeleteFileW($file) ? 1 : 0;
}

# like File::Copy::copy
sub copyW {
	_croakW('Usage: copyW(from, to [, over])') if @_ < 2;
	my ($from, $to) = _file_name_validete(shift, shift);
	my $over = shift || 0;
	
	$from = utf8_to_utf16($from) . NULL;
	$to   = utf8_to_utf16($to) . NULL;
	
	return $CopyFile->Call($from, $to, !$over) ? 1 : 0;
}

# move file
sub moveW {
	_croakW('Usage: moveW(from, to [, over])') if @_ < 2;
	my ($from, $to) = _file_name_validete(shift, shift);
	my $over = shift || 0;
	
	unless ($MoveFile->Call(utf8_to_utf16($from) . NULL, utf8_to_utf16($to) . NULL)) {
		return 0 unless copyW($from, $to, $over);
		return 0 unless unlinkW($from);
	};
	
	return 1;
}
*renameW = \&moveW;

my $back_to_dir = qr/^\.\.$/;
my $in_dir      = qr#[\\/]$#;

sub _file_name_validete {
	_croakW('from is a undefined values') unless defined $_[0];
	_croakW('to is a undefined values')   unless defined $_[1];
	
	my $from = catfile shift;
	my $to = shift;
	
	if ($to =~ $back_to_dir or $to =~ $in_dir or file_type(d => $to)) {
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
	_croakW('Usage: filename_nomalize($file_name)') unless defined $file_name;
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
		return 1 unless _is_dir($file);
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

sub _carpW {
	Win32::Unicode::Console::_row_warn(@_);
	warn Carp::shortmess();
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

=head1 METHODS

=over

=item B<new([$mode, $file_name])>

  my $fh = Win32::Unicode::File->new;
  my $fh = Win32::Unicode::File->new($mode, $file_name); # open $file_name;

=item B<open($mode, $file_name)>

  $fh->open('<', $file_name) or dieW errorW;
  
  open $fh, '<', $file_name or dieW errorW;

  # be useful mode
  <   = r   = rb
  >   = w   = wb
  >>  = a
  +<  = r+
  +>  = w+
  +>> = a+
  
=item B<close()>

  $fh->close;

  close $fh;

=item B<read($buff, $len)>

  $fh->read(my $buff, $len) or dieW errorW;
  print $buff;
  
  read $fh, my $buff, $len;

=item B<readline()>

  my $line = $fh->readline;
  my @line = $fh->readline;
  
  my $line = readline $fh;
  my @line = <$fh>;
  
=item B<print(@str)>

  $fh->print(@str);
  print $fh @str;
  
=item B<printf($format, @str)>

  $fh->printf('[%s]', $str);
  printf $fh '%d', $str;

=item B<write(@str)>

  $fh->write(@str);
  
=item B<seek($ofset, $whence)>

  $fh->seek(10, 1);
  
  seek $fh, 1024, 2;
  
=item B<tell()>

  my $current = $fh->tell();
  
  my $current = tell $fh;

=item B<slurp()>

  my $data = $fh->slurp;
  
=item B<eof()>

  if ($fh->eof) {
     # ...snip
  }

or

  if (eof $fh) {
     # ...snip
  }

=item B<binmode($layer)>

  $fh->binmode(':encoding(cp932)')
  
or

  binmode $fh, ':raw :utf8';
  
Currently available now is only the layer below.

  :raw
  :utf8
  :encoding(foo)

=item B<error()>

get error message.

  $fh->error;

=back

=head1 FUNCTIONS

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

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

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
