#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>

MODULE = Win32::Unicode::Dir    PACKAGE  = Win32::Unicode::Dir

PROTOTYPES: DISABLE

int
create_directory(SV* dir)
    CODE:
        const WCHAR* dir_name = SvPV_nolen(dir);
        RETVAL = CreateDirectoryW(dir_name, NULL);
    OUTPUT:
        RETVAL

SV*
get_current_directory()
    CODE:
        WCHAR cur[MAX_PATH];
        
        GetCurrentDirectoryW(sizeof(cur), cur);
        RETVAL = newSVpv(cur, wcslen(cur) * 2);
    OUTPUT:
        RETVAL

int
set_current_directory(SV* dir)
    CODE:
        const WCHAR* chdir = SvPV_nolen(dir);
        
        RETVAL = SetCurrentDirectoryW(chdir);
    OUTPUT:
        RETVAL

int
remove_directory(SV* dir)
    CODE:
        const WCHAR* rmdir = SvPV_nolen(dir);
        
        RETVAL = RemoveDirectoryW(rmdir);
    OUTPUT:
        RETVAL

void
find_first_file(SV* self, SV* dir)
    CODE:
        WIN32_FIND_DATAW file_info;
        const WCHAR* opendir = SvPV_nolen(dir);
        
        HANDLE handle = FindFirstFileW(opendir, &file_info);
        
        HV* h = (HV*)SvRV(self);
        hv_stores(h, "handle", newSViv(handle));
        hv_stores(h, "first", newSVpv(file_info.cFileName, wcslen(file_info.cFileName) * 2));

SV*
find_next_file(SV* self)
    CODE:
        WIN32_FIND_DATAW file_info;
        
        HV* h = (HV*)SvRV(self);
        HANDLE handle = SvIVx(*hv_fetchs(h, "handle", 1));
        
        if(FindNextFileW(handle, &file_info) == 0) {
            XSRETURN_EMPTY;
        }
        
        RETVAL = newSVpv(file_info.cFileName, wcslen(file_info.cFileName) * 2);
    OUTPUT:
        RETVAL

int
find_close(SV* self)
    CODE:
        HV* h = (HV*)SvRV(self);
        HANDLE handle = SvIVx(*hv_fetchs(h, "handle", 1));
        RETVAL = FindClose(handle);
    OUTPUT:
        RETVAL
