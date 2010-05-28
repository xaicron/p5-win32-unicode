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
        const WCHAR* file_name = SvPV_nolen(file);
        RETVAL = GetFileAttributesW(file_name);
    OUTPUT:
        RETVAL

SV*
get_file_size(long handle)
    CODE:
        LARGE_INTEGER st;
        SV* sv = newSV(0);
        HV* hv = newHV();
        
        if (GetFileSizeEx(handle, &st) == 0) {
            XSRETURN_EMPTY;
        }
        
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_stores(hv, "high", newSVnv(st.HighPart));
        hv_stores(hv, "low", newSVnv(st.LowPart));
        
        RETVAL = sv;
    OUTPUT:
        RETVAL

int
copy_file(SV* from, SV* to, int over)
    CODE:
        const WCHAR* from_name = SvPV_nolen(from);
        const WCHAR* to_name   = SvPV_nolen(to);
        
        RETVAL = CopyFileW(from_name, to_name, over);
    OUTPUT:
        RETVAL

int
move_file(SV* from, SV* to)
    CODE:
        const WCHAR* from_name = SvPV_nolen(from);
        const WCHAR* to_name   = SvPV_nolen(to);
        
        RETVAL = MoveFileW(from_name, to_name);
    OUTPUT:
        RETVAL

SV*
set_file_pointer(long handle, long lpos, long hpos, int whence)
    CODE:
        LARGE_INTEGER mv;
        LARGE_INTEGER st;
        SV* sv = newSV(0);
        HV* hv = newHV();
        
        mv.LowPart  = lpos;
        mv.HighPart = hpos;
        
        if (SetFilePointerEx(handle, mv, &st, whence) == 0) {
            XSRETURN_EMPTY;
        }
        
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_stores(hv, "high", newSVnv(st.HighPart));
        hv_stores(hv, "low", newSVnv(st.LowPart));
        
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV*
get_file_information_by_handle(long handle)
    CODE:
        BY_HANDLE_FILE_INFORMATION fi;
        SV* hr  = newSV(0);
        HV* hv  = newHV();
        SV* chr = newSV(0);
        HV* chv = newHV();
        SV* ahr = newSV(0);
        HV* ahv = newHV();
        SV* mhr = newSV(0);
        HV* mhv = newHV();
        
        if (GetFileInformationByHandle(handle, &fi) == 0) {
            XSRETURN_EMPTY;
        }
        
        /* set ctime */
        sv_setsv(chr, sv_2mortal(newRV_noinc((SV*)chv)));
        hv_stores(chv, "high", newSVnv(fi.ftCreationTime.dwHighDateTime));
        hv_stores(chv, "low", newSVnv(fi.ftCreationTime.dwLowDateTime));
        
        /* set atime */
        sv_setsv(ahr, sv_2mortal(newRV_noinc((SV*)ahv)));
        hv_stores(ahv, "high", newSVnv(fi.ftLastAccessTime.dwHighDateTime));
        hv_stores(ahv, "low", newSVnv(fi.ftLastAccessTime.dwLowDateTime));
        
        /* set mtime */
        sv_setsv(mhr, sv_2mortal(newRV_noinc((SV*)mhv)));
        hv_stores(mhv, "high", newSVnv(fi.ftLastWriteTime.dwHighDateTime));
        hv_stores(mhv, "low", newSVnv(fi.ftLastWriteTime.dwLowDateTime));
        
        sv_setsv(hr, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_stores(hv, "size_high", newSVnv(fi.nFileSizeHigh));
        hv_stores(hv, "size_low", newSVnv(fi.nFileSizeLow));
        hv_stores(hv, "ctime", chr);
        hv_stores(hv, "atime", ahr);
        hv_stores(hv, "mtime", mhr);
        hv_stores(hv, "dev", newSVnv(fi.dwVolumeSerialNumber));
        
        RETVAL = hr;
    OUTPUT:
        RETVAL
