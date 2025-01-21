# Convenience script

Start the NixOS ISO, then run:
`curl -fsSL https://raw.githubusercontent.com/Sapp00/tailscale-relay/refs/heads/main/setup.sh | sudo bash`

# Doing it manually
Change the configuration.yaml to enable ssh:

{ config, pkgs, ... }:
{
    imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];

    services.openssh = {
        enable = true;
        settings.PasswordAuthentication = true;
    };

    networking.firewall.allowedTCPPorts = [ 22 ];
}

Run `sudo nixos-rebuild switch`


