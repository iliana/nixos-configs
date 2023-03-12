{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, impermanence }@inputs: {
    nixosConfigurations = {
      hydrangea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./systems/hydrangea.nix
          impermanence.nixosModules.impermanence
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}
