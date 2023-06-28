{
  inputs = {
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    tailscale.url = "github:tailscale/tailscale/v1.44.0";
    tailscale.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:iliana/dotfiles?submodule=1";
    dotfiles.flake = false;
    emojos-dot-in.url = "github:iliana/emojos.in";
    emojos-dot-in.flake = false;
    oxide-cli.url = "github:oxidecomputer/oxide.rs";
    oxide-cli.flake = false;
  };

  outputs = {
    crane,
    emojos-dot-in,
    flake-utils,
    impermanence,
    nixpkgs,
    nixpkgs-unstable,
    oxide-cli,
    tailscale,
    ...
  } @ inputs:
    import ./generate.nix {
      inherit flake-utils nixpkgs;

      systems = ["aarch64-linux" "x86_64-linux"];

      packages = system: pkgs: let
        craneLib = crane.mkLib pkgs;
      in ({
          nix-eval-jobs = pkgs.nix-eval-jobs;
          nvd = pkgs.nvd;
          restic = pkgs.restic;

          helix = nixpkgs-unstable.legacyPackages.${system}.helix;
          tailscale = tailscale.packages.${system}.tailscale;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          caddy = pkgs.callPackage ./packages/caddy.nix {};
          emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix {inherit craneLib emojos-dot-in;};
          litterbox = pkgs.callPackage ./packages/litterbox.nix {};
          oxide = pkgs.callPackage ./packages/oxide.nix {inherit craneLib oxide-cli;};
          pkgf = pkgs.callPackage ./packages/pkgf {inherit craneLib;};
          pounce = pkgs.callPackage ./packages/pounce.nix {};
        });

      nixosImports = [
        impermanence.nixosModules.impermanence
        ./lib
      ];
      nixosSpecialArgs = system: {
        inherit inputs;
      };
      nixosConfigurations.aarch64-linux = {
        tisiphone = ./hosts/tisiphone.nix;
      };
      nixosConfigurations.x86_64-linux = {
        alecto = ./hosts/alecto;
        hydrangea = ./hosts/hydrangea;
        kasou = ./hosts/kasou;
        lernie = ./hosts/lernie.nix;
        megaera = ./hosts/megaera.nix;
        vermilion = ./hosts/vermilion;
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
