#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/stat.h>
#include <sys/types.h>
#include <windows.h>

#ifdef __CYGWIN__
#define _STAT(file, st) stat(file, st)
#else
#define _STAT(file, st) _wstat(file, st)
#endif

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
get_stat_data(SV* file, long handle)
    CODE:
        struct stat st;
        BY_HANDLE_FILE_INFORMATION fi;
        SV* hr = newSV(0);
        HV* hv = newHV();
        const WCHAR* file_name = SvPV_nolen(file);
        
        if (_STAT(file_name, &st) != 0) {
            XSRETURN_EMPTY;
        }
        
        if (GetFileInformationByHandle(handle, &fi) == 0) {
            XSRETURN_EMPTY;
        }
        
        sv_setsv(hr, sv_2mortal(newRV_noinc((SV*)hv)));
        hv_stores(hv, "dev", newSVnv(st.st_dev));
        hv_stores(hv, "ino", newSVnv(st.st_ino));
        hv_stores(hv, "mode", newSViv(st.st_mode));
        hv_stores(hv, "nlink", newSViv(st.st_nlink));
        hv_stores(hv, "uid", newSVnv(st.st_uid));
        hv_stores(hv, "gid", newSVnv(st.st_gid));
        hv_stores(hv, "rdev", newSVnv(st.st_rdev));
        hv_stores(hv, "atime", newSVnv(st.st_atime));
        hv_stores(hv, "mtime", newSVnv(st.st_mtime));
        hv_stores(hv, "ctime", newSVnv(st.st_ctime));
#ifdef __CYGWIN__
        hv_stores(hv, "blksize", newSVnv(st.st_blksize));
        hv_stores(hv, "blocks", newSVnv(st.st_blocks));
#endif
        hv_stores(hv, "size_high", newSVnv(fi.nFileSizeHigh));
        hv_stores(hv, "size_low", newSVnv(fi.nFileSizeLow));
        
        RETVAL = hr;
    OUTPUT:
        RETVAL

int
lock_file(long handle, int ope)
    CODE:
        long option = 0;
        OVERLAPPED ol;
        ol.Offset = 0;
        ol.OffsetHigh = 0;
        
        switch(ope) {
            case 1:
                break;
            case 2:
                option = LOCKFILE_EXCLUSIVE_LOCK;
                break;
            case 5:
                option = LOCKFILE_FAIL_IMMEDIATELY;
                break;
            case 6:
                option = LOCKFILE_FAIL_IMMEDIATELY | LOCKFILE_EXCLUSIVE_LOCK;
                break;
            default:
                XSRETURN_EMPTY;
                break;
        }
        
        RETVAL = LockFileEx(handle, option, 0, 0xFFFFFFFF, 0xFFFFFFFF, &ol);
    OUTPUT:
        RETVAL

int
unlock_file(long handle)
    CODE:
        OVERLAPPED ol;
        ol.Offset = 0;
        ol.OffsetHigh = 0;
        
        RETVAL = UnlockFileEx(handle, 0, 0xFFFFFFFF, 0xFFFFFFFF, &ol);
    OUTPUT:
        RETVAL
