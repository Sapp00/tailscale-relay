{
  description = "Tailscale Relay Node for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale = {
      url = "github:tailscale/tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, tailscale, disko, ... }@inputs: {
    nixosConfigurations = {
      relay-node = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Choose the architecture for your node
        specialArgs.inputs = inputs;
        modules = [
          disko.nixosModules.disko
          ./configuration.nix  # The relay node configuration
          { disko.devices.disk.disk1.device = "/dev/sda"; }
 #         tailscale.nixosModules.tailscale  # Import the Tailscale NixOS module
        ];
      };
    };
  };
}
