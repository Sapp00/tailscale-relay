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
  };

  # enable reverse proxy
  services.nginx = {
    enable = true;

    streamConfig = ''
      server {
        listen 443;
        proxy_pass 10.10.1.100:443;
        proxy_timeout 20s;
        proxy_ssl_server_name on;
      }
    '';
    logError = "stderr debug";

    #virtualHosts."internal" = {
    #  listen = [ 443 ];
    #  ssl = true;
    #  locations."/".proxyPass = "https://10.10.1.100";

    #  locations."/".extraConfig = ''
    #    proxy_ssl_verify off;
    #    proxy_ssl_server_name on;
    #  '';
    #};
  };

  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    servers = [ "10.100.10.1" ];
    settings.address = [ "/*.internal/100.64.125.40" ];
  };

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
      timeout = 0;
    };
  };

  # Enable SSH for remote management (optional)
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };

  # as default, the passwort is "test". crazy secure, so you better change it in prod. 
  users.users.nixos = {
    isNormalUser = true;
    description = "Nix";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    home = "/home/nix";
    hashedPassword = "ab12312";
  };
  security.sudo.wheelNeedsPassword = false;

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "24.11";
}
