#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "win32_unicode.h"

MODULE = Win32::Unicode

BOOT:
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Dir);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__File);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Error);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Console);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Process);
    WIN32_UNICODE_CALL_BOOT(Win32__Unicode__Native);

