{
  description = "Tailscale Relay Node for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tailscale = {
      url = "github:tailscale/tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, tailscale, disko, sops-nix, ... }@inputs: {
    nixosConfigurations = {
      relay-node = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Choose the architecture for your node
        specialArgs.inputs = inputs;
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./configuration.nix  # The relay node configuration
          { disko.devices.disk.disk1.device = "/dev/sda"; }
          ./hardware-configuration.nix
 #         tailscale.nixosModules.tailscale  # Import the Tailscale NixOS module
        ];
      };
    };
  };
}
