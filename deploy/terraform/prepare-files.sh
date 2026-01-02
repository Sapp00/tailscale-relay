#!/usr/bin/env bash
set -euo pipefail

# This script prepares the extra files for nixos-anywhere deployment
# It reads secrets from SOPS and creates the necessary files

# Get the script directory to find secrets.sops.json
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_FILE="$SCRIPT_DIR/secrets.sops.json"

# The working directory where nixos-anywhere expects files
WORK_DIR="${PWD}"

# Extract secrets from SOPS
SSH_KEYS=$(sops -d "$SECRETS_FILE" | jq -r '.public_keys | join("\n")')
TAILSCALE_KEY=$(sops -d "$SECRETS_FILE" | jq -r '.tailscale_key')

# Prepare SSH keys
mkdir -p "$WORK_DIR/home/nixos/.ssh"
echo "$SSH_KEYS" > "$WORK_DIR/home/nixos/.ssh/authorized_keys"
chmod 600 "$WORK_DIR/home/nixos/.ssh/authorized_keys"

# Prepare Tailscale auth key
mkdir -p "$WORK_DIR/etc/tailscale"
echo "$TAILSCALE_KEY" > "$WORK_DIR/etc/tailscale/auth-key"
chmod 600 "$WORK_DIR/etc/tailscale/auth-key"

echo "Files prepared in $WORK_DIR"