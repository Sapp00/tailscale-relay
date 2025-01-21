{
  description = "Tailscale Relay Node for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05"; # Nixpkgs version
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
          ./disko-config.nix
          {
            _module.args.disks = [ "/dev/vda" ];
          }
          ./configuration.nix  # The relay node configuration
          tailscale.nixosModules.tailscale  # Import the Tailscale NixOS module
        ];
      };
    };
  };
}
