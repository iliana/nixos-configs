{
  inputs = {
    crane.url = "github:ipetkov/crane";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    dotfiles.url = "git+https://github.com/iliana/dotfiles?submodules=1";
    dotfiles.flake = false;
    emojos-dot-in.url = "github:iliana/emojos.in";
    emojos-dot-in.flake = false;
    oxide-cli.url = "github:oxidecomputer/oxide.rs/v0.1.0-beta.3";
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
    ...
  } @ inputs:
    import ./generate.nix {
      inherit flake-utils nixpkgs;

      systems = ["aarch64-linux" "x86_64-linux"];

      packages = system: pkgs: let
        craneLib = crane.mkLib pkgs;
      in
        {
          inherit (pkgs) helix restic;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) nix-eval-jobs nvd;
          inherit (nixpkgs-unstable.legacyPackages.${system}) weechat;

          bandcamp-dl = pkgs.callPackage ./packages/bandcamp-dl.nix {};
          caddy = pkgs.callPackage ./packages/caddy.nix {};
          emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix {inherit craneLib emojos-dot-in;};
          litterbox = pkgs.callPackage ./packages/litterbox.nix {};
          oxide = pkgs.callPackage ./packages/oxide.nix {inherit craneLib oxide-cli;};
          pkgf = pkgs.callPackage ./packages/pkgf {inherit craneLib;};
          pounce = pkgs.callPackage ./packages/pounce.nix {};
          transmission = pkgs.callPackage ./packages/transmission.nix {inherit (nixpkgs-unstable.legacyPackages.${system}) transmission_4;};
        };

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
        lernie = ./hosts/lernie.nix;
        megaera = ./hosts/megaera.nix;
        poffertje = ./hosts/poffertje.nix;
        skyrabbit = ./hosts/skyrabbit;
        stroopwafel = ./hosts/stroopwafel;
        vermilion = ./hosts/vermilion;
      };

      testModule = import ./lib/test.nix;
      checks.x86_64-linux = {
        pdns = ./tests/pdns.nix;
        web = ./tests/web.nix;
      };

      eachSystem = system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      };
    };
}
