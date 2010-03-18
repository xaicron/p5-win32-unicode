package Win32::Unicode::Constant;

use strict;
use warnings;
use Carp ();
use Exporter 'import';

our $VERISON = '0.15';
our @EXPORT = grep { !/import|BEGIN|EXPORT/ && Win32::Unicode::Constant->can($_) } keys %Win32::Unicode::Constant::;

sub NULL     () { "\x00" }
sub NULLP    () { [] }
sub MAX_PATH () { 520 }
sub BUFF     () { NULL x (MAX_PATH + 1) }

# console
sub STD_INPUT_HANDLE      () { -10 }
sub STD_OUTPUT_HANDLE     () { -11 }
sub STD_ERROR_HANDLE      () { -12 }
sub MAX_BUFFER_SIZE       () { 20000 }
sub CONSOLE_OUTPUT_HANDLE () { +{7 => 1, 11 => 1} }
sub CONSOLE_ERROR_HANDLE  () { +{11 => 1, 15 => 1} }

# file attribute
sub FILE_ATTRIBUTE_READONLY            () { 0x00000001 }
sub FILE_ATTRIBUTE_HIDDEN              () { 0x00000002 }
sub FILE_ATTRIBUTE_SYSTEM              () { 0x00000004 }
sub FILE_ATTRIBUTE_DIRECTORY           () { 0x00000010 }
sub FILE_ATTRIBUTE_ARCHIVE             () { 0x00000020 }
sub FILE_ATTRIBUTE_NORMAL              () { 0x00000080 }
sub FILE_ATTRIBUTE_TEMPORARY           () { 0x00000100 }
sub FILE_ATTRIBUTE_COMPRESSED          () { 0x00000800 }
sub FILE_ATTRIBUTE_OFFLINE             () { 0x00001000 }
sub FILE_ATTRIBUTE_ENCRYPTED           () { 0x00004000 }
sub FILE_ATTRIBUTE_NOT_CONTENT_INDEXED () { 0x00002000 }
sub INVALID_VALUE                      () { -1 };

sub ERROR_NO_MORE_FILES  () { 18 }
sub INVALID_HANDLE_VALUE () { -1 }

# create file type
sub GENERIC_READ    () { 0x80000000 }
sub GENERIC_WRITE   () { 0x40000000 }
sub GENERIC_EXECUTE () { 0x20000000 }

# share mode
sub FILE_SHARE_READ   () { 0x00000001 }
sub FILE_SHARE_WRITE  () { 0x00000002 }
sub FILE_SHARE_DELETE () { 0x00000004 }

# file open type
sub CREATE_NEW        () { 1 }
sub CREATE_ALWAYS     () { 2 }
sub OPEN_EXISTING     () { 3 }
sub OPEN_ALWAYS       () { 4 }
sub TRUNCATE_EXISTING () { 5 }

# format message
sub FORMAT_MESSAGE_ALLOCATE_BUFFER () { 0x00000100 }
sub FORMAT_MESSAGE_ARGUMENT_ARRAY  () { 0x00002000 }
sub FORMAT_MESSAGE_FROM_HMODULE    () { 0x00000800 }
sub FORMAT_MESSAGE_FROM_STRING     () { 0x00000400 }
sub FORMAT_MESSAGE_FROM_SYSTEM     () { 0x00001000 }
sub FORMAT_MESSAGE_IGNORE_INSERTS  () { 0x00000200 }
sub FORMAT_MESSAGE_MAX_WIDTH_MASK  () { 255 * 2 }

sub LANG_NEUTRAL    () { 0x00 }
sub SUBLANG_DEFAULT () { 0x01 }
sub LANG_USER_DEFAULT () { SUBLANG_DEFAULT << 10 | LANG_NEUTRAL }

1;
__END__
