{
  inputs = {
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
    emojos-dot-in.url = "github:iliana/emojos.in";
    emojos-dot-in.flake = false;
    oxide-cli.url = "github:oxidecomputer/oxide.rs";
    oxide-cli.flake = false;
  };

  outputs = {
    crane,
    emojos-dot-in,
    impermanence,
    nixpkgs,
    nixpkgs-unstable,
    oxide-cli,
    rust-overlay,
    tailscale,
    wrench,
    ...
  } @ inputs: let
    generated = wrench.lib.generate {
      systems = ["x86_64-linux"];

      packages = system: callPackage: let
        craneLib = crane.lib.${system};
        rust-bin = rust-overlay.packages.${system};
      in {
        emojos-dot-in = callPackage ./packages/emojos-dot-in.nix {inherit craneLib emojos-dot-in;};
        nix-eval-jobs = nixpkgs.legacyPackages.${system}.nix-eval-jobs;
        oxide = callPackage ./packages/oxide.nix {inherit craneLib oxide-cli rust-bin;};
        pkgf = callPackage ./packages/pkgf {inherit craneLib rust-bin;};
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
        hydrangea = ./hosts/hydrangea;
        kasou = ./hosts/kasou.nix;
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
  in
    generated
    // {
      hydraJobs = {
        inherit (generated) packages;
        nixosConfigurations = builtins.mapAttrs (_: sys: sys.config.system.build.toplevel) generated.nixosConfigurations;
      };
    };
}
