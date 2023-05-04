{
  inputs = {
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.url = "github:iliana/dotfiles?dir=.config/dotfiles&submodule=1";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    wrench.url = "github:iliana/wrench";
    wrench.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { crane, impermanence, nixpkgs-unstable, wrench, ... }@inputs: wrench.lib.generate {
    systems = [ "x86_64-linux" ];

    packages = system: callPackage:
      let
        craneLib = crane.lib.${system};
      in
      {
        emojos-dot-in = callPackage ./packages/emojos-dot-in.nix { inherit craneLib; };
      };

    nixosImports = [
      impermanence.nixosModules.impermanence
      ./lib
    ];
    nixosSpecialArgs = system: {
      inherit inputs;
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
    };
    nixosConfigurations.x86_64-linux = {
      hydrangea = ./hosts/hydrangea.nix;
      megaera = ./hosts/megaera.nix;
    };

    testModule = import ./lib/test.nix;
    checks.x86_64-linux = {
      hydrangea = ./tests/hydrangea.nix;
      pdns = ./tests/pdns.nix;
    };
  };
}
