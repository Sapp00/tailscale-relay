{
  description = "Deployment environment for Tailscale Relay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Terraform scripts
      deployScript = pkgs.writeShellScriptBin "deploy" ''
        set -e
        echo "🚀 Deploying Tailscale Relay to Proxmox"
        
        cd terraform
        
        echo "📦 Initializing Terraform..."
        terraform init
        
        # Generate fresh SSH key pair for deployment
        echo "🔑 Generating SSH key pair for deployment..."
        ssh-keygen -t ed25519 -f /tmp/deployment-key -N "" -C "nixos-anywhere-deployment"
        DEPLOYMENT_PUBLIC_KEY=$(cat /tmp/deployment-key.pub)
        
        # Extract SSH public keys and Tailscale key from SOPS
        echo "🔓 Extracting SSH public keys from SOPS..."
        SSH_KEYS=$(sops -d secrets.sops.json | jq -r '.public_keys | join("\n")')
        TAILSCALE_KEY=$(sops -d secrets.sops.json | jq -r '.tailscale_key')
        echo "SSH Keys: $(echo "$SSH_KEYS" | wc -l) keys extracted"
        echo "Tailscale Key: $(echo $TAILSCALE_KEY | cut -c1-20)..." # Show only first 20 chars
        
        echo "📋 Planning deployment..."
        terraform plan -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
        
        echo ""
        read -p "🤔 Apply this plan? (yes/no): " response
        if [ "$response" = "yes" ]; then
          echo "🗑️ Destroying any existing VMs first..."
          terraform destroy -auto-approve -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY" || true
          echo "🔧 Applying Terraform configuration..."
          terraform apply -auto-approve -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
          
          VM_IP=$(terraform output -raw vm_ip)
          echo "✅ VM created at $VM_IP"
          
          echo "⏳ Waiting for VM to be ready..."
          
          # Wait for NixOS bootstrap VM SSH (admin user)
          while ! ssh -i /tmp/deployment-key -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no admin@$VM_IP exit 2>/dev/null; do
            sleep 5
            echo "   Still waiting for NixOS bootstrap SSH..."
          done
          
          echo "🔧 Installing NixOS with nixos-anywhere..."
          # Prepare SSH keys file for deployment
          mkdir -p /tmp/nixos-files/home/nixos/.ssh
          # Write SSH keys directly (they should already be newline-separated from jq)
          echo "$SSH_KEYS" > /tmp/nixos-files/home/nixos/.ssh/authorized_keys
          chmod 600 /tmp/nixos-files/home/nixos/.ssh/authorized_keys
          
          # Prepare Tailscale auth key file for deployment
          mkdir -p /tmp/nixos-files/etc/tailscale
          echo "$TAILSCALE_KEY" > /tmp/nixos-files/etc/tailscale/auth-key
          chmod 600 /tmp/nixos-files/etc/tailscale/auth-key
          
          echo "🔍 Debug: SSH keys file content:"
          cat /tmp/nixos-files/home/nixos/.ssh/authorized_keys
          echo "📏 File size: $(wc -c < /tmp/nixos-files/home/nixos/.ssh/authorized_keys) bytes"
          
          # Add SSH connection resilience with more aggressive settings
          export NIX_SSHOPTS="-o ServerAliveInterval=5 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -o ConnectionAttempts=5 -o TCPKeepAlive=yes -o Compression=yes"
          
          # Retry nixos-anywhere up to 3 times on connection failures
          for attempt in 1 2 3; do
            echo "🔄 nixos-anywhere attempt $attempt/3..."
            if ${pkgs.nixos-anywhere}/bin/nixos-anywhere -i /tmp/deployment-key --extra-files /tmp/nixos-files --flake ../..#relay-node admin@$VM_IP; then
              echo "✅ nixos-anywhere completed successfully on attempt $attempt"
              break
            else
              echo "❌ nixos-anywhere attempt $attempt failed"
              if [ $attempt -eq 3 ]; then
                echo "💥 All nixos-anywhere attempts failed"
                exit 1
              fi
              echo "⏳ Waiting 30 seconds before retry..."
              sleep 30
            fi
          done
          
          # Cleanup
          rm -f /tmp/deployment-key /tmp/deployment-key.pub
          rm -rf /tmp/nixos-files
          
          echo "✅ NixOS installation complete!"
          echo "📍 VM IP: $VM_IP"
          echo "🔗 SSH to your VM:"
          echo "   ssh nixos@$VM_IP"
        else
          echo "❌ Deployment cancelled."
        fi
      '';
      
      initScript = pkgs.writeShellScriptBin "init" ''
        set -e
        echo "🔧 Initializing Terraform configuration"
        
        echo "✅ terraform.tfvars already configured"
        echo "🔑 Make sure your SOPS secrets are set up with:"
        echo "   - Proxmox API credentials (url, token)"
        echo "   - VM configuration (ip, gateway, nameserver, etc.)"
        echo "   - Access credentials (password, ssh_public_key)"
        echo ""
        echo "🚀 Ready to deploy with: nix run .#deploy"
      '';
    in
    {
      # Development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          terraform
          git
          openssh
          curl
          sops
          age
          nixos-anywhere
          jq
        ];
        
        shellHook = ''
          echo "🔧 Tailscale Relay Deployment Environment"
          echo "Available commands:"
          echo "  nix run .#deploy  - Deploy to Proxmox"
          echo "  nix run .#init    - Initialize configuration"
        '';
      };
      
      # Apps for nix run
      apps.${system} = {
        deploy = {
          type = "app";
          program = "${deployScript}/bin/deploy";
        };
        init = {
          type = "app";
          program = "${initScript}/bin/init";
        };
      };
      
      # Default app
      defaultApp.${system} = self.apps.${system}.deploy;
    };
}
