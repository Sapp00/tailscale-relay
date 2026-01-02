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
        
        echo "📋 Planning deployment..."
        terraform plan
        
        echo ""
        read -p "🤔 Apply this plan? (yes/no): " response
        if [ "$response" = "yes" ]; then
          echo "🔧 Applying Terraform configuration..."
          terraform apply -auto-approve
          
          VM_IP=$(terraform output -raw vm_ip)
          echo "✅ Deployment complete!"
          echo "📍 VM IP: $VM_IP"
          echo "🔗 SSH to your VM:"
          echo "   ssh nixos@$VM_IP"
        else
          echo "❌ Deployment cancelled."
        fi
      '';

      destroyScript = pkgs.writeShellScriptBin "destroy" ''
        set -e
        echo "🗑️ Destroying Tailscale Relay infrastructure"
        
        cd terraform
        
        echo "📋 Planning destruction..."
        terraform plan -destroy
        
        echo ""
        read -p "🤔 Destroy infrastructure? (yes/no): " response
        if [ "$response" = "yes" ]; then
          echo "🗑️ Destroying infrastructure..."
          terraform destroy -auto-approve
          echo "✅ Infrastructure destroyed!"
        else
          echo "❌ Destruction cancelled."
        fi
      '';
    in
    {
      # Development environment
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          (terraform.withPlugins (p: [ p.proxmox p.sops p.null p.external p.tls ]))
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
      };
      
      # Default app
      defaultApp.${system} = self.apps.${system}.deploy;
    };
}
