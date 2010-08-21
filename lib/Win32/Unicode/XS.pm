package Win32::Unicode::XS;
use strict;
use warnings;

our $VERSION = '0.24';

use XSLoader;
XSLoader::load('Win32::Unicode', $VERSION);

1;
__END__
