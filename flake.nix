{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { nixpkgs, nixpkgs-unstable, impermanence, ... }@inputs:
    let
      lib = nixpkgs.lib;
      systems = system: hosts: lib.attrsets.genAttrs hosts (host: lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/${host}.nix
          impermanence.nixosModules.impermanence
        ];
        specialArgs = {
          inherit inputs;
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        };
      });
    in
    {
      nixosConfigurations = systems "x86_64-linux" [
        "hydrangea"
      ];
    };
}
