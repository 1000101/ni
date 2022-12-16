# NI - NixOS Installer

A simple guided Terminal NixOS Installer.

More info (what's inside) can be found at https://1000101.top/posts/NixOS_Installer/

## WARNING

**!!!THIS SCRIPT WILL ERASE YOUR ENTIRE DISK = ALL DATA WILL BE LOST!!!**

Use at your own risk, ideally on a new computer. **NEVER** use it on existing installations as this
installer will overwrite your disk.

## Usage

### Preparation

Download the latest graphical live NixOS from https://channels.nixos.org/nixos-22.05/latest-nixos-gnome-x86_64-linux.iso
and create a live USB (replace VERSION.COMMIT and sdX with appropriate values), e.g. (be careful):

`$ sudo dd if=Downloads/nixos-gnome-22.05.VERSION.COMMIT-x86_64-linux.iso of=/dev/sdX bs=1M && sync`

Make sure SATA mode is set to AHCI, i.e. disable Intel Rapid Storage Technology, if it's present.

Boot into live disk and start and connect to the Internet.

### Running the installer

Open Terminal and download the installation script:

`$ curl -O https://raw.githubusercontent.com/1000101/ni/master/ni.sh`

Run the installation script:

`$ sudo bash ni.sh`

The script will guide you through the installation process.

Don't forget to write down the **password** (same for root&encryption).

### Post installation

Login as root and set user password:

`# passwd yourusernamehere`

Then logout and login as user.

Enjoy!
