{
  nixpkgs-unstable,
  callPackage,
}: let
  libutp = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/p2p/libutp/3.4.nix") {};
  transmission = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/p2p/transmission/4.nix") {inherit libutp;};
in
  transmission.overrideAttrs (old: {
    patches = [
      ./5460.patch
      ./5619.patch
      ./5644.patch
      ./5645.patch
    ];
  })
