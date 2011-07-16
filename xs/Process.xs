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

long
wait_for_input_idle(long handle)
    CODE:
        RETVAL = WaitForInputIdle(handle, INFINITE);
    OUTPUT:
        RETVAL

void
create_process(SV* shell, SV* cmd)
    CODE:
        const WCHAR*        cshell = SvPV_nolen(shell);
        WCHAR*              ccmd = SvPV_nolen(cmd);
        STARTUPINFOW        si;
        PROCESS_INFORMATION pi;
        SV* sv = sv_2mortal(newSV(0));
        HV* hv = sv_2mortal(newHV());
        
        ZeroMemory(&si,sizeof(si));
        si.cb=sizeof(si);
        
        if (CreateProcessW(
            cshell,
            ccmd,
            NULL,
            NULL,
            FALSE,
            NORMAL_PRIORITY_CLASS,
            NULL,
            NULL,
            &si,
            &pi
        ) == 0) {
            XSRETURN_EMPTY;
        }
        
        sv_setsv(sv, newRV_noinc((SV*)hv));
        hv_stores(hv, "thread_handle", newSViv(pi.hThread));
        hv_stores(hv, "process_handle", newSViv(pi.hProcess));
        
        ST(0) = sv;
        XSRETURN(1);

long
get_exit_code(long handle)
    CODE:
        DWORD exit_code;
        if (GetExitCodeProcess(handle, &exit_code) == 0) {
            XSRETURN_EMPTY;
        }
        RETVAL = exit_code;
    OUTPUT:
        RETVAL
