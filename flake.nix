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
    , ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      inherit (flake-utils.lib) system;
      eachSystem = lib.genAttrs [ system.x86_64-linux ];

      packages = eachSystem (system: import ./packages {
        pkgs = import nixpkgs { inherit system; };
        craneLib = crane.lib.${system};
      });
      pkgs-unstable = eachSystem (system: import nixpkgs-unstable { inherit system; });

      specialArgs = system: {
        inherit inputs;
        pkgs-iliana = packages.${system};
        pkgs-unstable = pkgs-unstable.${system};
      };
      hosts = import ./hosts { inherit system inputs specialArgs; };
    in
    {
      inherit packages;
      nixosConfigurations = builtins.mapAttrs (_: { nixosConfig, ... }: nixosConfig) hosts;

      checks =
        let
          inherit (import (nixpkgs + "/nixos/lib") { }) runTest;
        in
        {
          ${system.x86_64-linux}.pdns = runTest {
            name = "pdns";
            hostPkgs = import nixpkgs { system = system.x86_64-linux; };

            nodes.megaera = hosts.megaera.testNode;
            node.specialArgs = specialArgs system.x86_64-linux;

            testScript = ''
              megaera.start()
              megaera.wait_for_unit("pdns")
            '';
          };
        };
    };
}
