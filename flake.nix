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
      hardware = import ./hardware;
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs [ system.x86_64-linux ];

      packages = eachSystem (system: import ./packages {
        pkgs = import nixpkgs { inherit system; };
        craneLib = crane.lib.${system};
      });
      pkgs-unstable = eachSystem (system: import nixpkgs-unstable { inherit system; });

      nixosModules = hostName: [
        ({ ... }: { networking.hostName = hostName; })
        impermanence.nixosModules.impermanence
        ./lib
        ./hosts/${hostName}.nix
      ];
      nixosSpecialArgs = system: {
        inherit inputs;
        pkgs-iliana = packages.${system};
        pkgs-unstable = pkgs-unstable.${system};
      };
    in
    {
      inherit packages;

      nixosConfigurations =
        let
          host = system: hardware: { inherit system hardware; };
        in
        builtins.mapAttrs
          (hostName: { system, hardware }: lib.nixosSystem {
            inherit system;
            modules = nixosModules hostName ++ [ hardware ];
            specialArgs = nixosSpecialArgs system;
          })
          {
            hydrangea = host system.x86_64-linux hardware.virt-v1;
            megaera = host system.x86_64-linux hardware.virt-v1;
          };

      checks =
        let
          inherit (import (nixpkgs + "/nixos/lib") { }) runTest;
        in
        {
          ${system.x86_64-linux}.pdns = runTest {
            name = "pdns";
            hostPkgs = import nixpkgs { system = system.x86_64-linux; };

            nodes.megaera = { ... }: {
              imports = nixosModules "megaera" ++ [ hardware.test ];
            };
            node.specialArgs = nixosSpecialArgs system.x86_64-linux;

            testScript = ''
              megaera.start()
              megaera.wait_for_unit("pdns")
            '';
          };
        };
    };
}
