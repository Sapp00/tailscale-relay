# Proxmox API URL now comes from SOPS secrets (url field)

# Proxmox username not needed with API tokens

# Proxmox password/token now comes from SOPS secrets (token field)

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

# Target Proxmox node now comes from SOPS secrets (vm.pve_node)
# VM IP, nameserver now come from SOPS secrets

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "tailscale-relay"
}

variable "vm_memory" {
  description = "VM memory in MB"
  type        = number
  default     = 2048
}

variable "vm_cores" {
  description = "VM CPU cores"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "VM disk size"
  type        = string
  default     = "20G"
}

variable "storage_pool" {
  description = "Proxmox storage pool"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vm_netmask" {
  description = "VM network mask"
  type        = string
  default     = "24"
}

# VM gateway now comes from SOPS secrets (vm.gateway)

# VM password and SSH key now come from SOPS secrets

variable "flake_path" {
  description = "Path to the NixOS flake"
  type        = string
  default     = ".."
}

# Proxmox host now derived from SOPS url field

variable "deployment_public_key" {
  description = "Public SSH key for deployment access"
  type        = string
}