#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Console    PACKAGE = Win32::Unicode::Console

PROTOTYPES: DISABLE

long
get_std_handle(long handle)
    CODE:
        RETVAL = GetStdHandle(handle);
    OUTPUT:
        RETVAL

void
write_console(long handle, SV* str)
    PPCODE:
        const WCHAR* buff = SvPV_nolen(str);
        DWORD write_size;
        
        WriteConsoleW(handle, buff, wcslen(buff), &write_size, NULL);

