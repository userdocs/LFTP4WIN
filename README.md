# LFTP4WIN Installer.

*Note: Lftp `4.8.4` is not working with `openssh 8`. You must select version `7.9` from the installer. I recommend using `openssl 1.0.2` as this is what lftp in Cygwin is built with currently.*

## Installation

Download and extract the `LFTP4WIN-installer.cmd` to a folder where you want to install LFTP4WIN.

*Warning: Though this can be installed to a path with spaces in it, it's best to not have spaces in the path as it will most likely break stuff in Cygwin unexpectedly.*

When the packet manager opens you need to filter for `openss` and you should be able to select the correct versions of `openssh` and `openssl` needed for LFTP4WIN to work properly.

![packages](https://github.com/userdocs/LFTP4WIN-CORE/raw/master/help/docs/readme-images/cygwin-packages.jpg)

Then click next and wait until it's finished.

Once Cygwin has been installed `LFTP4WIN-CORE` will be downloaded and applied to the Cygwin installation.

When the installer is finished it will look like this.

![packages](https://github.com/userdocs/LFTP4WIN-CORE/raw/master/help/docs/readme-images/install-complete.jpg)

Note: If the install was not complete because your firewall blocks parts of the setup (curl) you can simply run the installer over to download the required files. Make sure to tell Cygwin to keep the existing versions instead of updating `openssh` and `openssl`.

## Post Installation

`cmd` files what they do:

`Double Click Me - WinSCP Startup.cmd` - Starts WinSCP and `kageant` if key files are present.

`LFTP4WIN-conemu.cmd` - Starts ConEmu in the home folder and `kageant` if keys files are present.

`LFTP4WIN-import.cmd` - Imports your settings from another installation (2.0 or greater)

`LFTP4WIN-installer.cmd` - The main installation script. Installing this again will reset everything.

`LFTP4WIN-updater.cmd` - Updates Cygwin and `LFTP4WIN-CORE` with no settings lost.

## Using LFTP4WIN

Run the `Double Click Me - WinSCP Startup.cmd` to initialize the setup and start WinSCP.

All major features are handled by custom commands you can use once connected after configuring a session.

## Cygwin

Run the `LFTP4WIN-conemu.cmd` to access Cygwin bash via the ConEmu terminal.

The installation installs `apt-cyg` a cygwin `apt` style packet manager. Read more here.

[https://github.com/kou1okada/apt-cyg](https://github.com/kou1okada/apt-cyg)