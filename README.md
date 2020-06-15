# NI - NixOS Installer

## WARNING
**!!!THIS SCRIPT WILL ERASE YOUR ENTIER DISK = ALL DATA WILL BE LOST!!!**


Use at your own risk, ideally on a new computer. **NEVER** use it on existing installations as this 
installer will overwrite your disk.

## Usage

### Preparation
Download the latest graphical live NixOS from https://channels.nixos.org/nixos-20.03/latest-nixos-plasma5-x86_64-linux.iso 
and create a live USB with it, e.g. (be careful):

```$ sudo dd if=Downloads/nixos-plasma5-20.03.version.commit-x86_64-linux.iso of=/dev/sdX bs=1M && sync```

Make sure SATA mode is set to AHCI, i.e. disable Intel Rapid Storage Technology, if it's present.

Boot into live disk and start DM (In the newest stable NixOS, this should be automatic):

```$ systemctl start display-manager.service```

Connect to the Internet.

### Running the installer
Open Terminal and download the installation script:

```$ curl -O https://raw.githubusercontent.com/1000101/ni/master/ni.sh```

Run the installation script:

```$ sudo bash ni.sh```

Don't forget to write down the **password** (same for root&encryption).

### Post installation

Login as root and set user password:

```# passwd yourusernamehere```

Then logout and login as user.

Enjoy!