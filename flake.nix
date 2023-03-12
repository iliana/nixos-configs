{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { nixpkgs, nixpkgs-unstable, impermanence, ... }@inputs: {
    nixosConfigurations = {
      hydrangea = let system = "x86_64-linux"; in nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./systems/hydrangea.nix
          impermanence.nixosModules.impermanence
        ];
        specialArgs = {
          inherit inputs;
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        };
      };
    };
  };
}
