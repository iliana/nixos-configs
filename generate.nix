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
  testModule ? (_: {}),
}: let
  inherit (nixpkgs) lib;
  genSystems = lib.attrsets.genAttrs systems;

  pkgs = genSystems (system: import nixpkgs {inherit system overlays;});
  myPkgs = genSystems (system: packages system pkgs.${system});

  mySystems =
    lib.concatMapAttrs
    (system:
      builtins.mapAttrs
      (name: config: {
        inherit system;
        modules =
          lib.lists.optionals setHostName [
            (_: {
              networking.hostName = name;
            })
          ]
          ++ nixosImports
          ++ [config];
      }))
    nixosConfigurations;
  specialArgs = genSystems (system:
    nixosSpecialArgs system
    // {
      myPkgs = myPkgs.${system};
    });

  myNixosConfigs =
    builtins.mapAttrs
    (_: attrs:
      lib.nixosSystem {
        inherit (attrs) modules system;
        specialArgs = specialArgs.${attrs.system};
      })
    mySystems;

  myChecks = let
    args = name: system:
      (builtins.mapAttrs
        (_: attrs: ({...}: {
          imports = attrs.modules ++ [testModule];
        }))
        mySystems)
      // {
        pkgs = pkgs.${system};
        runTest = args:
          lib.nixos.runTest
          (lib.attrsets.recursiveUpdate
            {
              inherit name;
              hostPkgs = pkgs.${system};
              node.specialArgs = specialArgs.${system};
            }
            args);
      };
  in
    builtins.mapAttrs
    (system:
      builtins.mapAttrs (name: check:
        (
          if builtins.isPath check
          then import check
          else check
        ) (args name system)))
    checks;

  myTailscalePolicy = lib.attrsets.genAttrs ["acls" "ssh"] (attr:
    lib.flatten (lib.mapAttrsToList
      (_: sys: sys.config.iliana.tailscale.policy."${attr}")
      myNixosConfigs));
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
      checks = myChecks;
    };
    tailscalePolicy = myTailscalePolicy;
  }
