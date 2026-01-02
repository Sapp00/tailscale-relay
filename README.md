# Tailscale Relay NixOS

A secure relay VM for accessing internal services remotely via Tailscale, without exposing them directly to the internet.

## Goal

Access internal services from anywhere while maintaining network segmentation and security. The relay VM acts as a secure intermediary that forwards requests to internal services via Tailscale.

Inspired by: https://heymann.dev/blog/tailscale-reverse-proxy/

## Quick Start

```bash
cd deploy
nix develop
nix run .#deploy   # Deploy to Proxmox
nix run .#destroy  # Destroy infrastructure
```

## Prerequisites

- Proxmox VE with NixOS cloud-init template (ID 116)
- SOPS encrypted secrets in `deploy/terraform/secrets.sops.json`
- Tailscale auth key

## Deployment Features

- **Ephemeral SSH Keys**: Auto-generated per deployment for security
- **Automated Installation**: Uses nixos-anywhere for declarative OS deployment
- **GitOps Ready**: All infrastructure defined in code
- **Encrypted Secrets**: SOPS integration for secure credential management
- **Cloud-init Integration**: Seamless VM bootstrapping

## Secrets Configuration

Create `deploy/terraform/secrets.sops.json` with:

```json
{
  "url": "https://proxmox.local",
  "port": 8006,
  "id": "terraform@pve",
  "token": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tailscale_key": "tskey-auth-xxxxx",
  "vm": {
    "ip": "10.100.10.2",
    "gateway": "10.100.10.1", 
    "nameserver": "10.100.10.1",
    "vlan": 100,
    "pve_node": "proxmox",
    "password": "bootstrap-password"
  }
}
```

Encrypt with: `sops -e secrets.json > secrets.sops.json`

## Architecture

- **Infrastructure**: Terraform with Proxmox provider
- **OS Deployment**: nixos-anywhere with disko for disk partitioning
- **VM Management**: Proxmox cloud-init for initial bootstrap
- **Relay Service**: Tailscale mesh networking
- **DNS Resolution**: Routes `*.internal` domains to internal services
- **Security**: Ephemeral keys, encrypted secrets, network segmentation

## Technical Details

The deployment automatically:
1. Generates ephemeral SSH key pair via Terraform TLS provider
2. Creates Proxmox VM with cloud-init configuration
3. Runs nixos-anywhere to install NixOS declaratively
4. Configures Tailscale relay with encrypted auth key
5. Sets up DNS forwarding and traffic routing

No manual SSH key management or VM template modification required.