{ 
  modulesPath, 
  lib,
  pkgs, 
  ... 
}:

let
  # Traefik's external IP, adjust as needed.
  traefikIP = "10.10.1.100";
in
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  # Networking and firewall configuration
  networking.firewall.allowedTCPPorts = [
    443  # HTTPS port for Traefik
  ];

  networking.interfaces.enp0s3.ipAddress = "10.100.10.2";  # Set a static IP for this machine, if needed
  networking.defaultGateway = "10.100.10.1";  # Set your gateway

  # Optional: Configure DNS for Tailscale network
  networking.nameservers = [ "10.100.10.1" ];  # Replace with your DNS server or Tailscale DNS

  # Enable SSH for remote management (optional)
  services.openssh.enable = true;

  boot = {
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
      };
      timeout = 0;
    };

    #initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    #initrd.kernelModules = [];

    #initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
    #initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" "virtio_gpu" ];
  };

  hardware.enableRedistributableFirmware = true;

  # System settings
  system.stateVersion = "24.11";  # Adjust to your NixOS version
}
