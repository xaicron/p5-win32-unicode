package Win32::Unicode::File;

use strict;
use warnings;
use utf8;
use 5.008003;
use Win32API::File ();
use Carp ();
use File::Basename qw/basename/;
use Exporter 'import';
use parent qw/IO::Handle/;

use Win32::Unicode::Util;
use Win32::Unicode::Error;
use Win32::Unicode::Constant;
use Win32::Unicode::Console;
use Win32::Unicode::XS;

our @EXPORT = qw/file_type file_size copyW moveW unlinkW touchW renameW statW/;
our @EXPORT_OK = qw/filename_normalize slurp/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.22';

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

sub new {
    my $class = shift;
    $class = ref $class || $class;
    
    my $self = bless \do { local *FH }, $class;
    tie *$self, $class, $self;
    
    $self->open(@_) or return if @_;
    return $self;
}

sub open {
    my $self =shift;
    _croakW("Usage: $self->open('attrebute', 'filename')") unless @_ == 2;
    
    my $attr = shift;
    my $file = shift;
    
    $file = cygpathw($file) or return if CYGWIN;
    my $utf16_file = utf8_to_utf16(catfile $file) . NULL;
    
    if ($attr =~ s/(:.*)$//) {
        $self->binmode($1);
    }
    
    my $handle = 
        $attr eq '<' || $attr eq 'r' || $attr eq 'rb' ? _create_file(
            $utf16_file,
            GENERIC_READ,
            OPEN_EXISTING,
        ) :
        
        $attr eq '>' || $attr eq 'w' || $attr eq 'wb' ? _create_file(
            $utf16_file,
            GENERIC_WRITE,
            CREATE_ALWAYS,
        ) :
        
        $attr eq '>>' || $attr eq 'a' ? _create_file(
            $utf16_file,
            GENERIC_WRITE,
            OPEN_ALWAYS,
        ) :
        
        $attr eq '+<' || $attr eq 'r+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            OPEN_EXISTING,
        ) :
        
        $attr eq '+>' || $attr eq 'w+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            CREATE_ALWAYS,
        ) :
        
        $attr eq '+>>' || $attr eq 'a+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            OPEN_ALWAYS,
        ) :
        
        _croakW("'$attr' is unkown attribute")
    or return Win32::Unicode::Error::_set_errno;
    
    return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;
    
    *$self->{_handle} = $handle;
    $self->binmode if $attr eq 'rb' or $attr eq 'wb';
    
    $self->seek(0, 2) if $attr eq '>>' || $attr eq 'a' || $attr eq '+>>' || $attr eq 'a+';
    
    require Win32::Unicode::Dir;
    *$self->{_file_path} = File::Spec->rel2abs($file, Win32::Unicode::Dir::getcwdW());
    
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
    my $self = shift;
    if (exists *$self->{_handle}) {
        Win32API::File::CloseHandle(*$self->{_handle}) or return Win32::Unicode::Error::_set_errno;
        delete *$self->{_handle};
    }
    return 1;
}

sub getc {
    my $self = shift;
    $self->read(my $buf, 1);
    return $buf;
}

sub read {
    my $self = shift;
    my $into = \$_[0]; shift;
    my $len = shift;
#    my $offset = shift;
    
    Win32API::File::ReadFile(
        *$self->{_handle},
        my $data,
        $len,
        my $bytes_read_num,
        NULLP,
    ) or return Win32::Unicode::Error::_set_errno;
    
    $$into = $data if defined $data;
    
    if (*$self->{_encode}) {
        $$into = *$self->{_encode}->decode($$into);
    }
    
    return $bytes_read_num;
}

sub _readline {
    my $self = shift;
    
    my $encoder;
    if (*$self->{_encode}) {
        $encoder = *$self->{_encode};
        delete *$self->{_encode};
    }
    
    my $line = '';
    while (index($line, $/) == $[ -1) {
        my $char = $self->getc;
        last if not defined $char or $char eq '';
        $line .= $char;
    }
    
    $line =~ s/\r\n/\n/ unless *$self->{_binmode};
    
    if ($encoder) {
        $line = $encoder->decode($line);
        *$self->{_encode} = $encoder;
    }
    
    return $line eq '' ? () : $line;
};

sub readline {
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
    $self->write(@_);
}

sub printf {
    my $self = shift;
    my $format = shift;
    $self->write(sprintf $format, @_);
}

sub write {
    my ($self, $buff, $length, $offset) = @_;
    $offset = 0 unless defined $offset;
    
    $buff =~ s/\r?\n/\r\n/g unless *$self->{_binmode};
    $buff = *$self->{_encode}->encode($buff) if *$self->{_encode};
    
    use bytes;
    Win32API::File::WriteFile(
        *$self->{_handle},
        $buff,
        length($buff),
        my $write_size,
        NULLP,
    ) or return Win32::Unicode::Error::_set_errno;
    
    return $write_size;
}

sub seek {
    my $self = shift;
    my $low = shift;
    my $whence = shift;
    
    my $result;
    if (is64int($low)) {
        my ($pos_low, $pos_high);
        if ($low > 0) {
            $pos_low  = $low % _32INT;
            $pos_high = $low / _32INT;
        }
        else {
            $pos_low  = $low % _S32INT;
            $pos_high = $low / _S32INT;
        }
        my $st = set_file_pointer(*$self->{_handle}, $pos_low, $pos_high, $whence) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }
    else {
        my $high = 0;
        $high = ~0 if $low < 0;
        my $st = set_file_pointer(*$self->{_handle}, $low, $high, $whence) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }
}

sub tell {
    $_[0]->seek(0, 1);
}

sub flock {
    my $self = shift;
    $self = tied(*$self);
    my $ope = shift;
    
    _croakW('Usage: flock $fh, $operation') unless defined $ope;
    
    if ($ope == 1 or $ope == 2) {
        return lock_file(*$self->{_handle}, 1);
    }
    elsif ($ope == 5 or $ope == 6) {
        return lock_file(*$self->{_handle}, 0);
    }
    elsif ($ope == 8) {
        return unlock_file(*$self->{_handle});
    }
    else {
        require Errno;
        $! = Errno::EINVAL;
        return;
    }
}
*flockW = \&flock;

sub unlock {
    shift->flock(8);
}

sub slurp {
    my $self = shift;
    $self = tied(*$self);
    
    $self->seek(0, 0);
    $self->read(my $buff, $self->file_size);
    return $buff;
}

sub binmode {
    my $self = shift;
    my $layer = shift;
    
    if (not defined $layer or $layer eq 1) {
        *$self->{_binmode} = 1;
        return 1;
    }
    
    if (defined $layer) {
        if ($layer =~ /:raw/) {
            *$self->{_binmode} = 1;
        }
        
        if ($layer =~ /:(utf-?8)/i or $layer =~ /:encoding\(([^\)]+)\)/) {
            *$self->{_encode} = Encode::find_encoding($1);
        }
        
        _croakW("Unknown layer $layer") unless *$self->{_binmode} or *$self->{_encode}
    }
    
    return 1;
}

sub eof {
    my $self = shift;
    
    my $current = $self->TELL() + 0;
    my $end     = file_size($self) + 0;
    
    return $current == $end;
}

sub file_path {
    my $self = shift;
    return *$self->{_file_path};
}

# Unimplemented
sub statW {
    my $file = shift;
    _croakW('Usage: statW(filename)') unless defined $file;
    my $wantarray = wantarray;
    
    my $fi;
    if (ref $file eq __PACKAGE__) {
        $fi = get_file_information_by_handle(tied(*$file)->{_handle}) or return Win32::Unicode::Error::_set_errno;
    }
    else {
        $file = cygpathw($file) or return if CYGWIN;
        $file = catfile $file;
        return unless file_type(f => $file);
        
        my $handle = Win32API::File::CreateFileW(
            utf8_to_utf16($file) . NULL,
            GENERIC_READ,
            FILE_SHARE_READ,
            NULLP,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            NULLP,
        );
        return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;
        
        $fi = get_file_information_by_handle($handle) or return Win32::Unicode::Error::_set_errno;
        Win32API::File::CloseHandle($handle) or return Win32::Unicode::Error::_set_errno;
    }
    
    my $result = +{};
    
    # uid guid (really?)
    $result->{uid} = 0;
    $result->{gid} = 0;
    
    # inode (really?)
    $result->{ino} = 0;
    
    # block (really?)
    $result->{blksize} = '';
    $result->{blocks}  = '';
    
    # size
    $result->{size} = $fi->{size_high} ? to64int($fi->{size_high}, $fi->{size_low}) : $fi->{size_low};
    
    # ctime atime mtime
    for my $key (qw/ctime atime mtime/) {
        use bigint;
        my $etime = ($fi->{$key}{high} << 32) + $fi->{$key}{low};
        $result->{$key} = ($etime - 116444736000000000) / 10000000; # to epoch
    }
    
    return $wantarray ? (
        $result->{dev},     #  0 dev      device number of filesystem
        $result->{ino},     #  1 ino      inode number
        $result->{mode},    #  2 mode     file mode  (type and permissions)
        $result->{nlink},   #  3 nlink    number of (hard) links to the file
        $result->{uid},     #  4 uid      numeric user ID of file's owner
        $result->{gid},     #  5 gid      numeric group ID of file's owner
        $result->{rdev},    #  6 rdev     the device identifier (special files only)
        $result->{size},    #  7 size     total size of file, in bytes
        $result->{atime},   #  8 atime    last access time in seconds since the epoch
        $result->{mtime},   #  9 mtime    last modify time in seconds since the epoch
        $result->{ctime},   # 10 ctime    inode change time in seconds since the epoch (*)
        $result->{blksize}, # 11 blksize  preferred block size for file system I/O
        $result->{blocks},  # 12 blocks   actual number of blocks allocated
    ) : $result;
}

sub file_type {
    _croakW('Usage: type(attribute, file_or_dir_name)') unless @_ == 2;
    my $attr = shift;
    my $file = shift;
    $file = cygpathw($file) or return if CYGWIN;
    $file = catfile $file;
    
    my $get_attr = _get_file_type($file);
    return unless defined $get_attr;
    for (split //, $attr) {
        if ($_ eq 'f') {
            return if $get_attr & $FILE_TYPE_ATTRIBUTES{d};
            next;
        }
        
        unless (defined $FILE_TYPE_ATTRIBUTES{$_}) {
            Carp::carp "unkown attribute '$_'";
            next;
        }
        return unless $get_attr & $FILE_TYPE_ATTRIBUTES{$_};
    }
    return 1;
}

sub file_size {
    my $file = shift;
    _croakW('Usage: file_size(filename)') unless defined $file;
    
    if (ref $file eq __PACKAGE__) {
        my $self = "$file" =~ /GLOB/ ? tied *$file : $file;
        my $st = get_file_size(*$self->{_handle}) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }
    
    $file = cygpathw($file) or return if CYGWIN;
    $file = catfile $file;
    
    return unless file_type(f => $file);
    
    my $handle = Win32API::File::CreateFileW(
        utf8_to_utf16($file) . NULL,
        GENERIC_READ,
        FILE_SHARE_READ,
        NULLP,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        NULLP,
    );
    return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;
    
    my $st = get_file_size($handle) or return Win32::Unicode::Error::_set_errno;
    Win32API::File::CloseHandle($handle) or return Win32::Unicode::Error::_set_errno;
    
    return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
}

# like unix touch command
sub touchW {
    my @files = @_ ? @_ : ($_);
    my $count = 0;
    for my $file (@files) {
        $file = cygpathw($file) or return if CYGWIN;
        $file = catfile $file;
        $count += Win32::CreateFile($file) ? 1 : 0;
    }
    Win32::Unicode::Error::_set_errno unless $count;
    return $count;
}

# like CORE::unlink
sub unlinkW {
    my @files = @_ ? @_ : ($_);
    my $count = 0;
    for my $file (@files) {
        $file = cygpathw($file) or return if CYGWIN;
        $file = utf8_to_utf16(catfile $file) . NULL;
        $count += Win32API::File::DeleteFileW($file) ? 1 : 0;
    }
    Win32::Unicode::Error::_set_errno unless $count;
    return $count;
}

# like File::Copy::copy
sub copyW {
    _croakW('Usage: copyW(from, to [, over])') if @_ < 2;
    my ($from, $to) = _file_name_validete(shift, shift);
    my $over = shift || 0;
    
    $from = cygpathw($from) or return if CYGWIN;
    $to   = cygpathw($to)   or return if CYGWIN;
    
    $from = utf8_to_utf16($from) . NULL;
    $to   = utf8_to_utf16($to) . NULL;
    
    return copy_file($from, $to, !$over) ? 1 : Win32::Unicode::Error::_set_errno;
}

# move file
sub moveW {
    _croakW('Usage: moveW(from, to [, over])') if @_ < 2;
    my ($from, $to) = _file_name_validete(shift, shift);
    my $over = shift || 0;
    
    unless (move_file(utf8_to_utf16($from) . NULL, utf8_to_utf16($to) . NULL)) {
        return unless copyW($from, $to, $over);
        return unless unlinkW($from);
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
    
    if ($to =~ $back_to_dir or $to =~ $in_dir or (CYGWIN ? file_type(d => cygpathw($to)) : file_type(d => $to))) {
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
    $file = utf8_to_utf16($file) . NULL;
    my $result = get_file_attributes($file);
    if (defined $result && $result == INVALID_VALUE) {
        return Win32::Unicode::Error::_set_errno;
    }
    return $result;
}

sub _croakW {
    Win32::Unicode::Console::_row_warn(@_);
    die Carp::shortmess();
}

sub _carpW {
    Win32::Unicode::Console::_row_warn(@_);
    warn Carp::shortmess();
}

# Tie Handle
sub TIEHANDLE {
    defined $_[1] && UNIVERSAL::isa($_[1], __PACKAGE__) ? $_[1] : shift->new(@_);
}
sub OPEN     { shift->open(@_)    }
sub CLOSE    { shift->close       }
sub BINMODE  { shift->binmode(@_) }
sub PRINT    { shift->print(@_)   }
sub WRITE    { shift->write(@_)   }
sub READ     { shift->read(@_)    }
sub READLINE { shift->readline    }
sub GETC     { shift->getc        }
sub SEEK     { shift->seek(@_)    }
sub TELL     { shift->tell        }
sub EOF      { shift->eof         }
sub DESTROY  { shift->close       }

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
L<Win32API::File>
L<Win32::Unicode>
L<Win32::Unicode::File>
L<Win32::Unicode::Error>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
