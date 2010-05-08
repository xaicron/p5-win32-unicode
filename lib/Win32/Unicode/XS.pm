package Win32::Unicode::XS;
use strict;
use warnings;

our $VERSION = '0.19';

use XSLoader;
XSLoader::load('Win32::Unicode', $VERSION);

our @EXPORT = grep { !/import|BEGIN|EXPORT/ && __PACAKGE__->can($_) } keys %Win32::Unicode::XS::;

1;
__END__
