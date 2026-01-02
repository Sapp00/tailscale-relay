# Tailscale Relay NixOS

A secure relay VM for accessing internal services remotely via Tailscale, without exposing them directly to the internet.

## Goal

Access internal services from anywhere while maintaining network segmentation and security. The relay VM acts as a secure intermediary that forwards requests to internal services via Tailscale.

Inspired by: https://heymann.dev/blog/tailscale-reverse-proxy/

## Quick Start

```bash
cd deploy
nix develop
nix run .#init     # First time setup
nix run .#deploy   # Deploy to Proxmox
nix run .#destroy  # Destroy infrastructure
```

## Prerequisites

- Proxmox VE with NixOS template (ID 116)
- SOPS encrypted secrets in `deploy/terraform/secrets.sops.json`
- Tailscale auth key

## Secrets Configuration

```json
{
  "url": "https://proxmox:8006",
  "token": "api-token",
  "tailscale_key": "tskey-auth-xxxxx",
  "public_keys": ["ssh-ed25519 AAAAC..."],
  "vm": {
    "ip": "10.100.10.5",
    "gateway": "10.100.10.1",
    "pve_node": "node-name"
  }
}
```

## Architecture

- **Declarative Infrastructure**: Terraform with nixos-anywhere provider
- **Relay VM**: Connects to Tailscale network
- **DNS Resolution**: Routes `*.internal` domains to internal IP  
- **HTTPS Proxy**: Forwards traffic to internal reverse proxy
- **Security**: No direct service exposure, encrypted secrets

The VM provides secure remote access to internal services without compromising network boundaries. Deployment is fully automated and reproducible using GitOps principles.