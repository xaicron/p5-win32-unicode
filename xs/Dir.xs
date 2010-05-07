#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define UNICODE
#define _UNICODE

#include <windows.h>
#include <tchar.h>

MODULE = Win32::Unicode PACKAGE = Win32::Unicode::Dir

PROTOTYPES: DISABLE

SV*
XS_getcwd()
    CODE:
        WCHAR cur[MAX_PATH];
        
        GetCurrentDirectoryW(sizeof(cur), cur);
        RETVAL = newSVpv(cur, wcslen(cur) * 2);
    OUTPUT:
        RETVAL

int
XS_chdir(SV* dir)
    CODE:
        STRLEN len;
        const WCHAR* chdir = SvPV_const(dir, len);
        
        RETVAL = SetCurrentDirectoryW(chdir);
    OUTPUT:
        RETVAL
