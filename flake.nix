{
  inputs = {
    crane.url = "github:ipetkov/crane/v0.13.1";
    crane.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    dotfiles.url = "git+https://github.com/iliana/dotfiles?submodules=1";
    dotfiles.flake = false;
    emojos-dot-in.url = "github:iliana/emojos.in";
    emojos-dot-in.flake = false;
  };

  outputs = {
    crane,
    emojos-dot-in,
    impermanence,
    nixpkgs,
    nixpkgs-unstable,
    ...
  } @ inputs:
    import ./generate.nix {
      inherit inputs nixpkgs;

      systems = ["aarch64-linux" "x86_64-linux"];

      overlays = [
        (self: _: {craneLib = crane.mkLib self;})
      ];

      packages = system: pkgs:
        {
          inherit (pkgs) helix restic;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) nix-eval-jobs nvd;

          bandcamp-dl = pkgs.callPackage ./packages/bandcamp-dl.nix {};
          caddy = pkgs.callPackage ./packages/caddy.nix {inherit nixpkgs-unstable;};
          emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix {inherit emojos-dot-in;};
          litterbox = pkgs.callPackage ./packages/litterbox.nix {};
          oxide = pkgs.callPackage ./packages/oxide.nix {};
          pkgf = pkgs.callPackage ./packages/pkgf {};
          pounce = pkgs.callPackage ./packages/pounce.nix {};
          transmission = pkgs.callPackage ./packages/transmission {inherit nixpkgs-unstable;};
          weechat = pkgs.callPackage ./packages/weechat.nix {inherit nixpkgs-unstable;};
        };

      nixosImports = [
        impermanence.nixosModules.impermanence
        ./lib
      ];
      nixosConfigurations.aarch64-linux = {
        juice = ./hosts/juice;
        tisiphone = ./hosts/tisiphone.nix;
      };
      nixosConfigurations.x86_64-linux = {
        alecto = ./hosts/alecto;
        hydrangea = ./hosts/hydrangea;
        lernie = ./hosts/lernie.nix;
        megaera = ./hosts/megaera;
        mocha = ./hosts/mocha;
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
    };
}
