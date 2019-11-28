@echo off
::
:: Copyright 2019 by userdocs and contributors for LFTP4WIN installer derived from https://github.com/vegardit/cygwin-portable-installer
:: Copyright 2017-2019 by Vegard IT GmbH (https://vegardit.com) and the cygwin-portable-installer contributors.
::
:: SPDX-License-Identifier: Apache-2.0
::
:: LFTPWIN installer derived from cygwin-portable-installer
:: @author userdocs
:: @contributors
::
:: cygwin-portable-installer
:: @author Sebastian Thomschke, Vegard IT GmbH
:: @contributor userdocs bofhbug xnum
::
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

:: ============================================================================================================
:: CONFIG CUSTOMIZATION START
:: ============================================================================================================

:: You can customize the following variables to your needs before running the batch file:

:: Choose a user name that will be used to configure Cygwin. This user will be a clone of the account running the installation script renamed as the setting chosen.
set LFTP4WIN_USERNAME=LFTP4WIN

:: Show the packet manager if you need to specify a program version during installation instead of using the current release (default), like openssh 7.9 instead of 8.0 for Lftp.
set CYGWIN_PACKET_MANAGER=

:: Select the packages to be installed automatically - required packages for LFTP4WIN:bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh
set CYGWIN_PACKAGES=bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh,openssl

:: Install the LFTP4WIN Skeleton files to use lftp via WinSCP and Conemu. Installs Conemu, kitty, WinSCP, notepad++ and makes a few minor modifications to the default cygin installation.
set INSTALL_LFTP4WIN_CORE=yes

:: if set to 'yes' the apt-cyg command line package manager (https://github.com/kou1okada/apt-cyg) will be installed automatically - requires wget,ca-certificates,gnupg which will be installed.
set INSTALL_APT_CYG=yes

:: set proxy if required (unfortunately Cygwin setup.exe does not have command line options to specify proxy user credentials)
set PROXY_HOST=
set PROXY_PORT=8080

:: change the URL to the closest mirror https://cygwin.com/mirrors.html
set CYGWIN_MIRROR=http://cygwin.mirror.uk.sargasso.net

:: one of: auto,64,32 - specifies if 32 or 64 bit version should be installed or automatically detected based on current OS architecture
set CYGWIN_ARCH=auto

:: add more path if required, but at the cost of runtime performance (e.g. slower forks)
set CYGWIN_PATH=""

:: if set to 'yes' the local package cache created by cygwin setup will be deleted after installation/update
set DELETE_CYGWIN_PACKAGE_CACHE=yes

:: set Mintty options, see https://cdn.rawgit.com/mintty/mintty/master/docs/mintty.1.html#CONFIGURATION
set MINTTY_OPTIONS=--Title cygwin-portable ^
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

set LFTP4WIN_ROOT=%INSTALL_ROOT%system
echo Creating Cygwin root [%LFTP4WIN_ROOT%]...
if not exist "%LFTP4WIN_ROOT%" (
    md "%LFTP4WIN_ROOT%"
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
    echo On Error Resume Next
    echo Set req = CreateObject("MSXML2.XMLHTTP.6.0"^)
    echo On Error GoTo 0
    echo If req Is Nothing Then
    echo   Set req = CreateObject("WinHttp.WinHttpRequest.5.1"^)
    echo End If
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
) > "%DOWNLOADER%" || goto :fail

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
    set CYGWIN_SETUP=setup-x86_64.exe
) else (
    set CYGWIN_SETUP=setup-x86.exe
)

if exist "%LFTP4WIN_ROOT%\%CYGWIN_SETUP%" (
    del "%LFTP4WIN_ROOT%\%CYGWIN_SETUP%" || goto :fail
)
cscript //Nologo "%DOWNLOADER%" https://cygwin.org/%CYGWIN_SETUP% "%LFTP4WIN_ROOT%\%CYGWIN_SETUP%" || goto :fail
del "%DOWNLOADER%"

:: Cygwin command line options: https://cygwin.com/faq/faq.html#faq.setup.cli
if "%PROXY_HOST%" == "" (
    set CYGWIN_PROXY=
) else (
    set CYGWIN_PROXY=--proxy "%PROXY_HOST%:%PROXY_PORT%"
)

if "%CYGWIN_PACKET_MANAGER%" == "yes" (
   set CYGWIN_PACKET_MANAGER=--package-manager
)

if "%INSTALL_APT_CYG%" == "yes" (
   set CYGWIN_PACKAGES=wget,ca-certificates,gnupg,%CYGWIN_PACKAGES%
)

echo Running Cygwin setup...
"%LFTP4WIN_ROOT%\%CYGWIN_SETUP%" --no-admin ^
 --site %CYGWIN_MIRROR% %CYGWIN_PROXY% ^
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

set Updater_cmd=%INSTALL_ROOT%LFTP4WIN-updater.cmd
echo Creating updater [%Updater_cmd%]...
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo.
    echo set LFTP4WIN_BASE=%%~dp0
    echo set LFTP4WIN_ROOT=%%~dp0system
    echo.
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
    echo     echo # Updating Cygwin [LFTP4WIN Portable]...
    echo     echo ###########################################################
    echo     echo.
    echo     "%%LFTP4WIN_ROOT%%\%CYGWIN_SETUP%" --no-admin ^^
    echo     --site %CYGWIN_MIRROR% %CYGWIN_PROXY% ^^
    echo     --root "%%LFTP4WIN_ROOT%%" ^^
    echo     --local-package-dir "%%LFTP4WIN_ROOT%%\.pkg-cache" ^^
    echo     --no-shortcuts ^^
    echo     --no-desktop ^^
    echo     --delete-orphans ^^
    echo     --upgrade-also ^^
    echo     --no-replaceonreboot ^^
    echo     --quiet-mode %%PACKETMANAGER%% ^|^| goto :fail
    if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
        echo     rd /s /q "%%LFTP4WIN_ROOT%%\.pkg-cache"
    )
    echo     echo.
    echo ^)
	echo.
	echo IF EXIST "%%LFTP4WIN_ROOT%%\portable-init.sh" "%%LFTP4WIN_ROOT%%\bin\bash" "%%LFTP4WIN_ROOT%%\portable-init.sh"
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

set Cygwin_bat=%LFTP4WIN_ROOT%\Cygwin.bat
if exist "%LFTP4WIN_ROOT%\Cygwin.bat" (
    echo Disabling default Cygwin launcher [%Cygwin_bat%]...
    if exist "%Cygwin_bat%.disabled" (
        del "%Cygwin_bat%.disabled" || goto :fail
    )
    rename "%Cygwin_bat%" Cygwin.bat.disabled || goto :fail
)

set Init_sh=%LFTP4WIN_ROOT%\portable-init.sh
echo Creating [%Init_sh%]...
(
    echo #!/usr/bin/env bash
    echo #
    echo # Map Current Windows User to root user
    echo #
    echo # Check if current Windows user is in /etc/passwd
    echo USER_SID="$(mkpasswd -c | cut -d':' -f 5)"
    echo if ! grep -F "$USER_SID" /etc/passwd ^&^>/dev/null; then
    echo     echo "Mapping Windows user '$USER_SID' to cygwin '$USERNAME' in /etc/passwd..."
    echo     mkgroup -c ^> /etc/group
    echo     echo "$USERNAME:*:1001:$(mkpasswd -c | cut -d':' -f 4):$(mkpasswd -c | cut -d':' -f 5):$HOME:/bin/bash" ^> /etc/passwd
    echo fi
    echo #
    echo # adjust Cygwin packages cache path
    echo #
    echo pkg_cache_dir=$(cygpath -w "$LFTP4WIN_ROOT/.pkg-cache"^)
    echo sed -ri 's#(.*^)\.pkg-cache$#'"\t${pkg_cache_dir//\\/\\\\}"'#' /etc/setup/setup.rc
    if not "%PROXY_HOST%" == "" (
		echo #
        echo if [[ $HOSTNAME == "%COMPUTERNAME%" ]]; then
        echo     export http_proxy=http://%PROXY_HOST%:%PROXY_PORT%
        echo     export https_proxy=$http_proxy
        echo fi
    )
    if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
        echo #
        echo # Installing lftp4win core
        echo #
        echo lftp4win_core=$(cygpath -m "$LFTP4WIN_ROOT/../"^)
		echo #
		echo if [[ ! -f /.core-installed ]]; then
        echo     echo "*******************************************************************************"
        echo     echo "* Installing LFTP4WIN CORE..."
        echo     echo "*******************************************************************************"
        echo     echo
        echo     lftp4win_core_url="https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip"
        echo     echo "Download URL=$lftp4win_core_url"
        echo     curl -sL "$lftp4win_core_url" -o "lftp4win_core.zip"
        echo     bsdtar -xmf "lftp4win_core.zip" --strip-components=1 -C "$lftp4win_core"
        echo     [[ -d /applications ]] ^&^& touch /.core-installed
        echo     rm "lftp4win_core.zip"
        echo fi
        echo #
		echo if [[ -f /.core-installed ^&^& $CORE_UPDATE = 'yes' ]]; then
        echo     echo "*******************************************************************************"
        echo     echo "* Updating LFTP4WIN CORE..."
        echo     echo "*******************************************************************************"
        echo     lftp4win_core_url="https://github.com/userdocs/LFTP4WIN-CORE/archive/master.zip"
        echo     echo "Download URL=$lftp4win_core_url"
        echo     curl -sL "$lftp4win_core_url" -o "lftp4win_core.zip"
        echo     bsdtar -X '/core-update-excludes' -xmf "lftp4win_core.zip" --strip-components=1 -C "$lftp4win_core"
        echo     [[ -d /applications ]] ^&^& touch /.core-installed
        echo     rm "lftp4win_core.zip"
        echo fi
    )
    if "%INSTALL_APT_CYG%" == "yes" (
        echo #
        echo # Installing apt-cyg package manager if not yet installed or update it silently if it is.
        echo #
        echo if [[ ! -x /usr/local/bin/apt-cyg ]]; then
        echo     echo "*******************************************************************************"
        echo     echo "* Installing apt-cyg..."
        echo     echo "*******************************************************************************"
        echo     curl -sL https://raw.githubusercontent.com/kou1okada/apt-cyg/master/apt-cyg ^> /usr/local/bin/apt-cyg
        echo     chmod +x /usr/local/bin/apt-cyg
        echo else
        echo     curl -sL https://raw.githubusercontent.com/kou1okada/apt-cyg/master/apt-cyg ^> /usr/local/bin/apt-cyg
        echo     chmod +x /usr/local/bin/apt-cyg
        echo fi
    )
	echo #
	echo # Clean up some files we don't need.
	echo rm -f '.gitattributes' 'LICENSE.txt' 'README.md'
) > "%Init_sh%" || goto :fail

"%LFTP4WIN_ROOT%\bin\sed" -i 's/\r$//' "%Init_sh%" || goto :fail

set Start_cmd=%INSTALL_ROOT%LFTP4WIN-conemu.cmd
echo Creating launcher [%Start_cmd%]...
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
    echo ^(
    echo     echo # /etc/fstab
    echo     echo # IMPORTANT: this files is recreated on each start by LFTP4WIN-conemu.cmd
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
	echo IF EXIST "%%LFTP4WIN_ROOT%%\initialize.sh" "%%LFTP4WIN_ROOT%%\bin\bash" "%%LFTP4WIN_ROOT%%\initialize.sh"
	echo.
    echo IF EXIST "%%LFTP4WIN_ROOT%%\portable-init.sh" "%%LFTP4WIN_ROOT%%\bin\bash" "%%LFTP4WIN_ROOT%%\portable-init.sh"
    echo.
    echo set LIST=
    echo for %%%%x in ^("%%LFTP4WIN_BASE%%keys\*.ppk"^) do set LIST=!LIST! "%%%%x"
    echo IF exist "%%LFTP4WIN_BASE%%keys\*.ppk" ^(
    echo start "" "%%LFTP4WIN_ROOT%%\applications\kitty\kageant.exe" %%LIST:~1%%
    echo ^)
    echo.
    echo if "%%1" == "" (
    if "%INSTALL_LFTP4WIN_CORE%" == "yes" (
        if "%CYGWIN_ARCH%" == "64" (
            echo   start "" "%%~dp0system\applications\conemu\ConEmu64.exe" -cmd {Bash::bash}
        ) else (
            echo   start "" "%%~dp0system\applications\conemu\ConEmu.exe" -cmd {Bash::bash}
        )
    ) else (
        echo   mintty --nopin %MINTTY_OPTIONS% --icon %LFTP4WIN_ROOT%\Cygwin-Terminal.ico -
    )
    echo ^) else (
    echo   if "%%1" == "no-mintty" (
    echo     bash --login -i
    echo   ^) else (
    echo     bash --login -c %%*
    echo   ^)
    echo ^)
    echo.
) > "%Start_cmd%" || goto :fail

:: launching Bash once to initialize user home dir
call "%Start_cmd%" whoami

set Bashrc_sh=%INSTALL_ROOT%\home\.bashrc

if not "%PROXY_HOST%" == "" (
    echo Adding proxy settings for host [%COMPUTERNAME%] to [home/.bashrc]...
    find "export http_proxy" "%Bashrc_sh%" >NUL || (
        echo.
        echo if [[ $HOSTNAME == "%COMPUTERNAME%" ]]; then
        echo     export http_proxy=http://%PROXY_HOST%:%PROXY_PORT%
        echo     export https_proxy=$http_proxy
        echo     export no_proxy="::1,127.0.0.1,localhost,169.254.169.254,%COMPUTERNAME%,*.%USERDNSDOMAIN%"
        echo     export HTTP_PROXY=$http_proxy
        echo     export HTTPS_PROXY=$http_proxy
        echo     export NO_PROXY=$no_proxy
        echo fi
    ) >> "%Bashrc_sh%" || goto :fail
)

"%LFTP4WIN_ROOT%\bin\sed" -i 's/\r$//' "%Bashrc_sh%" || goto :fail

echo.
echo ###########################################################
echo # Installing [LFTP4WIN Portable] succeeded.
echo ###########################################################
echo.
echo Use [%Start_cmd%] to launch LFTP4WIN Portable.
echo.
timeout /T 60
goto :eof

:fail
    if exist "%DOWNLOADER%" (
        del "%DOWNLOADER%"
    )
    echo.
    echo ###########################################################
    echo # Installing [LFTP4WIN Portable] FAILED!
    echo ###########################################################
    echo.
    timeout /T 60
    exit /b 1
