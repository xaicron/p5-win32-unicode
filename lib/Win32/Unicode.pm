package Win32::Unicode;

use strict;
use warnings;
use 5.008003;
use Exporter ();

our $VERSION = '0.17';

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
	console => $Win32::Unicode::Console::EXPORT_TAGS{all},
	file    => $Win32::Unicode::File::EXPORT_TAGS{all},
	dir     => $Win32::Unicode::Dir::EXPORT_TAGS{all},
	error   => $Win32::Unicode::Error::EXPORT_TAGS{all},
	all     => [@EXPORT, @EXPORT_OK],
);

sub import {
	my $class = shift;
	my $caller = caller(0);
	
	my @args;
	for my $arg (@_) {
		if ($arg eq '-native') {
			require Win32::Unicode::Native;
			no strict 'refs';
			map {
				*{"$caller\::$_"} = \&{"Win32::Unicode::Native::$_"};
			} @Win32::Unicode::Native::EXPORT;
		}
		else {
			push @args, $arg;
		}
	}
	
	local $Exporter::ExportLevel = 1;
	Exporter::import($class, @args);
}

1;
__END__
=head1 NAME

Win32::Unicode.pm - perl unicode-friendly wrapper for win32api.

=head1 SYNOPSIS

  use Win32::Unicode;
  use utf8;
  
  # unicode console out
  printW "I \x{2665} Perl";
  
  # unicode file util
  unlinkW $file or dieW errorW;
  copyW $from, $to or dieW errorW;
  moveW $from, $to or dieW errorW;
  file_type f => $file ? 'ok' : 'no file';
  my $size = file_size $file;
  touchW $new_file;
  
  # unicode directory util
  mkdirW $dir or dieW errorW;
  rmdirW $dir or dieW errorW;
  my $cwd = getcwdW;
  chdirW $change_dir;
  findW sub { sayW $_ }, $dir;
  finddepthW sub { sayW $_ }, $dir;
  mkpathW $long_path_dir_name;
  rmtreeW $tree;
  cptreeW $from, $to
  mvtreeW $from, $to;
  my $dir_size = dir_size $dir;
  
  # opendir
  my $wdir = Win32::Unicode::Dir->new;
  $wdir->open($dir) || die $wdir->error;
  for ($wdir->fetch) {
      next if /^\.{1,2}$/;
      
      my $full_path = "$dir/$_";
      if (file_type('f', $full_path)) {
          # $_ is file
      }
      
      elsif (file_type('d', $full_path))
          # $_ is directory
      }
  }
  $wdir->close || die $wdir->error;

=head1 DESCRIPTION

Wn32::Unicode is a perl unicode-friendly wrapper for win32api.
This module many functions import :P.

Many features easy to use Perl because I think it looks identical to the standard function.

=head1 OPTION

Switch L<Win32::Unicode::Native>.

  use Win32::Unicode '-native'; # eq use Win32::Unicode::Native

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Unicode::Console>
L<Win32::Unicode::Dir>
L<Win32::Unicode::File>
L<Win32::Unicode::Error>
L<Win32>
L<Win32::API>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
