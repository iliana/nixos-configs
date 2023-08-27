# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
{
  nixpkgs,
  checks ? {},
  nixosConfigurations ? {},
  nixosImports ? [],
  nixosSpecialArgs ? (system: {}),
  overlays ? [],
  packages ? (system: pkgs: {}),
  systems,
  testModule ? (_: {}),
}: let
  inherit (nixpkgs) lib;
  eachSystem = lib.attrsets.genAttrs systems;

  pkgs = eachSystem (system: import nixpkgs {inherit system overlays;});
  myPkgs = eachSystem (system: packages system pkgs.${system});

  mySystems =
    lib.concatMapAttrs
    (system:
      builtins.mapAttrs
      (name: config: {
        inherit system;
        modules =
          [
            (_: {
              networking.hostName = name;
            })
          ]
          ++ nixosImports
          ++ [config];
      }))
    nixosConfigurations;
  specialArgs = eachSystem (system:
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

  myTailscalePolicy = let
    extraPolicy = import ./tailscale-policy.nix;
    configs =
      [
        # elaborate way of ensuring ./tailscale-policy.nix matches our schema
        (lib.nixosSystem {
          system = "x86_64-linux";
          modules = nixosImports ++ [{iliana.tailscale.policy = {inherit (extraPolicy) acls ssh tags;};}];
        })
      ]
      ++ builtins.attrValues myNixosConfigs;
    combinedPolicy =
      lib.attrsets.genAttrs ["acls" "ssh" "tags"]
      (attr: lib.concatMap (sys: sys.config.iliana.tailscale.policy.${attr}) configs);
  in {
    inherit (combinedPolicy) ssh;
    inherit (extraPolicy) tests;
    acls =
      builtins.map
      (acl:
        if acl.proto == ["tcp" "udp"]
        then builtins.removeAttrs acl ["proto"]
        else acl)
      combinedPolicy.acls;
    hosts = lib.importJSON ./lib/hosts.json;
    tagOwners = lib.genAttrs combinedPolicy.tags (_: ["iliana@github"]);
  };
in {
  packages = myPkgs;
  nixosConfigurations = myNixosConfigs;
  checks = myChecks;
  hydraJobs = {
    packages = myPkgs;
    nixosConfigurations = builtins.mapAttrs (_: sys: sys.config.system.build.toplevel) myNixosConfigs;
    checks = myChecks;
  };
  formatter = eachSystem (system: pkgs.${system}.alejandra);
  tailscalePolicy = myTailscalePolicy;
}
