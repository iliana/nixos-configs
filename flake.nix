{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    impermanence.url = "github:nix-community/impermanence";

    dotfiles.url = "github:iliana/dotfiles?dir=.config/dotfiles&submodule=1";
  };

  outputs =
    { nixpkgs
    , nixpkgs-unstable
    , crane
    , flake-utils
    , impermanence
    , ...
    }@inputs:
    let
      inherit (flake-utils.lib) system;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs [ system.x86_64-linux ];

      packages = eachSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          craneLib = crane.lib.${system};
        in
        {
          emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix { inherit craneLib; };
        });
      pkgs-unstable = eachSystem (system: import nixpkgs-unstable { inherit system; });

      hosts = builtins.mapAttrs (hostName: system: lib.nixosSystem {
        inherit system;
        modules = [
          impermanence.nixosModules.impermanence
          ./lib
          ./hosts/${hostName}.nix
        ];
        specialArgs = {
          inherit hostName inputs;
          pkgs-iliana = packages.${system};
          pkgs-unstable = pkgs-unstable.${system};
        };
      });
    in
    {
      inherit packages;

      nixosConfigurations = hosts {
        hydrangea = system.x86_64-linux;
      };
    };
}
