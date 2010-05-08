#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::File   PACKAGE = Win32::Unicode::File

PROTOTYPES: DISABLE

long
get_file_attributes(SV* file)
    CODE:
        STRLEN len;
        const WCHAR* file_name = SvPV_const(file, len);
        RETVAL = GetFileAttributesW(file_name);
    OUTPUT:
        RETVAL
