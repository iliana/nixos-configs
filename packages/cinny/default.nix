{
  nixpkgs-unstable,
  callPackage,
  lib,
}: let
  cinny = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/instant-messengers/cinny") {};
in
  cinny.overrideAttrs (old: {
    version =
      if (lib.hasInfix "-b v${old.version}" (builtins.readFile ./README.md))
      then "${old.version}-iliana"
      else builtins.throw "update the version in packages/cinny/README.md";
    patches =
      (old.patches or [])
      ++ [
        ./0001-indicate-this-is-a-fork.patch
        ./0002-remove-mod-number-shortcuts.patch
      ];
  })
