module "nixos_deploy" {
  source = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  
  # Wait for VM to be created
  depends_on = [proxmox_virtual_environment_vm.tailscale_relay]
  
  # NixOS configuration
  nixos_system_attr = ".#nixosConfigurations.relay-node.config.system.build.toplevel"
  nixos_partitioner_attr = ".#nixosConfigurations.relay-node.config.system.build.diskoScript"
  
  # Target configuration
  target_host = data.sops_file.secrets.data["vm.ip"]
  instance_id = tostring(proxmox_virtual_environment_vm.tailscale_relay.vm_id)
  
  # SSH configuration
  target_user = "admin"  # Bootstrap user from template
  
  # Extra files for SSH keys and Tailscale auth
  extra_files_script = "${path.module}/prepare-files.sh"
  
  # Build locally instead of on target
  build_on_remote = false
  
  # Working directory for NixOS configuration
  flake = "${path.module}/../.."
}