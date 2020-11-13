#!/usr/bin/env bash 
set -e

# Colours are for cool kids
error()   { echo -e " \033[1;31m*\033[0m  $@"; }
bold=$(tput bold)
normal=$(tput sgr0)

print_banner() {
  echo 
  echo " N)    nn  I)iiii  "
  echo " N)n   nn    I)    "
  echo " N)nn  nn    I)           Welcome to"
  echo " N) nn nn    I)             NixOS"
  echo " N)  nnnn    I)           Installer"
  echo " N)   nnn    I)"
  echo " N)    nn  I)iiii"
  echo
  echo
  echo
  echo " We are going to install NixOS on this computer."
  echo "         !!! ALL DATA WILL BE LOST !!! "
  echo
  echo
  while true; do
    read -p "[?] Do you understand? [Yes/No] " confirm
      case $confirm in
        [yY][eE][sS]* ) break;;
        [Nn][oO]* ) echo "Terminating the installer. Bye!"; exit;;
        * ) echo "Please answer Yes or No.";;
      esac
  done
}

ask_for_username() {
  read -p "[?] Please enter your username: " INST_USERNAME < /dev/tty
  export INST_USERNAME="${INST_USERNAME}"
}

find_install_device() {
  if [ -b /dev/nvme0n1 ]; then
    export INST_DEVICE="/dev/nvme0n1";
  elif [ -b /dev/sda ]; then
    export INST_DEVICE="/dev/sda";
  else
    echo "Installation device not found."
    read -p "Please specify the installation device manually: " -r < /dev/tty
    export INST_DEVICE=$REPLY
    if [ -b $INST_DEVICE ]; then
      echo "$INST_DEVICE is valid, using it."
    else
      error "$INST_DEVICE is not valid, aborting installation."
    fi
  fi
}

run_parted() {
  while true; do
    read -p "[?] We are going to run parted on ${bold}$INST_DEVICE${normal}. Is this okay? [Yes/No] " confirm
      case $confirm in
        [yY][eE][sS]* ) break;;
        [Nn][oO]* ) echo "Terminating the installer. Bye!"; exit;;
        * ) echo "Please answer Yes or No.";;
      esac
  done
  echo -n "[-] Partitioning $INST_DEVICE... "
  if ! wipefs -a $INST_DEVICE >/dev/null 2>&1; then
    error "ERROR:"
    echo "Problem with partitioning (mounted/active partition?)."
    echo -n "Please, erase the device using GPparted, then re-run the installer."
    exit;
  fi
  parted $INST_DEVICE -- mklabel gpt >/dev/null 2>&1 
  parted $INST_DEVICE -- mkpart ESP fat32 1MiB 512MiB set 1 boot on >/dev/null 2>&1
  parted $INST_DEVICE mkpart primary ext4 537M 100% set 2 lvm on >/dev/null 2>&1
  echo " done."
}

run_cryptsetup(){
  while true; do
    read -p "[?] Do you wish to ${bold} encrypt ${normal} your disk? [Yes/No] " confirm
      case $confirm in
        [yY][eE][sS]* ) ENCRYPTION=true; echo "Proceeding with encryption - YAY!!! - Don't forget to write down the password at the end of the installation!!!"; break;;
        [Nn][oO]* ) echo "Leaving your disk unencrypted :/ "; break;;
        * ) echo "Please answer Yes or No.";;
      esac
  done

  # Creating passwords for root and encryption (if enabled)
  INST_PASSWD=$(diceware -n 3);
  INST_PASSWD_SHA512=$(mkpasswd  -m sha-512 -s <<< ${INST_PASSWD})

  if [ $ENCRYPTION ]; then
    echo -n "[-] Encrypting the disk... "
    if [ -b /dev/nvme0n1 ]; then
      export INST_DEVICE=$INST_DEVICE"p"
    fi
    echo -n $INST_PASSWD | cryptsetup -q --type luks1 luksFormat ${INST_DEVICE}2 -
    echo -n $INST_PASSWD | cryptsetup luksOpen ${INST_DEVICE}2 enc-pv -d -
    echo "done."
  fi
}

run_fssetup(){
  echo -n "[-] Setting up LVM... "
  if [ $ENCRYPTION ]
  then
    pvcreate /dev/mapper/enc-pv >/dev/null
    vgcreate vg /dev/mapper/enc-pv >/dev/null
  else
    pvcreate ${INST_DEVICE}2 >/dev/null
    vgcreate vg ${INST_DEVICE}2 >/dev/null
  fi
    lvcreate -n swap vg -L 8G >/dev/null
    lvcreate -n root vg -l 100%FREE >/dev/null
  echo "done."
  echo -n "[-] Formating filesystems... "
  mkfs.fat -F 32 -n boot ${INST_DEVICE}1 >/dev/null 2>&1
  mkfs.ext4 -L root /dev/vg/root >/dev/null >/dev/null 2>&1
  mkswap -L swap /dev/vg/swap >/dev/null 2>&1
  echo "done."
  echo -n "[-] Mouting filesystems... "
  mount /dev/disk/by-label/root /mnt
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot
  swapon /dev/disk/by-label/swap >/dev/null
  echo "done."
}

run_nixossetup(){
  echo -n "[-] Generating NixOS configuration... "
  nixos-generate-config --root /mnt >/dev/null 2>&1
  mv /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/configuration.nix-old
  wget -q https://raw.githubusercontent.com/1000101/ni/master/configuration-template.nix -O /mnt/etc/nixos/configuration.nix
  if [ $ENCRYPTION ]; then
    sed -i "s~##device##~${INST_DEVICE}~g" /mnt/etc/nixos/configuration.nix
  else
    sed -i "13,18d" /mnt/etc/nixos/configuration.nix
  fi
  sed -i "s~##username##~${INST_USERNAME}~g" /mnt/etc/nixos/configuration.nix
  sed -i "s~##rootpasswd##~${INST_PASSWD_SHA512/\//\\/}~g" /mnt/etc/nixos/configuration.nix
  echo "done."
}

run_nixosinstall(){
  echo "[-] Running nixos-install... "
  nixos-install --no-root-passwd
}

print_finish(){
  clear
  echo Installation finished.
  echo Please take note of your password before reboot.
  echo
    printf "!!! This is your initial ROOT PASSWORD"
  if [ $ENCRYPTION ]; then
    printf " and DISK ENCRYPTION PASSPHRASE"
  fi 
  echo " !!!"
  echo
  echo Username:${bold} $INST_USERNAME ${normal}
  echo Password:${bold} $INST_PASSWD ${normal}
  echo
  printf "!!! This is your initial ROOT PASSWORD"
  if [ $ENCRYPTION ]; then
    printf "and DISK ENCRYPTION PASSPHRASE"
  fi 
  echo " !!!"
  echo
}

run_reboot(){

  while true; do
    read -p "[?] Have you written down the ${bold} password ${normal} - continue with ${bold} REBOOT ${normal} [Yes/No] " confirm
      case $confirm in
	[yY][eE][sS]* ) echo "REBOOTING"; sleep 1; reboot; break;;
        [Nn][oO]* )   echo Username:${bold} $INST_USERNAME ${normal}; echo Password:${bold} $INST_PASSWD ${normal};;
        * ) echo "Please write down your password, then reboot.";;
      esac
  done

}

# Let's bring the band together
clear
print_banner
ask_for_username
find_install_device
run_parted
run_cryptsetup
run_fssetup
run_nixossetup
run_nixosinstall
clear
print_finish
run_reboot
