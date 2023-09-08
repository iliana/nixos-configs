{
  nixpkgs-unstable,
  callPackage,
}:
callPackage (nixpkgs-unstable + "/pkgs/servers/caddy") {}
