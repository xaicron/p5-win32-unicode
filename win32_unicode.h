/* win32_unicode.h */

#define WIN32_UNICODE_CALL_BOOT(name) STMT_START {  \
            EXTERN_C XS(CAT2(boot_, name));         \
            PUSHMARK(SP);                           \
            CALL_FPTR(CAT2(boot_, name))(aTHX_ cv); \
        } STMT_END
