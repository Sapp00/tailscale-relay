#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

FILE_PATH="/etc/nixos/configuration.nix"

# Define the new content
NEW_CONTENT='{ config, pkgs, ... }:
{
    imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];

    services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
}'

# Replace the content of the file
echo "$NEW_CONTENT" > "$FILE_PATH"

echo "The file $FILE_PATH has been replaced successfully."
echo "Rebuilding NixOS"

nixos-rebuild switch

