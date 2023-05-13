{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.url = "github:iliana/dotfiles?dir=.config/dotfiles&submodule=1";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    wrench.url = "github:iliana/wrench";
    wrench.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    agenix,
    crane,
    impermanence,
    nixpkgs,
    nixpkgs-unstable,
    wrench,
    ...
  } @ inputs:
    wrench.lib.generate {
      packages = system: callPackage: let
        craneLib = crane.lib.${system};
      in {
        caddy = callPackage ./packages/caddy.nix {};
        emojos-dot-in = callPackage ./packages/emojos-dot-in.nix {inherit craneLib;};
      };

      nixosImports = [
        agenix.nixosModules.age
        impermanence.nixosModules.impermanence
        ./lib
      ];
      nixosSpecialArgs = system: {
        inherit inputs;
        pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      };
      nixosConfigurations.x86_64-linux = {
        hydrangea = ./hosts/hydrangea;
        kasou = ./hosts/kasou.nix;
        megaera = ./hosts/megaera.nix;
        vermilion = ./hosts/vermilion.nix;
      };

      testModule = import ./lib/test.nix;
      checks.x86_64-linux = {
        hydrangea = ./tests/hydrangea.nix;
        pdns = ./tests/pdns.nix;
      };

      eachSystem = system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      };
    };
}
