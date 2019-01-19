@echo off
::
:: Copyright (c) 2017 Vegard IT GmbH, http://vegardit.com
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::      http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
::
:: @author Sebastian Thomschke, Vegard IT GmbH


:: ABOUT
:: =====
:: This self-contained Windows batch file creates a portable Cygwin (https://cygwin.com/mirrors.html) installation.
:: By default it automatically installs :
:: - testssl.sh (command line tool to check SSL/TLS configurations of servers, see https://testssl.sh/)


:: ============================================================================================================
:: CONFIG CUSTOMIZATION START
:: ============================================================================================================

:: You can customize the following variables to your needs before running the batch file:

:: set proxy if required (unfortunately Cygwin setup.exe does not have commandline options to specify proxy user credentials)
set PROXY_HOST=
set PROXY_PORT=8080

:: change the URL to the closest mirror https://cygwin.com/mirrors.html
set CYGWIN_MIRROR=http://mirrors.ustc.edu.cn/cygwin

:: choose a user name under Cygwin
set CYGWIN_USERNAME=root

:: select the packages to be installed automatically via apt-cyg
set CYGWIN_PACKAGES=bash,gawk,tar,wget,xz,bzip2,dos2unix

:: if set to 'yes' the local package cache created by cygwin setup will be deleted after installation/update
set DELETE_CYGWIN_PACKAGE_CACHE=no

:: if set to 'yes' testssl.sh (https://testssl.sh/) will be installed automatically
set INSTALL_TESTSSL_SH=no
:: name of the GIT branch to install from, see https://github.com/drwetter/testssl.sh
set TESTSSL_GIT_BRANCH=2.9.5

:: add more path if required, but at the cost of runtime performance (e.g. slower forks)
set CYGWIN_PATH=%%SystemRoot%%\system32;%%SystemRoot%%

:: set Mintty options, see https://cdn.rawgit.com/mintty/mintty/master/docs/mintty.1.html#CONFIGURATION
set MINTTY_OPTIONS=--Title Command Prompt ^
  -o Columns=160 ^
  -o Rows=50 ^
  -o BellType=0 ^
  -o ClicksPlaceCursor=yes ^
  -o CursorBlinks=yes ^
  -o CursorColour=96,96,255 ^
  -o CursorType=Block ^
  -o CopyOnSelect=yes ^
  -o RightClickAction=Paste ^
  -o Font="Courier New" ^
  -o FontHeight=10 ^
  -o FontSmoothing=None ^
  -o ScrollbackLines=10000 ^
  -o Transparency=off ^
  -o Term=xterm-256color ^
  -o Charset=UTF-8 ^
  -o Locale=C

:: ============================================================================================================
:: CONFIG CUSTOMIZATION END
:: ============================================================================================================


echo.
echo ###########################################################
echo # Installing [Cygwin Portable]...
echo ###########################################################
echo.

set INSTALL_ROOT=%~dp0

set CYGWIN_ROOT=%INSTALL_ROOT%cygwin
echo Creating Cygwin root [%CYGWIN_ROOT%]...
if not exist "%CYGWIN_ROOT%" (
    md "%CYGWIN_ROOT%"
)

:: create VB script that can download files
:: not using PowerShell which may be blocked by group policies
set DOWNLOADER=%INSTALL_ROOT%downloader.vbs
echo Creating [%DOWNLOADER%] script...
if "%PROXY_HOST%" == "" (
    set DOWNLOADER_PROXY=.
) else (
    set DOWNLOADER_PROXY= req.SetProxy 2, "%PROXY_HOST%:%PROXY_PORT%", ""
)

(
    echo url = Wscript.Arguments(0^)
    echo target = Wscript.Arguments(1^)
    echo WScript.Echo "Downloading '" ^& url ^& "' to '" ^& target ^& "'..."
    echo Set req = CreateObject("WinHttp.WinHttpRequest.5.1"^)
    echo%DOWNLOADER_PROXY%
    echo req.Open "GET", url, False
    echo req.Send
    echo If req.Status ^<^> 200 Then
    echo    WScript.Echo "FAILED to download: HTTP Status " ^& req.Status
    echo    WScript.Quit 1
    echo End If
    echo Set buff = CreateObject("ADODB.Stream"^)
    echo buff.Open
    echo buff.Type = 1
    echo buff.Write req.ResponseBody
    echo buff.Position = 0
    echo buff.SaveToFile target
    echo buff.Close
    echo.
) >"%DOWNLOADER%" || goto :fail

:: download Cygwin 32 or 64 setup exe depending on detected architecture
if "%PROCESSOR_ARCHITEW6432%" == "AMD64" (
    set CYGWIN_SETUP=setup-x86_64.exe
) else (
    if "%PROCESSOR_ARCHITECTURE%" == "x86" (
        set CYGWIN_SETUP=setup-x86.exe
    ) else (
        set CYGWIN_SETUP=setup-x86_64.exe
    )
)

if NOT exist "%CYGWIN_ROOT%\setup\%CYGWIN_SETUP%" (
    cscript //Nologo %DOWNLOADER% http://cygwin.org/%CYGWIN_SETUP% "%CYGWIN_ROOT%\setup\%CYGWIN_SETUP%" || goto :fail
)
del "%DOWNLOADER%"

:: Cygwin command line options: https://cygwin.com/faq/faq.html#faq.setup.cli
if "%PROXY_HOST%" == "" (
    set CYGWIN_PROXY=
) else (
    set CYGWIN_PROXY=--proxy "%PROXY_HOST%:%PROXY_PORT%"
)

:: if conemu install is selected we need to be able to extract 7z archives, otherwise we need to install mintty
if "%INSTALL_CONEMU%" == "yes" (
    set CYGWIN_PACKAGES=bsdtar,%CYGWIN_PACKAGES%
) else (
    set CYGWIN_PACKAGES=mintty,%CYGWIN_PACKAGES%
)

if "%INSTALL_TESTSSL_SH%" == "yes" (
    set CYGWIN_PACKAGES=bind-utils,%CYGWIN_PACKAGES%
)

echo Running Cygwin setup...
"%CYGWIN_ROOT%\setup\%CYGWIN_SETUP%" --no-admin ^
 --site %CYGWIN_MIRROR% %CYGWIN_PROXY% ^
 --root "%CYGWIN_ROOT%" ^
 --local-package-dir "%CYGWIN_ROOT%\setup" ^
 --no-shortcuts ^
 --no-desktop ^
 --delete-orphans ^
 --upgrade-also ^
 --no-replaceonreboot ^
 --quiet-mode ^
 --packages %CYGWIN_PACKAGES% || goto :fail

if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
    rd /s /q "%CYGWIN_ROOT%\setup"
)

echo.
echo ###########################################################
echo # /etc/fstab and /etc/passwd initialization.
echo ###########################################################
%CYGWIN_ROOT%\..\cygwin-start.cmd 0
echo.


set Start_cmd=%INSTALL_ROOT%cygwin-start.cmd

echo.
echo ###########################################################
echo # Installing [Cygwin Portable] succeeded.
echo ###########################################################
echo.
echo Use [%Start_cmd%] to launch Cygwin Portable.
echo.
timeout /T 60
goto :eof

:fail
    if exist "%DOWNLOADER%" (
        del "%DOWNLOADER%"
    )
    echo.
    echo ###########################################################
    echo # Installing [Cygwin Portable] FAILED!
    echo ###########################################################
    echo.
    timeout /T 60
    exit /b 1
