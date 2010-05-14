#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

WINBASEAPI BOOL WINAPI GetFileSizeEx(HANDLE,PLARGE_INTEGER);


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

SV*
get_file_size(long handle)
    CODE:
        LARGE_INTEGER st;
        
        if (GetFileSizeEx(handle, &st) == 0) {
            XSRETURN_EMPTY;
        }
        
        SV* sv = newSV(0);
        HV* hv = newHV();
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_store(hv, "high", strlen("high"), newSVnv(st.HighPart), 0);
        hv_store(hv, "low", strlen("low"), newSVnv(st.LowPart), 0);
        
        RETVAL = sv;
    OUTPUT:
        RETVAL

int
copy_file(SV* from, SV* to, int over)
    CODE:
        STRLEN len;
        const WCHAR* from_name = SvPV_const(from, len);
        const WCHAR* to_name   = SvPV_const(to  , len);
        
        RETVAL = CopyFileW(from_name, to_name, over);
    OUTPUT:
        RETVAL

int
move_file(SV* from, SV* to)
    CODE:
        STRLEN len;
        const WCHAR* from_name = SvPV_const(from, len);
        const WCHAR* to_name   = SvPV_const(to  , len);
        
        RETVAL = MoveFileW(from_name, to_name);
    OUTPUT:
        RETVAL

SV*
set_file_pointer(long handle, long lpos, long hpos, int whence)
    CODE:
        LARGE_INTEGER mv;
        LARGE_INTEGER st;
        
        mv.LowPart  = lpos;
        mv.HighPart = hpos;
        
        if (SetFilePointerEx(handle, mv, &st, whence) == 0) {
            XSRETURN_EMPTY;
        }
        
        SV* sv = newSV(0);
        HV* hv = newHV();
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_store(hv, "high", strlen("high"), newSVnv(st.HighPart), 0);
        hv_store(hv, "low", strlen("low"), newSVnv(st.LowPart), 0);
        
        RETVAL = sv;
    OUTPUT:
        RETVAL
