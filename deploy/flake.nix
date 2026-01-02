{
  description = "Deployment environment for Tailscale Relay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      
      # Terraform deployment script
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
        
        echo "📋 Planning deployment..."
        terraform plan -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
        
        echo ""
        read -p "🤔 Apply this plan? (yes/no): " response
        if [ "$response" = "yes" ]; then
          echo "🔧 Applying Terraform configuration..."
          terraform apply -auto-approve -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
          
          VM_IP=$(terraform output -raw vm_ip)
          echo "✅ Deployment complete!"
          echo "📍 VM IP: $VM_IP"
          echo "🔗 SSH to your VM:"
          echo "   ssh nixos@$VM_IP"
          
          # Cleanup
          rm -f /tmp/deployment-key /tmp/deployment-key.pub
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

      destroyScript = pkgs.writeShellScriptBin "destroy" ''
        set -e
        echo "🗑️ Destroying Tailscale Relay infrastructure"
        
        cd terraform
        
        # Generate temporary SSH key for compatibility
        ssh-keygen -t ed25519 -f /tmp/deployment-key -N "" -C "nixos-anywhere-deployment" 2>/dev/null || true
        DEPLOYMENT_PUBLIC_KEY=$(cat /tmp/deployment-key.pub 2>/dev/null || echo "dummy-key")
        
        echo "📋 Planning destruction..."
        terraform plan -destroy -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
        
        echo ""
        read -p "🤔 Destroy infrastructure? (yes/no): " response
        if [ "$response" = "yes" ]; then
          echo "🗑️ Destroying infrastructure..."
          terraform destroy -auto-approve -var="deployment_public_key=$DEPLOYMENT_PUBLIC_KEY"
          echo "✅ Infrastructure destroyed!"
        else
          echo "❌ Destruction cancelled."
        fi
        
        # Cleanup
        rm -f /tmp/deployment-key /tmp/deployment-key.pub
      '';
    in
    {
      # Development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (terraform.withPlugins (p: [ p.proxmox p.sops p.null p.external ]))
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
          echo "  nix run .#destroy - Destroy infrastructure"
          echo "  nix run .#init    - Initialize configuration"
        '';
      };
      
      # Apps for nix run
      apps.${system} = {
        deploy = {
          type = "app";
          program = "${deployScript}/bin/deploy";
        };
        destroy = {
          type = "app";
          program = "${destroyScript}/bin/destroy";
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
