{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    tailscale.url = "github:tailscale/tailscale/release-branch/1.40";
    tailscale.inputs.nixpkgs.follows = "nixpkgs";
    wrench.url = "github:iliana/wrench";
    wrench.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:iliana/dotfiles?submodule=1";
    dotfiles.flake = false;
    oxide-cli.url = "github:oxidecomputer/oxide.rs";
    oxide-cli.flake = false;
  };

  outputs = {
    agenix,
    crane,
    impermanence,
    nixpkgs,
    nixpkgs-unstable,
    oxide-cli,
    rust-overlay,
    tailscale,
    wrench,
    ...
  } @ inputs:
    wrench.lib.generate {
      packages = system: callPackage: let
        craneLib = crane.lib.${system};
        rust-bin = rust-overlay.packages.${system};
      in {
        caddy = callPackage ./packages/caddy.nix {};
        emojos-dot-in = callPackage ./packages/emojos-dot-in.nix {inherit craneLib;};
        oxide = callPackage ./packages/oxide.nix {inherit craneLib oxide-cli rust-bin;};
        tailscale = tailscale.packages.${system}.tailscale;
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
