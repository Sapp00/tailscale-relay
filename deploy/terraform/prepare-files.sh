#!/usr/bin/env bash
set -euo pipefail

# This script prepares the extra files for nixos-anywhere deployment
# It reads secrets from SOPS and creates the necessary files

NIXOS_ANYWHERE_TMP_DIR="${NIXOS_ANYWHERE_TMP_DIR:-/tmp/nixos-anywhere-files}"

# Extract secrets from SOPS
SSH_KEYS=$(sops -d secrets.sops.json | jq -r '.public_keys | join("\n")')
TAILSCALE_KEY=$(sops -d secrets.sops.json | jq -r '.tailscale_key')

# Prepare SSH keys
mkdir -p "$NIXOS_ANYWHERE_TMP_DIR/home/nixos/.ssh"
echo "$SSH_KEYS" > "$NIXOS_ANYWHERE_TMP_DIR/home/nixos/.ssh/authorized_keys"
chmod 600 "$NIXOS_ANYWHERE_TMP_DIR/home/nixos/.ssh/authorized_keys"

# Prepare Tailscale auth key
mkdir -p "$NIXOS_ANYWHERE_TMP_DIR/etc/tailscale"
echo "$TAILSCALE_KEY" > "$NIXOS_ANYWHERE_TMP_DIR/etc/tailscale/auth-key"
chmod 600 "$NIXOS_ANYWHERE_TMP_DIR/etc/tailscale/auth-key"

echo "Files prepared in $NIXOS_ANYWHERE_TMP_DIR"