{
  description = "NixOS QCOW2 bootstrap image (cloud-init + kexec)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";
  };

  outputs = { self, nixpkgs, disko }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.bootstrap = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./system.nix
      ];
    };
  };
}
