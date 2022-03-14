#!/usr/bin/env bash
echo
echo Bootstraping the NI installer, hold on...
echo
nix-env -iA nixos.diceware nixos.wget
wget -q https://raw.githubusercontent.com/1000101/ni/amd/install.sh -O /etc/nixos/install.sh && chmod +x /etc/nixos/install.sh
bash /etc/nixos/install.sh
