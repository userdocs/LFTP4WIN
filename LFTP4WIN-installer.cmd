@echo off

:: Copyright 2023 by userdocs and contributors for LFTP4WIN installer derived from https://github.com/vegardit/cygwin-portable-installer
:: Copyright 2017-2023 by Vegard IT GmbH (https://vegardit.com) and the cygwin-portable-installer contributors.
::
:: LFTP4WIN installer derived from cygwin-portable-installer
:: SPDX-FileCopyrightText: © userdocs and contributors
:: SPDX-FileContributor: userdocs
:: SPDX-License-Identifier: Apache-2.0
::
:: cygwin-portable-installer
:: SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com) and contributors
:: SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
:: SPDX-License-Identifier: Apache-2.0

:: ABOUT
:: =====
:: LFTP4WIN installer
::
:: A heavily modified and re-targeted version of this project https://github.com/vegardit/cygwin-portable-installer
:: Original code has been 1: removed where not relevant 2: Modified to work with LFTP4WIN CORE 3: Unmodified where applicable.
:: It installs a portable Cygwin installation to be used specifically with the https://github.com/userdocs/LFTP4WIN-CORE skeleton.
:: The LFTP4WIN-CORE is applied to the Cygwin installation with minimal modification to the Cygwin environment or core files.
:: This provides a a fully functional Cygwin portable platform for use with the LFTP4WIN project.
:: Environment customization is no longer designed to be fully self contained and is partially provided via the LFTP4WIN-CORE
:: There are still some critical configuration options available below for the installation.
:: if executed with "--debug" print all executed commands
for %%a in (%*) do (
  if [%%~a]==[--debug] echo on
)

:: ============================================================================================================
:: CONFIG CUSTOMIZATION START
:: ============================================================================================================

:: You can customize the following variables to your needs before running the batch file:

:: set proxy if required (unfortunately Cygwin setup.exe does not have commandline options to specify proxy user credentials)
set PROXY_HOST=
set PROXY_PORT=8080

:: Choose a user name that will be used to configure Cygwin. This user will be a clone of the account running the installation script renamed as the setting chosen.
set LFTP4WIN_USERNAME=LFTP4WIN

:: Show the packet manager if you need to specify a program version during installation instead of using the current release (default), like openssh 7.9 instead of 8.0 for Lftp.
set CYGWIN_PACKET_MANAGER=

:: Select the packages to be installed automatically - required packages for LFTP4WIN:bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh
set CYGWIN_PACKAGES=wget,ca-certificates,gnupg,bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh,openssl,sshpass,procps-ng

:: Install the LFTP4WIN Skeleton files to use lftp via WinSCP and Conemu. Installs Conemu, kitty, WinSCP, notepad++ and makes a few minor modifications to the default cygin installation.
set INSTALL_LFTP4WIN_CORE=yes

:: change the URL to the closest mirror https://cygwin.com/mirrors.html
set CYGWIN_MIRROR=https://www.mirrorservice.org/sites/sourceware.org/pub/cygwin/

:: one of: auto,64,32 - specifies if 32 or 64 bit version should be installed or automatically detected based on current OS architecture
set CYGWIN_ARCH=auto

:: add more path if required, but at the cost of runtime performance (e.g. slower forks)
set CYGWIN_PATH=""

:: if set to 'yes' the local package cache created by cygwin setup will be deleted after installation/update
set DELETE_CYGWIN_PACKAGE_CACHE=yes

:: ============================================================================================================
:: CONFIG CUSTOMIZATION END
:: ============================================================================================================

echo.
echo ###########################################################
echo # Installing [Cygwin Portable]
echo ###########################################################
echo.

set LFTP4WIN_BASE=%~dp0
set LFTP4WIN_ROOT=%~dp0system
set INSTALL_TEMP=%~dp0system\tmp

set USERNAME=%LFTP4WIN_USERNAME%
set GROUP=None
set GRP=
set SHELL=/bin/bash

if not exist "%INSTALL_TEMP%" (
  md "%LFTP4WIN_ROOT%"
  md "%LFTP4WIN_ROOT%\etc"
  md "%INSTALL_TEMP%"
)

:: https://blogs.msdn.microsoft.com/david.wang/2006/03/27/howto-detect-process-bitness/
if "%CYGWIN_ARCH%" == "auto" (
  if "%PROCESSOR_ARCHITECTURE%" == "x86" (
    if defined PROCESSOR_ARCHITEW6432 (
      set CYGWIN_ARCH=64
    ) else (
      set CYGWIN_ARCH=32
    )
  ) else (
    set CYGWIN_ARCH=64
  )
)

:: download Cygwin 32 or 64 setup exe depending on detected architecture
if "%CYGWIN_ARCH%" == "64" (
  set CYGWIN_SETUP_EXE=setup-x86_64.exe
) else (
  set CYGWIN_SETUP_EXE=setup-x86.exe
)

:: Cygwin command line options: https://cygwin.com/faq/faq.html#faq.setup.cli
if "%PROXY_HOST%" == "" (
  set CYGWIN_PROXY=
) else (
  set CYGWIN_PROXY=--proxy "%PROXY_HOST%:%PROXY_PORT%"
)

if exist "%INSTALL_TEMP%\%CYGWIN_SETUP_EXE%" (
  del "%INSTALL_TEMP%\%CYGWIN_SETUP_EXE%" || goto :fail
)

if "%CYGWIN_PACKET_MANAGER%" == "yes" (
  set CYGWIN_PACKET_MANAGER=--package-manager
)

echo Downloading some files, it can take a minute or two
echo.

call :download "https://cygwin.org/%CYGWIN_SETUP_EXE%" "%INSTALL_TEMP%\%CYGWIN_SETUP_EXE%"

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
  call :download "https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip" "%INSTALL_TEMP%\lftp4win_core.zip"
)

echo Running Cygwin setup
echo.

"%INSTALL_TEMP%\%CYGWIN_SETUP_EXE%" --no-admin ^
  --site "%CYGWIN_MIRROR%" ^
  --root "%LFTP4WIN_ROOT%" ^
  --local-package-dir "%LFTP4WIN_ROOT%\.pkg-cache" ^
  --no-shortcuts ^
  --no-desktop ^
  --delete-orphans ^
  --upgrade-also ^
  --no-replaceonreboot ^
  --quiet-mode ^
  --packages %CYGWIN_PACKAGES% %CYGWIN_PACKET_MANAGER% || goto :fail

if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
  rd /s /q "%LFTP4WIN_ROOT%\.pkg-cache"
)

(
  echo # /etc/fstab
  echo # IMPORTANT: this files is recreated on each start by LFTP4WIN-terminal.cmd
  echo #
  echo #    This file is read once by the first process in a Cygwin process tree.
  echo #    To pick up changes, restart all Cygwin processes.  For a description
  echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
  echo #
  echo none /cygdrive cygdrive binary,noacl,posix=0,sparse,user 0 0
) > "%LFTP4WIN_ROOT%\etc\fstab"

:: Configure our Cygwin Environment
"%LFTP4WIN_ROOT%\bin\mkgroup.exe" -c > system/etc/group || goto :fail
"%LFTP4WIN_ROOT%\bin\bash.exe" -c "echo ""$USERNAME:*:1001:$(system/bin/mkpasswd -c | system/bin/cut -d':' -f 4):$(system/bin/mkpasswd -c | system/bin/cut -d':' -f 5):$(system/bin/cygpath.exe -u ""%~dp0home""):/bin/bash""" > system/etc/passwd || goto :fail
:: Fix a symlink bug in Cygwin
"%LFTP4WIN_ROOT%\bin\ln.exe" -fsn '../usr/share/terminfo' '/lib/terminfo' || goto :fail

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
  "%LFTP4WIN_ROOT%\bin\bsdtar.exe" -xmf "%INSTALL_TEMP%\lftp4win_core.zip" --strip-components=1 -C "%LFTP4WIN_BASE%\" || goto :fail
  "%LFTP4WIN_ROOT%\bin\touch.exe" "%LFTP4WIN_ROOT%\.core-installed"
)

set Updater_cmd=%LFTP4WIN_BASE%LFTP4WIN-updater.cmd
echo.
echo Creating updater [%Updater_cmd%]
echo.
(
  echo @echo off
  echo setlocal enabledelayedexpansion
  echo.
  echo set LFTP4WIN_BASE=%%~dp0
  echo set LFTP4WIN_ROOT=%%~dp0system
  echo set INSTALL_TEMP=%%~dp0system\tmp
  echo.
  echo set CYGWIN_SETUP_EXE=%CYGWIN_SETUP_EXE%
  echo set CORE_UPDATE=yes
  echo set PATH=%%LFTP4WIN_ROOT%%\bin
  echo set USERNAME=%LFTP4WIN_USERNAME%
  echo set HOME=%%LFTP4WIN_BASE%%home
  echo set GROUP=None
  echo set GRP=
  echo set SHELL=/bin/bash
  echo echo.
  echo set /p "REPLY=Update Cygwin? [y|n]: "
  echo echo.
  echo.
  echo if "%%REPLY%%" == "y" ^(
  echo     set /p "PACKETMANAGER=Open Cygwin packet manager? [y|n]: "
  echo     echo.
  echo ^)
  echo.
  echo if "%%PACKETMANAGER%%" == "y" ^(
  echo     set PACKETMANAGER=--package-manager
  echo ^)
  echo.
  echo if "%%REPLY%%" == "y" ^(
  echo     echo ###########################################################
  echo     echo # Updating Cygwin [LFTP4WIN Portable]
  echo     echo ###########################################################
  echo     echo.
  echo     echo Downloading Cygwin Setup and the core-update-requirements files
  echo.
  echo     "%%LFTP4WIN_ROOT%%\bin\curl.exe" -sL "https://cygwin.org/%CYGWIN_SETUP_EXE%" ^> "%%INSTALL_TEMP%%\%%CYGWIN_SETUP_EXE%%"
  echo     "%%LFTP4WIN_ROOT%%\bin\curl.exe" -sL "https://raw.githubusercontent.com/userdocs/LFTP4WIN-CORE/master/system/.core-update-requirements" ^> "%%INSTALL_TEMP%%\.core-update-requirements"
  echo.
  echo     set /p C_U_R=^<"%%INSTALL_TEMP%%\.core-update-requirements"
  echo.
  echo     "%%INSTALL_TEMP%%\%%CYGWIN_SETUP_EXE%%" --no-admin ^^
  echo     --site %CYGWIN_MIRROR% ^^
  echo     --root "%%LFTP4WIN_ROOT%%" ^^
  echo     --local-package-dir "%%LFTP4WIN_ROOT%%\.pkg-cache" ^^
  echo     --no-shortcuts ^^
  echo     --no-desktop ^^
  echo     --delete-orphans ^^
  echo     --upgrade-also ^^
  echo     --no-replaceonreboot ^^
  echo     --quiet-mode ^^
  echo     --packages ^!C_U_R^! %%PACKETMANAGER%% ^|^| goto :fail
  if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
    echo     rd /s /q "%%LFTP4WIN_ROOT%%\.pkg-cache"
  )
  echo     echo.
  echo     del /q "%%INSTALL_TEMP%%\%%CYGWIN_SETUP_EXE%%" "%%LFTP4WIN_ROOT%%\Cygwin.bat" "%%LFTP4WIN_ROOT%%\Cygwin.ico" "%%LFTP4WIN_ROOT%%\Cygwin-Terminal.ico"
  echo ^)
  echo.
  echo "%%LFTP4WIN_ROOT%%\bin\curl.exe" -sL "https://raw.githubusercontent.com/userdocs/LFTP4WIN/master/LFTP4WIN-installer.cmd" ^> "%%LFTP4WIN_BASE%%\LFTP4WIN-installer.cmd"
  echo.
  echo IF EXIST "%%LFTP4WIN_ROOT%%\portable-init.sh" "%%LFTP4WIN_ROOT%%\bin\bash" -li "%%LFTP4WIN_ROOT%%\portable-init.sh"
  echo.
  echo echo.
  echo echo ###########################################################
  echo echo # Updating [LFTP4WIN Portable] succeeded.
  echo echo ###########################################################
  echo echo.
  echo pause
  echo goto :eof
  echo echo.
  echo :fail
  echo echo ###########################################################
  echo echo # Updating [LFTP4WIN Portable] FAILED!
  echo echo ###########################################################
  echo echo.
  echo pause
  echo exit /1
) > "%Updater_cmd%" || goto :fail

set Init_sh=%LFTP4WIN_ROOT%\portable-init.sh
echo Creating [%Init_sh%]
echo.
(
  echo #!/usr/bin/env bash
  echo #
  echo ## Map Current Windows User to root user
  echo #
  echo unset HISTFILE
  echo #
  echo USER_SID="$(mkpasswd -c | cut -d':' -f 5)"
  echo echo "Mapping Windows user '$USER_SID' to cygwin '$USERNAME' in /etc/passwd"
  echo mkgroup -c ^> /etc/group
  echo echo "$USERNAME:*:1001:$(mkpasswd -c | cut -d':' -f 4):$(mkpasswd -c | cut -d':' -f 5):$HOME:/bin/bash" ^> /etc/passwd
  echo #
  echo ## Create required directories
  echo #
  echo mkdir -p ~/bin
  echo #
  echo ## Adjust the Cygwin packages cache path
  echo #
  echo pkg_cache_dir=$(cygpath -w "$LFTP4WIN_ROOT/.pkg-cache"^)
  echo #
  echo sed -ri 's#(.*^)\.pkg-cache$#'"\t${pkg_cache_dir//\\/\\\\}"'#' /etc/setup/setup.rc
  if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
    echo #
    echo lftp4win_core=$(cygpath -m "$LFTP4WIN_ROOT/../"^)
    echo #
    echo if [[ -f /.core-installed ^&^& $CORE_UPDATE = 'yes' ]]; then
    echo     echo "*******************************************************************************"
    echo     echo "* Updating LFTP4WIN CORE"
    echo     echo "*******************************************************************************"
    echo     lftp4win_core_url="https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip"
    echo     echo -e "\nDownload URL=$lftp4win_core_url"
    echo     curl -sL "$lftp4win_core_url" ^> "lftp4win_core.zip"
    echo     bsdtar -X '/.core-update-excludes' -xmf "lftp4win_core.zip" --strip-components=1 -C "$lftp4win_core"
    echo     [[ -d /applications ]] ^&^& touch /.core-installed
    echo     rm -f 'lftp4win_core.zip' '.gitattributes' 'LICENSE.txt' 'README.md'
    echo fi
    echo #
    echo source "/.core-cleanup"
  )
  echo #
  echo ## Installing apt-cyg package manager to home folder ~/bin
  echo #
  echo curl -sL https://raw.githubusercontent.com/kou1okada/apt-cyg/master/apt-cyg ^> ~/bin/apt-cyg
  echo #
  echo set HISTFILE
) > "%Init_sh%" || goto :fail

"%LFTP4WIN_ROOT%\bin\sed" -i 's/\r$//' "%Init_sh%" || goto :fail

set Start_cmd=%LFTP4WIN_BASE%LFTP4WIN-terminal.cmd
echo Creating launcher [%Start_cmd%]
echo.
(
  echo @echo off
  echo setlocal enabledelayedexpansion
  echo.
  echo set LFTP4WIN_BASE=%%~dp0
  echo set LFTP4WIN_ROOT=%%~dp0system
  echo.
  echo set PATH=%%LFTP4WIN_ROOT%%\bin
  echo set USERNAME=%LFTP4WIN_USERNAME%
  echo set HOME=%%LFTP4WIN_BASE%%home
  echo set GROUP=None
  echo set GRP=
  echo set SHELL=/bin/bash
  echo.
  echo set TERMINAL=mintty
  echo.
  echo ^(
  echo     echo # /etc/fstab
  echo     echo # IMPORTANT: this files is recreated on each start by LFTP4WIN-terminal.cmd
  echo     echo #
  echo     echo #    This file is read once by the first process in a Cygwin process tree.
  echo     echo #    To pick up changes, restart all Cygwin processes.  For a description
  echo     echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
  echo     echo #
  echo     echo none /cygdrive cygdrive binary,noacl,posix=0,sparse,user 0 0
  echo ^) ^> "%%LFTP4WIN_ROOT%%\etc\fstab"
  echo.
  echo IF EXIST "%%LFTP4WIN_ROOT%%\etc\fstab" "%%LFTP4WIN_ROOT%%\bin\sed" -i 's/\r$//' "%%LFTP4WIN_ROOT%%\etc\fstab"
  echo.
  echo IF EXIST "%%LFTP4WIN_ROOT%%\portable-init.sh" "%%LFTP4WIN_ROOT%%\bin\bash" -li "%%LFTP4WIN_ROOT%%\portable-init.sh"
  echo.
  echo set LIST=
  echo for %%%%x in ^("%%LFTP4WIN_BASE%%keys\*.ppk"^) do set LIST=!LIST! "%%%%x"
  echo IF exist "%%LFTP4WIN_BASE%%keys\*.ppk" ^(
  echo start "" "%%LFTP4WIN_ROOT%%\applications\kitty\kageant.exe" %%LIST:~1%%
  echo ^)
  echo.
  if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
  echo if "%%TERMINAL%%" == "conemu" ^(
    if "%CYGWIN_ARCH%" == "64" (
      echo   start "" "%%LFTP4WIN_ROOT%%\applications\conemu\ConEmu64.exe" -cmd {Bash::bash}
    ) else (
      echo   start "" "%%LFTP4WIN_ROOT%%\applications\conemu\ConEmu.exe" -cmd {Bash::bash}
    )
  echo ^)
  )
  echo.
  echo if "%%TERMINAL%%" == "mintty" ^(
  echo   start "" "%%LFTP4WIN_ROOT%%\bin\mintty.exe" --nopin --title LFTP4WIN -e /bin/bash -li
  echo ^)
) > "%Start_cmd%" || goto :fail

echo ###########################################################
echo # Installing [LFTP4WIN Portable] succeeded.
echo ###########################################################
echo.
echo Use [%Start_cmd%] to launch LFTP4WIN Portable.

del /q "%INSTALL_TEMP%\%CYGWIN_SETUP_EXE%" "%LFTP4WIN_ROOT%\Cygwin.bat" "%LFTP4WIN_ROOT%\Cygwin.ico" "%LFTP4WIN_ROOT%\Cygwin-Terminal.ico"

if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
  DEL /Q "%LFTP4WIN_BASE%\.gitattributes" "%LFTP4WIN_BASE%\README.md" "%LFTP4WIN_BASE%\LICENSE.txt" "%INSTALL_TEMP%\lftp4win_core.zip"
  RMDIR /S /Q "%LFTP4WIN_BASE%\docs"
)

timeout /T 60
goto :eof

:fail
  set exit_code=%ERRORLEVEL%
  if exist "%DOWNLOADER%" (
    del "%DOWNLOADER%"
  )
  echo.
  echo ###########################################################
  echo # Installing [LFTP4WIN Portable] FAILED!
  echo ###########################################################
  echo.
  timeout /T 60
  exit /B %exit_code%

:download
  if exist "%2" (
    echo Deleting existing [%2]
    del "%2" || goto :fail
  )

  where /q curl
  if %ERRORLEVEL% EQU 0 (
    call :download_with_curl "%1" "%2"
  )

  if errorlevel 1 (
    call :download_with_powershell "%1" "%2"
  )

  if errorlevel 1 (
    call :download_with_vbs "%1" "%2" || goto :fail
  )

  exit /B 0

:download_with_curl
  if "%PROXY_HOST%" == "" (
    set "http_proxy="
    set "https_proxy="
  ) else (
    set http_proxy=http://%PROXY_HOST%:%PROXY_PORT%
    set https_proxy=http://%PROXY_HOST%:%PROXY_PORT%
  )
  echo Downloading %1 to %2 using curl
  curl -sL %1 -# -o %2 || exit /B 1
  exit /B 0

:download_with_vbs
  :: create VB script that can download files
  :: not using PowerShell which may be blocked by group policies
  set DOWNLOADER=%INSTALL_ROOT%downloader.vbs
  echo Creating [%DOWNLOADER%] script
  if "%PROXY_HOST%" == "" (
    set DOWNLOADER_PROXY=.
  ) else (
    set DOWNLOADER_PROXY= req.SetProxy 2, "%PROXY_HOST%:%PROXY_PORT%", ""
  )

  (
    echo url = Wscript.Arguments(0^)
    echo target = Wscript.Arguments(1^)
    echo On Error Resume Next
    echo reqType = "WinHttp.WinHttpRequest.5.1"
    echo Set req = CreateObject(reqType^)
    echo If req Is Nothing Then
    echo   reqType = "MSXML2.XMLHTTP.6.0"
    echo   Set req = CreateObject(reqType^)
    echo End If
    echo WScript.Echo "Downloading '" ^& url ^& "' to '" ^& target ^& "' using '" ^& reqType ^& "'"
    echo%DOWNLOADER_PROXY%
    echo req.Open "GET", url, False
    echo req.Send
    echo If Err.Number ^<^> 0 Then
    echo   WScript.Quit 1
    echo End If
    echo If req.Status ^<^> 200 Then
    echo   WScript.Echo "FAILED to download: HTTP Status " ^& req.Status
    echo   WScript.Quit 1
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

  cscript //Nologo "%DOWNLOADER%" %1 %2 || exit /B 1
  del "%DOWNLOADER%"
  exit /B 0

:download_with_powershell
  if "%PROXY_HOST%" == "" (
    set "http_proxy="
    set "https_proxy="
  ) else (
    set http_proxy=http://%PROXY_HOST%:%PROXY_PORT%
    set https_proxy=http://%PROXY_HOST%:%PROXY_PORT%
  )
  echo Downloading %1 to %2 using powershell
  powershell "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; (New-Object Net.WebClient).DownloadFile('%1', '%2')" || exit /B 1
  exit /B 0
