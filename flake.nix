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
      lib = nixpkgs.lib;
      inherit (flake-utils.lib) system;
      eachSystem = lib.genAttrs [ system.x86_64-linux ];

      pkgs = eachSystem (system: import nixpkgs { inherit system; });
      pkgs-unstable = eachSystem (system: import nixpkgs-unstable { inherit system; });
      pkgs-iliana = eachSystem (system: import ./packages {
        pkgs = pkgs.${system};
        craneLib = crane.lib.${system};
      });

      specialArgs = system: {
        inherit inputs;
        pkgs-iliana = pkgs-iliana.${system};
        pkgs-unstable = pkgs-unstable.${system};
      };
      hosts = import ./hosts {
        inherit system specialArgs nixpkgs impermanence;
      };
    in
    rec
    {
      packages = pkgs-iliana;

      nixosConfigurations = builtins.mapAttrs
        (_: { nixosConfig, ... }: nixosConfig)
        hosts;

      checks = import ./tests {
        inherit system hosts specialArgs nixpkgs;
      };

      defaultPackage = eachSystem (system: pkgs.${system}.linkFarm "ci" (lib.lists.flatten [
        (lib.attrsets.mapAttrsToList (name: drv: { name = "packages/${name}"; path = drv; }) pkgs-iliana.${system})
        (lib.attrsets.mapAttrsToList
          (name: drv: { name = "systems/${name}"; path = drv.config.system.build.toplevel; })
          (lib.attrsets.filterAttrs (name: _: hosts.${name}.system == system) nixosConfigurations))
        (lib.attrsets.mapAttrsToList (name: drv: { name = "checks/${name}"; path = drv; }) checks.${system})
      ]));

      formatter = eachSystem (system: pkgs.${system}.nixpkgs-fmt);
    };
}
