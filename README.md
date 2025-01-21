# VM configuration
The VM uses a SCSI hard disk and UEFI.

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

Run `sudo nixos-rebuild switch`. Afterwards change the password with `passwd`, otherwise SSH does not work.

# Building

Build the config on the target VM using `nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake .#relay-node --target-host nixos@<YourVMsIP> --build-on-remote`


