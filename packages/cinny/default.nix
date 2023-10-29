{
  nixpkgs-unstable,
  callPackage,
}: let
  cinny = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/instant-messengers/cinny") {};
in
  cinny.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ./0001-remove-mod-number-shortcuts.patch
      ];
  })
