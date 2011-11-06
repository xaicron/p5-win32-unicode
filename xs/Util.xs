#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Util   PACKAGE = Win32::Unicode::Util

PROTOTYPES: DISABLE

int
close_handle(long handle)
    CODE:
        RETVAL = CloseHandle(handle);
    OUTPUT:
        RETVAL
