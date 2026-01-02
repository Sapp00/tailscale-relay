resource "proxmox_virtual_environment_vm" "tailscale_relay" {
  name      = var.vm_name
  node_name = data.sops_file.secrets.data["vm.pve_node"]
  
  cpu {
    cores = var.vm_cores
    type  = "host"
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  # Clone from NixOS bootstrap template
  clone {
    vm_id = 116
  }
  
  network_device {
    bridge  = var.network_bridge
    vlan_id = data.sops_file.secrets.data["vm.vlan"]
  }
  
  initialization {
    ip_config {
      ipv4 {
        address = "${data.sops_file.secrets.data["vm.ip"]}/${var.vm_netmask}"
        gateway = data.sops_file.secrets.data["vm.gateway"]
      }
    }
    
    dns {
      servers = [data.sops_file.secrets.data["vm.nameserver"]]
    }
    
    user_account {
      username = "admin"
      keys     = [tls_private_key.deployment.public_key_openssh]
    }
  }
  
  operating_system {
    type = "l26"
  }
  
  # Use SeaBIOS to match template
  bios = "seabios"
  
}

# Output the VM's IP address
output "vm_ip" {
  value = data.sops_file.secrets.data["vm.ip"]
  sensitive = true
}
