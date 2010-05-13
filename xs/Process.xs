#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Process  PACKAGE = Win32::Unicode::Process

PROTOTYPES: DISABLE

long
wait_for_single_object(long handle)
    CODE:
        RETVAL = WaitForSingleObject(handle, INFINITE);
    OUTPUT:
        RETVAL
