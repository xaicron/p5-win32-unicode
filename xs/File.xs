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
    #define _UTIME(file, st) utime(file, st)
#else
    #define _STAT(file, st) _wstat(file, st)
    #define _UTIME(file, st) _wutime(file, st)
#endif

#ifndef PERL_STATIC_INLINE
    #define PERL_STATIC_INLINE static inline
#endif

#ifndef Zero
    #define Zero(d,n,t) memset((void *)(d), 0, (n) * sizeof(t))
#endif

WINBASEAPI BOOL WINAPI GetFileSizeEx(HANDLE,PLARGE_INTEGER);

#if (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5))
PERL_STATIC_INLINE time_t translate_ft_to_time_t(FILETIME ft) {
    SYSTEMTIME st;
    struct tm pt;
    time_t retval;
    dTHX;

    if (! FileTimeToSystemTime(&ft, &st)) {
        return -1;
    }

    Zero(&pt, 1, struct tm);
    pt.tm_year = st.wYear - 1900;
    pt.tm_mon = st.wMonth - 1;
    pt.tm_mday = st.wDay;
    pt.tm_hour = st.wHour;
    pt.tm_min = st.wMinute;
    pt.tm_sec = st.wSecond;

#ifdef MKTIME_LOCK
    MKTIME_LOCK;
#endif
    retval = _mkgmtime(&pt);
#ifdef MKTIME_UNLOCK
    MKTIME_UNLOCK;
#endif

    return retval;
}
#endif /* (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5)) */

MODULE = Win32::Unicode::File   PACKAGE = Win32::Unicode::File

PROTOTYPES: DISABLE

HANDLE
create_file(WCHAR *filename, long amode, long smode, long opt, long attr)
    CODE:
        RETVAL = CreateFileW(
            filename,
            amode,
            smode,
            NULL,
            opt,
            attr,
            NULL
        );
    OUTPUT:
        RETVAL

void
win32_read_file(HANDLE handle, DWORD count)
    CODE:
        char  *ptr, *buff;
        bool  has_error = 0;
        DWORD len       = 0;

        Newxz(ptr, count + 1, char);
        buff = ptr;
        if (!ReadFile(handle, buff, count, &len, NULL)) {
            if (GetLastError() != NO_ERROR) {
                has_error = 1;
            }
            else {
                len = 0;
            }
        }
        buff[len] = '\0';

        ST(0) = has_error ? sv_2mortal(newSViv(-1)) : sv_2mortal(newSVuv(len));
        ST(1) = sv_2mortal(newSVpvn(buff, len));

        Safefree(ptr);
        XSRETURN(2);

SV *
win32_write_file(HANDLE handle, char *buff, DWORD size)
    CODE:
        bool has_error = 0;
        DWORD len;
        if (!WriteFile(handle, buff, size, &len, NULL)) {
            if (GetLastError() != NO_ERROR) {
                has_error = 1;
            }
            else {
                len = 0;
            }
        }

        RETVAL = has_error ? newSViv(-1) : newSVuv(len);
    OUTPUT:
        RETVAL

bool
win32_flush_file_buffers(HANDLE handle)
    CODE:
        RETVAL = FlushFileBuffers(handle);
    OUTPUT:
        RETVAL

bool
delete_file(WCHAR *filename)
    CODE:
        RETVAL = DeleteFileW(filename);
    OUTPUT:
        RETVAL

long
get_file_attributes(WCHAR *filename)
    CODE:
        RETVAL = GetFileAttributesW(filename);
    OUTPUT:
        RETVAL

void
get_file_size(HANDLE handle)
    CODE:
        LARGE_INTEGER st;
        HV* hv    = newHV();
        SV* hvref = sv_2mortal(newRV_noinc((SV *)hv));

        if (GetFileSizeEx(handle, &st) == 0) {
            XSRETURN_EMPTY;
        }

        hv_stores(hv, "high", newSVnv(st.HighPart));
        hv_stores(hv, "low", newSVnv(st.LowPart));

        ST(0) = hvref;
        XSRETURN(1);

bool
copy_file(WCHAR *from, WCHAR *to, bool over)
    CODE:
        RETVAL = CopyFileW(from, to, over);
    OUTPUT:
        RETVAL

bool
move_file(WCHAR *from, WCHAR *to)
    CODE:
        RETVAL = MoveFileW(from, to);
    OUTPUT:
        RETVAL

void
set_file_pointer(HANDLE handle, long lpos, long hpos, int whence)
    CODE:
        LARGE_INTEGER mv;
        LARGE_INTEGER st;
        HV* hv    = newHV();
        SV* hvref = sv_2mortal(newRV_noinc((SV *)hv));

        mv.LowPart  = lpos;
        mv.HighPart = hpos;

        if (SetFilePointerEx(handle, mv, &st, whence) == 0) {
            XSRETURN_EMPTY;
        }

        hv_stores(hv, "high", newSVnv(st.HighPart));
        hv_stores(hv, "low", newSVnv(st.LowPart));

        ST(0) = hvref;
        XSRETURN(1);

void
get_stat_data(WCHAR *filename, HANDLE handle, bool is_dir)
    CODE:
        struct _stat st;
        BY_HANDLE_FILE_INFORMATION fi;
        HV* hv    = newHV();
        SV* hvref = sv_2mortal(newRV_noinc((SV *)hv));
#if (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5))
        Stat_t St;
        HANDLE dirhandle;
        DWORD type;
        BOOL isstdhandle;
#endif

        if (_STAT(filename, &st) != 0) {
            XSRETURN_EMPTY;
        }
#if (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5))
        Zero(&St, 1, Stat_t);
        /* Semantic of perl's stat changed in 5.33.5 */
        /* C.f. https://github.com/Perl/perl5/commit/e935ef333b3eab54a766de93fad1369f76ddea49 */
        /* In addition st.ino is on 64bits */
        if (is_dir) {
            dirhandle = CreateFileW(filename, FILE_READ_ATTRIBUTES, FILE_SHARE_DELETE | FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
            if (dirhandle == INVALID_HANDLE_VALUE) {
                XSRETURN_EMPTY;
            }
            type = GetFileType(dirhandle);
            type &= ~FILE_TYPE_REMOTE;
            if ((type == FILE_TYPE_DISK) && (GetFileInformationByHandle(dirhandle, &fi) == 0)) {
                CloseHandle(dirhandle);
                XSRETURN_EMPTY;
            }
            isstdhandle = 0;
            CloseHandle(dirhandle);
        } else {
            type = GetFileType(handle);
            type &= ~FILE_TYPE_REMOTE;
            if ((type == FILE_TYPE_DISK) && (GetFileInformationByHandle(handle, &fi) == 0)) {
                XSRETURN_EMPTY;
            }
            isstdhandle = (handle == GetStdHandle(STD_INPUT_HANDLE) || handle == GetStdHandle(STD_OUTPUT_HANDLE) || handle == GetStdHandle(STD_ERROR_HANDLE)) ? 1 : 0;
        }

        switch (type) {
        case FILE_TYPE_DISK:
            St.st_dev = fi.dwVolumeSerialNumber;
            St.st_ino = fi.nFileIndexHigh;
            St.st_ino <<= 32;
            St.st_ino |= fi.nFileIndexLow;
            if (fi.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                St.st_mode = _S_IFDIR | _S_IREAD | _S_IEXEC;
                /* duplicate the logic from the end of the old win32_stat() */
                if (!(fi.dwFileAttributes & FILE_ATTRIBUTE_READONLY)) {
                    St.st_mode |= S_IWRITE;
                }
            }
            else {
                size_t len = wcslen(filename);
                St.st_mode = _S_IFREG;
                if (len > 4 &&
                    (_wcsicmp(filename + len - 4, L".exe") == 0 ||
                     _wcsicmp(filename + len - 4, L".bat") == 0 ||
                     _wcsicmp(filename + len - 4, L".cmd") == 0 ||
                     _wcsicmp(filename + len - 4, L".com") == 0)) {
                    St.st_mode |= _S_IEXEC;
                }
                if (!(fi.dwFileAttributes & FILE_ATTRIBUTE_READONLY)) {
                    St.st_mode |= _S_IWRITE;
                }
                St.st_mode |= _S_IREAD;
            }
            /* owner == user == group */
            St.st_mode |= (St.st_mode & 0700) >> 3;
            St.st_mode |= (St.st_mode & 0700) >> 6;
            St.st_nlink = fi.nNumberOfLinks;
            St.st_uid = 0;
            St.st_gid = 0;
            St.st_rdev = 0;
            St.st_atime = translate_ft_to_time_t(fi.ftLastAccessTime);
            St.st_mtime = translate_ft_to_time_t(fi.ftLastWriteTime);
            St.st_ctime = translate_ft_to_time_t(fi.ftCreationTime);
#ifdef __CYGWIN__
            St.st_blksize = st.st_blksize;
            St.st_blocks = st.st_blocks;
#endif
            hv_stores(hv, "dev", newSVuv(St.st_dev));
            hv_stores(hv, "ino_high", newSVuv(fi.nFileIndexHigh));
            hv_stores(hv, "ino_low", newSVuv(fi.nFileIndexLow));
            hv_stores(hv, "mode", newSVuv(St.st_mode));
            hv_stores(hv, "nlink", newSVuv(St.st_nlink));
            hv_stores(hv, "uid", newSVuv(St.st_uid));
            hv_stores(hv, "gid", newSVuv(St.st_gid));
            hv_stores(hv, "rdev", newSVuv(St.st_rdev));
            hv_stores(hv, "atime", newSVuv(St.st_atime));
            hv_stores(hv, "mtime", newSVuv(St.st_mtime));
            hv_stores(hv, "ctime", newSVuv(St.st_ctime));
#ifdef __CYGWIN__
            hv_stores(hv, "blksize", newSVuv(St.st_blksize));
            hv_stores(hv, "blocks", newSVuv(St.st_blocks));
#endif
            if (is_dir) {
                hv_stores(hv, "size_high", newSVuv(0));
                hv_stores(hv, "size_low", newSVuv(0));
            }
            else {
                hv_stores(hv, "size_high", newSVuv(fi.nFileSizeHigh));
                hv_stores(hv, "size_low", newSVuv(fi.nFileSizeLow));
            }
            break;

        case FILE_TYPE_CHAR:
        case FILE_TYPE_PIPE:
            St.st_mode = (type == FILE_TYPE_CHAR) ? _S_IFCHR : _S_IFIFO;
            if (isstdhandle) {
                St.st_mode |= _S_IWRITE | _S_IREAD;
            }
            hv_stores(hv, "dev", newSVuv(0));
            hv_stores(hv, "ino", newSVuv(0));
            hv_stores(hv, "mode", newSVuv(St.st_mode));
            hv_stores(hv, "nlink", newSVuv(0));
            hv_stores(hv, "uid", newSVuv(0));
            hv_stores(hv, "gid", newSVuv(0));
            hv_stores(hv, "rdev", newSVuv(0));
            hv_stores(hv, "atime", newSVuv(0));
            hv_stores(hv, "mtime", newSVuv(0));
            hv_stores(hv, "ctime", newSVuv(0));
#ifdef __CYGWIN__
            hv_stores(hv, "blksize", newSVuv(0));
            hv_stores(hv, "blocks", newSVuv(0));
#endif
            hv_stores(hv, "size_high", newSVuv(0));
            hv_stores(hv, "size_low", newSVuv(0));
            break;

        default:
            XSRETURN_EMPTY;
        }
#else /* (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5)) */
        if (!is_dir) {
            if (GetFileInformationByHandle(handle, &fi) == 0) {
                XSRETURN_EMPTY;
            }
        }

        hv_stores(hv, "dev", newSViv(st.st_dev));
        hv_stores(hv, "ino", newSViv(st.st_ino));
        hv_stores(hv, "mode", newSViv(st.st_mode));
        hv_stores(hv, "nlink", newSViv(st.st_nlink));
        hv_stores(hv, "uid", newSViv(st.st_uid));
        hv_stores(hv, "gid", newSViv(st.st_gid));
        hv_stores(hv, "rdev", newSViv(st.st_rdev));
        hv_stores(hv, "atime", newSViv(st.st_atime));
        hv_stores(hv, "mtime", newSViv(st.st_mtime));
        hv_stores(hv, "ctime", newSViv(st.st_ctime));
#ifdef __CYGWIN__
        hv_stores(hv, "blksize", newSViv(st.st_blksize));
        hv_stores(hv, "blocks", newSViv(st.st_blocks));
#endif
        if (is_dir) {
            hv_stores(hv, "size_high", newSViv(0));
            hv_stores(hv, "size_low", newSViv(0));
        }
        else {
            hv_stores(hv, "size_high", newSViv(fi.nFileSizeHigh));
            hv_stores(hv, "size_low", newSViv(fi.nFileSizeLow));
        }
#endif /* (PERL_VERSION > 33) || ((PERL_VERSION == 33) && (PERL_SUBVERSION >= 5)) */

        ST(0) = hvref;
        XSRETURN(1);

bool
lock_file(HANDLE handle, int ope)
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

bool
unlock_file(HANDLE handle)
    CODE:
        OVERLAPPED ol;
        ol.Offset = 0;
        ol.OffsetHigh = 0;

        RETVAL = UnlockFileEx(handle, 0, 0xFFFFFFFF, 0xFFFFFFFF, &ol);
    OUTPUT:
        RETVAL

bool
update_time(long atime, long mtime, WCHAR *filename)
    CODE:
        struct _utimbuf ut;
        ut.actime  = atime;
        ut.modtime = mtime;

        if (_UTIME(filename, &ut) == -1) {
            XSRETURN_EMPTY;
        }

        RETVAL = 1;
    OUTPUT:
        RETVAL
