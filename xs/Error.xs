#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Error  PACKAGE = Win32::Unicode::Error

PROTOTYPES: DISABLE

long
get_last_error()
    CODE:
        RETVAL = GetLastError();
    OUTPUT:
        RETVAL
