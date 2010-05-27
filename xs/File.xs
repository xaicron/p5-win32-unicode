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
        SV* sv = newSV(0);
        HV* hv = newHV();
        
        if (GetFileSizeEx(handle, &st) == 0) {
            XSRETURN_EMPTY;
        }
        
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
        SV* sv = newSV(0);
        HV* hv = newHV();
        
        mv.LowPart  = lpos;
        mv.HighPart = hpos;
        
        if (SetFilePointerEx(handle, mv, &st, whence) == 0) {
            XSRETURN_EMPTY;
        }
        
        sv_setsv(sv, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_store(hv, "high", strlen("high"), newSVnv(st.HighPart), 0);
        hv_store(hv, "low", strlen("low"), newSVnv(st.LowPart), 0);
        
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
        hv_store(chv, "high", strlen("high"), newSVnv(fi.ftCreationTime.dwHighDateTime), 0);
        hv_store(chv, "low", strlen("low"), newSVnv(fi.ftCreationTime.dwLowDateTime), 0);
        
        /* set atime */
        sv_setsv(ahr, sv_2mortal(newRV_noinc((SV*)ahv)));
        hv_store(ahv, "high", strlen("high"), newSVnv(fi.ftLastAccessTime.dwHighDateTime), 0);
        hv_store(ahv, "low", strlen("low"), newSVnv(fi.ftLastAccessTime.dwLowDateTime), 0);
        
        /* set mtime */
        sv_setsv(mhr, sv_2mortal(newRV_noinc((SV*)mhv)));
        hv_store(mhv, "high", strlen("high"), newSVnv(fi.ftLastWriteTime.dwHighDateTime), 0);
        hv_store(mhv, "low", strlen("low"), newSVnv(fi.ftLastWriteTime.dwLowDateTime), 0);
        
        sv_setsv(hr, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_store(hv, "size_high", strlen("size_high"), newSVnv(fi.nFileSizeHigh), 0);
        hv_store(hv, "size_low", strlen("size_low"), newSVnv(fi.nFileSizeLow), 0);
        hv_store(hv, "ctime", strlen("ctime"), chr, 0);
        hv_store(hv, "atime", strlen("atime"), ahr, 0);
        hv_store(hv, "mtime", strlen("mtime"), mhr, 0);
        hv_store(hv, "dev", strlen("dev"), newSVnv(fi.dwVolumeSerialNumber), 0);
        
        RETVAL = hr;
    OUTPUT:
        RETVAL
