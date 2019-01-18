@echo off
setlocal enabledelayedexpansion
set CWD=%cd%
set CYGWIN_DRIVE=%~d0
set CYGWIN_ROOT=%~dp0cygwin


set PATH=%SystemRoot%\system32;%SystemRoot%;%CYGWIN_ROOT%\bin;
set CYGWIN=nodosfilewarning

set USERNAME=root
set HOME=/home/%USERNAME%
set SHELL=/bin/bash
set HOMEDRIVE=%CYGWIN_DRIVE%
set HOMEPATH=%CYGWIN_ROOT%\home\%USERNAME%
set GROUP=None
set GRP=


%CYGWIN_DRIVE%
chdir "%CYGWIN_ROOT%\bin"

if NOT "%*" == "0" (
    REM mintty -T 'Command Prompt' -
    bash --login -i
    goto :eof
)


echo Replacing [/etc/fstab]...
(
    echo # /etc/fstab
    echo # IMPORTANT: this files is recreated on each start by cygwin-portable.cmd
    echo #
    echo #    This file is read once by the first process in a Cygwin process tree.
    echo #    To pick up changes, restart all Cygwin processes.  For a description
    echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
    echo.
    echo # noacl = disable Cygwin's - apparently broken - special ACL treatment which prevents apt-cyg and other programs from working
    echo %CYGWIN_ROOT%/bin  /usr/bin ntfs binary,auto,noacl           0  0
    echo %CYGWIN_ROOT%/lib  /usr/lib ntfs binary,auto,noacl           0  0
    echo %CYGWIN_ROOT%      /        ntfs override,binary,auto,noacl  0  0
    echo none /cygdrive cygdrive binary,noacl,posix=0,user 0 0
) > %CYGWIN_ROOT%\etc\fstab


set CYGWIN_INIT='%CYGWIN_ROOT:\=/%/../portable-init.sh'
bash --login -c '%CYGWIN_INIT%; ln -sf %CYGWIN_INIT% /bin'

:eof
