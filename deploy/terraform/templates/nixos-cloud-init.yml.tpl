#cloud-config
package_update: false
package_upgrade: false

runcmd:
  # Install nix if not present
  - |
    if ! command -v nix >/dev/null 2>&1; then
      curl -L https://nixos.org/nix/install | sh -s -- --daemon
      source /etc/profile.d/nix.sh
    fi
  
  # Enable flakes
  - mkdir -p /etc/nix
  - echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  
  # Download and apply the flake configuration
  - |
    cd /tmp
    git clone ${flake_url} tailscale-relay || true
    cd tailscale-relay
    
    # Generate hardware configuration
    nixos-generate-config --root /mnt --no-filesystems
    
    # Build and switch to the configuration
    nixos-rebuild switch --flake .#relay-node
  
  # Ensure services are started
  - systemctl enable tailscaled
  - systemctl start tailscaled
  - systemctl enable nginx
  - systemctl start nginx
  - systemctl enable dnsmasq
  - systemctl start dnsmasq

write_files:
  - path: /etc/nixos/hardware-configuration.nix
    content: |
      { config, lib, pkgs, modulesPath, ... }:
      {
        imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
        boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ ];
        boot.extraModulePackages = [ ];
        
        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        
        fileSystems."/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
        };
        
        swapDevices = [ ];
        networking.useDHCP = lib.mkDefault true;
        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.enableRedistributableFirmware = true;
      }