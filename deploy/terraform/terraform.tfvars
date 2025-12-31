# Proxmox Configuration (API URL, token, node come from SOPS secrets)
proxmox_tls_insecure = true

# VM Configuration
vm_name       = "tailscale-relay"
vm_memory     = 4096
vm_cores      = 4
disk_size     = "20G"
storage_pool  = "local-lvm"
network_bridge = "vmbr0"

vm_netmask    = "24"
