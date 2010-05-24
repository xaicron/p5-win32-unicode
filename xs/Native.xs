#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#include <shellapi.h>

MODULE = Win32::Unicode::Native  PACKAGE = Win32::Unicode::Native

PROTOTYPES: DISABLE

SV*
parse_argv()
    CODE:
        int argc;
        int i;
        
        LPWSTR* args = CommandLineToArgvW(GetCommandLineW(), &argc);
        
        SV* sv = newSV(0);
        AV* av = newAV();
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)av)));
        for (i = 0; i < argc; i++) {
            av_push(av, newSVpv(args[i], wcslen(args[i]) * 2));
        }
        LocalFree(args);
        
        RETVAL = sv;
    OUTPUT:
        RETVAL
