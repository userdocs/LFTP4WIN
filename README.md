# LFTP4WIN Installer

This is a deployment tool that allows you to install a portable and configured Cygwin x64 installation to use with the [LFTP4WIN-CORE](https://github.com/userdocs/LFTP4WIN-CORE) solution.

The script is configured to install the required components automatically and you don't need to edit anything to get this to work out of the box. Just follow the installation instructions.

If you require a specific setting to be modified, configuration options are set in the `LFTP4WIN-installer.cmd` using a text editor.

## Configuration

There are some configuration options that you can change in the `LFTP4WIN-installer.cmd`. These are the only only options that should be modified.

```bat
:: Show the packet manager if you need to specify a program version during installation instead of using the current release (default), like openssh 7.9 instead of 8.0 for Lftp.
set CYGWIN_PACKET_MANAGER=

:: Select the packages to be installed automatically - required packages for LFTP4WIN:bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh
set CYGWIN_PACKAGES=wget,ca-certificates,gnupg,bsdtar,bash-completion,curl,lftp,ssh-pageant,openssh,openssl,sshpass,procps-ng

:: Install the LFTP4WIN Skeleton files to use lftp via WinSCP and Conemu. Installs Conemu, kitty, WinSCP, notepad++ and makes a few minor modifications to the default cygin installation.
set INSTALL_LFTP4WIN_CORE=yes

:: change the URL to the closest mirror <https://cygwin.com/mirrors.html>
set CYGWIN_MIRROR=<https://cygwin.mirror.uk.sargasso.net/>
```

## Installation

Download and extract the `LFTP4WIN-installer.cmd` to a folder where you want to install LFTP4WIN.

_Warning: Though this can be installed to a path with spaces in it, it's best to not have spaces in the path as it will most likely break stuff in Cygwin unexpectedly._

Once Cygwin has been installed `LFTP4WIN-CORE` will be downloaded and applied to the Cygwin installation.

When the installer is finished it will look like this.

![packages](https://github.com/userdocs/LFTP4WIN-CORE/raw/master/help/docs/readme-images/install-complete.jpg)

Note: If the install was not complete because your firewall blocks parts of the setup (curl) you can simply run the installer over to download the required files.

## Post Installation

`cmd` files what they do:

`Double Click Me - WinSCP Startup.cmd` - Starts WinSCP and `kageant` if key files are present.

`LFTP4WIN-import.cmd` - Imports your settings from another installation (2.0 or greater) by running this script and selecting the previous LFTP4WIN installation.

`LFTP4WIN-installer.cmd` - The main installation script. Installing this again will reset everything.

`LFTP4WIN-terminal.cmd` - Starts a local terminal session in the home folder and loads your key files via  `kageant` if keys files are present.

`LFTP4WIN-updater.cmd` - Updates Cygwin and `LFTP4WIN-CORE` with no settings lost.

## Using LFTP4WIN

_Please use this [readme](https://github.com/userdocs/LFTP4WIN-CORE/blob/master/README.md) to understand how to properly use this solution._

Run the `Double Click Me - WinSCP Startup.cmd` to initialize the setup and start WinSCP.

All major features are handled by custom commands you can use once connected after configuring a session.

## Cygwin

Run the `LFTP4WIN-terminal.cmd` to access Cygwin bash via the ConEmu terminal.

The installation installs `apt-cyg` a Cygwin `apt` style packet manager. Read more here.

<https://github.com/kou1okada/apt-cyg>

## Updating

You can updated the installation using this script - `LFTP4WIN-updater.cmd`

It will present you two yes or no options.

`Update Cygwin? [y|n]:` - `y` or `n`

`y` - This will start the Cygwin update process which leads to the second question.

`n` - Will skip the Cygwin update and just skip to the `LFTP4WIN-CORE` update.

`Open Cygwin packet manager? [y|n]:` - `y` or `n`

`y` - This will open the Cygwin packet manger and allow you to add or remove packages.

`n` - This will run the updater with no interaction. It will update installed and base components of the Cygwin installation.

`LFTP4WIN-CORE` is always updated by pulling the repo from GitHub and unpacking over your existing installation.
