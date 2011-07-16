#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#include <shellapi.h>

MODULE = Win32::Unicode::Native  PACKAGE = Win32::Unicode::Native

PROTOTYPES: DISABLE

void
parse_argv()
    CODE:
        int argc;
        int i;
        LPWSTR* args = CommandLineToArgvW(GetCommandLineW(), &argc);
        SV* sv = sv_2mortal(newSV(0));
        AV* av = sv_2mortal(newAV());
        
        sv_setsv(sv, newRV_noinc((SV*)av));
        for (i = 0; i < argc; i++) {
            av_push(av, newSVpv(args[i], wcslen(args[i]) * 2));
        }
        LocalFree(args);
        
        ST(0) = sv;
        XSRETURN(1);
