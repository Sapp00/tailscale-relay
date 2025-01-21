{
  description = "Tailscale Relay Node for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05"; # Nixpkgs version
    nixosModules.url = "github:nix-community/nixos-modules"; # Optional for custom modules

    # Tailscale flake input
    tailscale = {
      url = "github:tailscale/nix-tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, tailscale, ... }: {
    nixosConfigurations = {
      relay-node = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Choose the architecture for your node
        modules = [
          ./configuration.nix  # The relay node configuration
          tailscale.nixosModule  # Import the Tailscale NixOS module
        ];

        specialArgs = { inherit system; };
      };
    };
  };
}
