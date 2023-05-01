{ system, hosts, specialArgs, nixpkgs }:
let
  tests = {
    ${system.x86_64-linux} = {
      pdns = ./pdns.nix;
    };
  };

  nodes = builtins.mapAttrs
    (_: { testNode, ... }: testNode)
    hosts;
  nixos-lib = import (nixpkgs + "/nixos/lib") { };
in
builtins.mapAttrs
  (system: systemTests:
  let
    hostPkgs = import nixpkgs { inherit system; };
  in
  builtins.mapAttrs
    (name: test: nixos-lib.runTest (import test nodes // {
      inherit name hostPkgs;
      node.specialArgs = specialArgs system;
    }))
    systemTests)
  tests
