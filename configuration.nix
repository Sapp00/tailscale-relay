{ config, pkgs, ... }:

let
  # Traefik's external IP, adjust as needed.
  traefikIP = "192.168.1.100";
in
{
  # Enable the Tailscale service
  services.tailscale = {
    enable = true;
    # Optional: Set the Tailscale authentication key if you prefer it
    authKey = null;  # Or replace with an actual auth key from Tailscale
  };

  # Networking and firewall configuration
  networking.firewall.allowedTCPPorts = [
    443  # HTTPS port for Traefik
  ];

  networking.interfaces.enp0s3.ipAddress = "192.168.1.200";  # Set a static IP for this machine, if needed
  networking.defaultGateway = "192.168.1.1";  # Set your gateway

  # Enable Disko for automated disk partitioning
  # You need to specify the disk device you want to partition, such as /dev/sda.
  # Example with a single disk setup:
  disko = {
    enable = true;

    # Define your partitioning scheme
    partitions = [
      # Partition 1: EFI System Partition (ESP)
      {
        mountPoint = "/boot";
        size = "512MB";
        fsType = "vfat";
        label = "EFI";
      }
      # Partition 2: Root filesystem
      {
        mountPoint = "/";
        size = "100%";  # Use the remaining space
        fsType = "ext4";  # Or any other filesystem you prefer
        label = "ROOT";
      }
    ];

    # Optionally, you can enable LVM or ZFS if you want to use advanced partitioning schemes
    # Use this section if you're interested in using LVM or ZFS
    # lvm.enable = true;
    # zfs.enable = true;
  };

  # Set up Tailscale iptables to forward traffic to Traefik
  systemd.services.tailscale-iptables = {
    description = "Configure iptables for Tailscale traffic forwarding";
    after = [ "tailscale.service" ];
    serviceConfig.ExecStart = ''
      iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 443 -j DNAT --to-destination ${traefikIP}:443
      iptables -A FORWARD -i tailscale0 -p tcp --dport 443 -j ACCEPT
    '';
  };

  # Optional: Configure DNS for Tailscale network
  networking.dns.nameservers = [ "100.100.100.100" ];  # Replace with your DNS server or Tailscale DNS

  # Enable SSH for remote management (optional)
  services.openssh.enable = true;

  # System settings
  system.stateVersion = "23.05";  # Adjust to your NixOS version
}
