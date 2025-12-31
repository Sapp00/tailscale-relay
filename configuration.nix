{ 
  modulesPath, 
  lib,
  pkgs, 
  ... 
}:

let
  traefikIP = "10.10.1.100";
  dnsServer = "10.100.10.1";
  tailscaleIP = "100.64.125.40";
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
    hostName = "tailscale-relay";
    firewall.allowedTCPPorts = [
      53 # DNS port
      443  # HTTPS port for Traefik
    ];
    
    # Use cloud-init for network configuration
    useNetworkd = true;
    useDHCP = false;
  };
  
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };
  
  # Cloud-init support
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  # enable reverse proxy
  services.nginx = {
    enable = true;

    streamConfig = ''
      server {
        listen 443;
        proxy_pass ${traefikIP}:443;
        proxy_timeout 20s;
        proxy_ssl_server_name on;
      }
    '';
    logError = "stderr debug";
  };

  # Disable systemd-resolved to free up port 53
  services.resolved.enable = false;
  
  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    settings.server = [ dnsServer ];
    settings.address = [ "/*.internal/${tailscaleIP}" ];
  };

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
    };
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
  };

  # Enable SSH for remote management (optional)
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # as default, the passwort is "test". crazy secure, so you better change it in prod. 
  users.users.nixos = {
    isNormalUser = true;
    description = "Nix";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    home = "/home/nixos";
    # SSH keys will be deployed via --extra-files and fixed with systemd service
  };

  # Fix SSH key ownership deployed via --extra-files
  systemd.services.fix-ssh-keys = {
    description = "Fix SSH key ownership for nixos user";
    wantedBy = [ "multi-user.target" ];
    after = [ "users.target" ];
    script = ''
      if [ -f /home/nixos/.ssh/authorized_keys ]; then
        chown nixos:users /home/nixos/.ssh/authorized_keys
        chmod 600 /home/nixos/.ssh/authorized_keys
        chown nixos:users /home/nixos/.ssh
        chmod 700 /home/nixos/.ssh
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  hardware.enableRedistributableFirmware = true;

  system.stateVersion = "25.11";
}
