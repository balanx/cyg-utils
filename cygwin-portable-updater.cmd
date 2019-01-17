@echo off
set CYGWIN_ROOT=%~dp0cygwin
echo.

echo ###########################################################
echo # Updating [Cygwin Portable]...
echo ###########################################################
echo.
"%CYGWIN_ROOT%\setup-x86_64.exe" --no-admin ^
--site http://linux.rz.ruhr-uni-bochum.de/download/cygwin  ^
--root "%CYGWIN_ROOT%" ^
--local-package-dir "%CYGWIN_ROOT%\..\cygwin-pkg-cache" ^
--no-shortcuts ^
--no-desktop ^
--delete-orphans ^
--upgrade-also ^
--no-replaceonreboot ^
--quiet-mode || goto :fail
rd /s /q "%CYGWIN_ROOT%\..\cygwin-pkg-cache"
echo.
echo ###########################################################
echo # Updating [Cygwin Portable] succeeded.
echo ###########################################################
timeout /T 60
goto :eof
echo.
:fail
echo ###########################################################
echo # Updating [Cygwin Portable] FAILED!
echo ###########################################################
timeout /T 60
exit /1
