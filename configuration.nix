{ 
  modulesPath, 
  lib,
  pkgs, 
  ... 
}:

let
  traefikIP = "10.10.1.100";
in
{
  nix.settings.experimental-features = [ "nix-command" "flakes"];

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./tailscale.nix
  ];

  # Networking and firewall configuration
  networking = {
    firewall.allowedTCPPorts = [
      53 # DNS port
      443  # HTTPS port for Traefik
    ];

    interfaces.ens18.ipAddress = "10.100.10.2";  # Set a static IP for this machine, if needed
    defaultGateway = "10.100.10.1";  # Set your gateway
    nameservers = [ "10.100.10.1" ];  # Replace with your DNS server or Tailscale DNS
  }

  # Enable SSH for remote management (optional)
  services.openssh.enable = true;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
      timeout = 0;
    };
  };

  # no password per default, need to set it afterwards
  users.users.nix = {
    isNormalUser = true;
    description = "Nix";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    home = "/home/nix";
    hashedPassword = "";
  };

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "24.11";
}
