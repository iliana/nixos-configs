{
  inputs = {
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    tailscale.url = "github:tailscale/tailscale/release-branch/1.42";
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
    rust-overlay,
    tailscale,
    ...
  } @ inputs:
    import ./generate.nix {
      inherit flake-utils nixpkgs;

      systems = ["x86_64-linux"];
      overlays = [rust-overlay.overlays.default];

      packages = system: pkgs: let
        craneLib = (crane.mkLib pkgs).overrideToolchain pkgs.rust-bin.stable."1.69.0".minimal;
      in {
        emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix {inherit craneLib emojos-dot-in;};
        nix-eval-jobs = pkgs.nix-eval-jobs;
        nvd = pkgs.nvd;
        oxide = pkgs.callPackage ./packages/oxide.nix {inherit craneLib oxide-cli;};
        pkgf = pkgs.callPackage ./packages/pkgf {inherit craneLib;};
        restic = pkgs.restic;
        tailscale = tailscale.packages.${system}.tailscale;
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
        alecto = ./hosts/alecto.nix;
        hydrangea = ./hosts/hydrangea;
        kasou = ./hosts/kasou.nix;
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
