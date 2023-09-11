{
  hosts,
  pkgs,
}: let
  nixos-lib = import (pkgs.path + "/nixos/lib") {};
  nodes = builtins.mapAttrs (_: system: {imports = system._module.args.modules;}) hosts;
in
  name: testFunction: let
    test = testFunction (nodes // {inherit pkgs;});
  in
    nixos-lib.runTest {
      inherit name;
      inherit (test) nodes testScript;
      hostPkgs = pkgs;

      defaults = {
        config,
        lib,
        ...
      }: {
        # This statement in nixos/lib/testing/nixos-test-base:
        #     config.system.nixos.revision = mkForce "constant-nixos-revision";
        # does not actually make the nodes equivalent across otherwise-unchanged
        # nixpkgs revisions! So this is here instead.
        system.nixos.version = config.system.nixos.release;
      };
    }
