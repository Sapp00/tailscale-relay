#cloud-config
package_update: false
package_upgrade: false

write_files:
  # Write age private key for SOPS decryption
  - path: /var/lib/sops-nix/key.txt
    content: |
      ${age_private_key}
    permissions: '0600'
    owner: root:root
  
  # Write SOPS secrets file
  - path: /etc/nixos/secrets.yaml
    content: |
      ${indent(6, secrets_yaml)}
    permissions: '0600'
    owner: root:root
  
  # Write hardware configuration
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
    permissions: '0644'
    owner: root:root

runcmd:
  # Create necessary directories
  - mkdir -p /var/lib/sops-nix
  - mkdir -p /etc/nixos
  
  # Clone the flake repository
  - |
    cd /tmp
    git clone ${flake_path} tailscale-relay || git clone file://${flake_path} tailscale-relay || true
    cd tailscale-relay || true
    
    # Build and switch to the NixOS configuration
    nixos-rebuild switch --flake .#relay-node || true
  
  # Ensure critical services are enabled and started
  - systemctl enable tailscaled || true
  - systemctl start tailscaled || true
  - systemctl enable nginx || true
  - systemctl start nginx || true
  - systemctl enable dnsmasq || true
  - systemctl start dnsmasq || true