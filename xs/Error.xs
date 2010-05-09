#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <windows.h>
#define BUFF_SIZE 520

MODULE = Win32::Unicode::Error  PACKAGE = Win32::Unicode::Error

PROTOTYPES: DISABLE

long
get_last_error()
    CODE:
        RETVAL = GetLastError();
    OUTPUT:
        RETVAL

SV*
foramt_message()
    CODE:
        WCHAR* buff[BUFF_SIZE];
        
        FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
            NULL,
            GetLastError(),
            LANG_USER_DEFAULT,
            buff,
            BUFF_SIZE,
            NULL
        );
        
        RETVAL = newSVpv(buff, wcslen(buff) * 2);
     OUTPUT:
        RETVAL
