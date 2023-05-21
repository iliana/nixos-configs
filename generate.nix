# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
{
  flake-utils,
  nixpkgs,
  checks ? {},
  eachSystem ? (system: {}),
  nixosConfigurations ? {},
  nixosImports ? [],
  nixosSpecialArgs ? (system: {}),
  overlays ? [],
  packages ? (system: pkgs: {}),
  setHostName ? true,
  systems ? flake-utils.lib.defaultSystems,
  testModule ? ({...}: {}),
}: let
  lib = nixpkgs.lib;
  genSystems = lib.attrsets.genAttrs systems;

  pkgs = genSystems (system: import nixpkgs {inherit system overlays;});
  myPkgs = genSystems (system: packages system pkgs.${system});

  mySystems =
    lib.concatMapAttrs
    (system: systems:
      builtins.mapAttrs
      (name: config: {
        inherit system;
        modules =
          lib.lists.optionals setHostName [
            ({...}: {
              networking.hostName = name;
            })
          ]
          ++ nixosImports
          ++ [config];
      })
      systems)
    nixosConfigurations;
  specialArgs = genSystems (system:
    nixosSpecialArgs system
    // {
      myPkgs = myPkgs.${system};
    });

  myNixosConfigs =
    builtins.mapAttrs
    (name: attrs:
      lib.nixosSystem {
        inherit (attrs) system;
        modules = attrs.modules;
        specialArgs = specialArgs.${attrs.system};
      })
    mySystems;

  myChecks = let
    args = name: system:
      (builtins.mapAttrs
        (name: attrs: ({...}: {
          imports = attrs.modules ++ [testModule];
        }))
        mySystems)
      // {
        pkgs = pkgs.${system};
        runTest = (
          args:
            lib.nixos.runTest
            (lib.attrsets.recursiveUpdate
              {
                inherit name;
                hostPkgs = pkgs.${system};
                node.specialArgs = specialArgs.${system};
              }
              args)
        );
      };
  in
    builtins.mapAttrs
    (system: checks:
      builtins.mapAttrs (name: check:
        (
          if builtins.isPath check
          then import check
          else check
        ) (args name system))
      checks)
    checks;
in
  lib.attrsets.recursiveUpdate
  (flake-utils.lib.eachSystem systems eachSystem)
  {
    packages = myPkgs;
    nixosConfigurations = myNixosConfigs;
    checks = myChecks;
    hydraJobs = {
      packages = myPkgs;
      nixosConfigurations = builtins.mapAttrs (_: sys: sys.config.system.build.toplevel) myNixosConfigs;
      # checks = myChecks;
    };
  }
