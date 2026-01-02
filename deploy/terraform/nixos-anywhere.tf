module "deploy" {
  source = "github.com/sapp00/nixos-anywhere//terraform/all-in-one"
  
  # Wait for VM to be created
  depends_on = [proxmox_virtual_environment_vm.tailscale_relay]
  
  # NixOS configuration - use git+file URL to specify the parent directory
  nixos_system_attr = "git+file://${abspath(path.module)}/../../#nixosConfigurations.relay-node.config.system.build.toplevel"
  nixos_partitioner_attr = "git+file://${abspath(path.module)}/../../#nixosConfigurations.relay-node.config.system.build.diskoScript"
  
  # Target configuration - use nonsensitive() to allow debug output
  target_host = nonsensitive(data.sops_file.secrets.data["vm.ip"])
  instance_id = tostring(proxmox_virtual_environment_vm.tailscale_relay.vm_id)
  
  # SSH configuration for initial connection (bootstrap user)
  install_user = "admin"
  install_ssh_key = nonsensitive(tls_private_key.deployment.private_key_openssh)

  target_user = "nixos"
  
  extra_files_script = "${path.module}/prepare-files.sh"
  
  #phases = ["kexec", "disko", "install", "reboot"]
  phases = ["kexec", "disko", "install"]
  
  # Enable debug logging to see what's happening
  debug_logging = true
}
