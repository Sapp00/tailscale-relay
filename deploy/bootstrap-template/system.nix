{ lib, pkgs, ... }:

{
  networking.hostName = "nixos-bootstrap";
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks."10-eth" = {
      matchConfig.Name = "en*";
      networkConfig.DHCP = "yes";
    };
  };

  # kexec-capable kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
    "ds=nocloud;s=/dev/sr0"
  ];

  systemd.services."serial-getty@ttys0".enable = true;

  # Grub
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
    };
    initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" "9p" "9pnet_virtio" ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # qemu
  services.qemuGuest.enable = true;

  # cloud-init support
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [
    pkgs.cloud-init
  ];

  users.allowNoPasswordLogin = false;
  users.mutableUsers = true;

  system.stateVersion = "24.11";

  users.users.admin = {
    isNormalUser = true;
    description = "Default user for access";
    extraGroups = [ "wheel" ];
  };
}
