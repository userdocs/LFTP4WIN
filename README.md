# LFTP4WIN Installer.

This is a deployment tool that allows you to install a portable Cygwin x64 installation to use with the [LFTP4WIN-CORE](https://github.com/userdocs/LFTP4WIN-CORE) solution.

The script is configured to install the required components automatically and you don't need to edit anything to get this to work out of the box. Just follow the installation insrtuctions.

If you require a specific setting, configuration options are set in the `LFTP4WIN-installer.cmd` using a text editor.

## Installation

Download and extract the `LFTP4WIN-installer.cmd` to a folder where you want to install LFTP4WIN.

*Warning: Though this can be installed to a path with spaces in it, it's best to not have spaces in the path as it will most likely break stuff in Cygwin unexpectedly.*

Once Cygwin has been installed `LFTP4WIN-CORE` will be downloaded and applied to the Cygwin installation.

When the installer is finished it will look like this.

![packages](https://github.com/userdocs/LFTP4WIN-CORE/raw/master/help/docs/readme-images/install-complete.jpg)

Note: If the install was not complete because your firewall blocks parts of the setup (curl) you can simply run the installer over to download the required files.
## Post Installation

`cmd` files what they do:

`Double Click Me - WinSCP Startup.cmd` - Starts WinSCP and `kageant` if key files are present.

`LFTP4WIN-conemu.cmd` - Starts ConEmu in the home folder and `kageant` if keys files are present.

`LFTP4WIN-import.cmd` - Imports your settings from another installation (2.0 or greater) by running this script.

`LFTP4WIN-installer.cmd` - The main installation script. Installing this again will reset everything.

`LFTP4WIN-updater.cmd` - Updates Cygwin and `LFTP4WIN-CORE` with no settings lost.

## Using LFTP4WIN

*Please use this [readme](https://github.com/userdocs/LFTP4WIN-CORE/blob/master/README.md) to understand how to properly use this solution.*

Run the `Double Click Me - WinSCP Startup.cmd` to initialize the setup and start WinSCP.

All major features are handled by custom commands you can use once connected after configuring a session.

## Cygwin

Run the `LFTP4WIN-conemu.cmd` to access Cygwin bash via the ConEmu terminal.

The installation installs `apt-cyg` a cygwin `apt` style packet manager. Read more here.

[https://github.com/kou1okada/apt-cyg](https://github.com/kou1okada/apt-cyg)