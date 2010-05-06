package Win32::Unicode::Define;

use strict;
use warnings;
use Win32::API ();
use Exporter 'import';

our @EXPORT = grep { !/import|BEGIN|EXPORT/ && Win32::Unicode::Define->can($_) } keys %Win32::Unicode::Define::;

use constant +{
    GetCurrentDirectory        => Win32::API->new('kernel32', 'GetCurrentDirectoryW'      , 'NP'        , 'N'),
    SetCurrentDirectory        => Win32::API->new('kernel32', 'SetCurrentDirectoryW'      , 'P'         , 'I'),
    FindFirstFile              => Win32::API->new('kernel32', 'FindFirstFileW'            , 'PS'        , 'N'),
    FindNextFile               => Win32::API->new('kernel32', 'FindNextFileW'             , 'NS'        , 'I'),
    FindClose                  => Win32::API->new('kernel32', 'FindClose'                 , 'N'         , 'I'),
    RemoveDirectory            => Win32::API->new('kernel32', 'RemoveDirectoryW'          , 'P'         , 'I'),
    GetFileAttributes          => Win32::API->new('kernel32', 'GetFileAttributesW'        , 'P'         , 'N'),
    GetFileSizeEx              => Win32::API->new('kernel32', 'GetFileSizeEx'             , 'NS'        , 'I'),
    CopyFile                   => Win32::API->new('kernel32', 'CopyFileW'                 , 'PPI'       , 'I'),
    MoveFile                   => Win32::API->new('kernel32', 'MoveFileW'                 , 'PP'        , 'I'),
    GetFileInformationByHandle => Win32::API->new('kernel32', 'GetFileInformationByHandle', 'NS'        , 'N'),
    GetLastError               => Win32::API->new('kernel32', 'GetLastError'              , ''          , 'I'),
    FormatMessage              => Win32::API->new('kernel32', 'FormatMessageW'            , 'IPIIPIP'   , 'I'),
    GetStdHandle               => Win32::API->new('kernel32', 'GetStdHandle'              , 'N'         , 'N'),
    WriteConsole               => Win32::API->new('kernel32', 'WriteConsoleW'             , 'NPNNP'     , 'I'),
    CreateProcess              => Win32::API->new('kernel32', 'CreateProcessW'            , 'PPPPNNPPSS', 'I'),
    WaitForSingleObject        => Win32::API->new('kernel32', 'WaitForSingleObject'       , 'NN'        , 'N'),
    WaitForInputIdle           => Win32::API->new('user32'  , 'WaitForInputIdle'          , 'NN'        , 'N'),
    SetFilePointerEx           => Win32::API->new('kernel32', 'SetFilePointerEx'          , 'NSSN'      , 'I'),
};

Win32::API::Struct->typedef('LARGE_INTEGER', qw(
    DWORD low;
    DWORD high;
));

Win32::API::Struct->typedef('FILETIME', qw(
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
));

Win32::API::Struct->typedef('WIN32_FIND_DATAW', qw{
    DWORD    dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD    nFileSizeHigh;
    DWORD    nFileSizeLow;
    DWORD    dwReserved0;
    DWORD    dwReserved1;
    WCHAR    cFileName[520];
    WCHAR    cAlternateFileName[28];
});

Win32::API::Struct->typedef('BY_HANDLE_FILE_INFORMATION', qw{
    DWORD    dwFileAttributes;
    FILETIME ctime;
    FILETIME atime;
    FILETIME mtime;
    DWORD    dwVolumeSerialNumber;
    DWORD    size_high;
    DWORD    size_low;
    DWORD    nNumberOfLinks;
    DWORD    nFileIndexHigh;
    DWORD    nFileIndexLow;
});

Win32::API::Struct->typedef('PROCESS_INFORMATION', qw(
    HANDLE hProcess;
    HANDLE hThread;
    DWORD  dwProcessId;
    DWORD  dwThreadId;
));

Win32::API::Struct->typedef('STARTUPINFO', qw{
    DWORD  cb;
    LPWSTR lpReserved;
    LPWSTR lpDesktop;
    LPWSTR lpTitle;
    DWORD  dwX;
    DWORD  dwY;
    DWORD  dwXSize;
    DWORD  dwYSize;
    DWORD  dwXCountChars;
    DWORD  dwYCountChars;
    DWORD  dwFillAttribute;
    DWORD  dwFlags;
    WORD   wShowWindow;
    WORD   cbReserved2;
    LPBYTE lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
});

1;
