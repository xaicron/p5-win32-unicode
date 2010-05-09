#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = Win32::Unicode

BOOT:
    boot_Win32__Unicode__Dir(aTHX_ cv);
    boot_Win32__Unicode__File(aTHX_ cv);
    boot_Win32__Unicode__Console(aTHX_ cv);

