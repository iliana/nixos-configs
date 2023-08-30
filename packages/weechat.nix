{
  nixpkgs-unstable,
  callPackage,
  guile_3_0,
}: let
  wrapWeechat = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/irc/weechat/wrapper.nix") {};
  weechat-unwrapped = callPackage (nixpkgs-unstable + "/pkgs/applications/networking/irc/weechat/") {
    guile = guile_3_0;
    # only used in darwin builds
    libobjc = null;
    libresolv = null;
  };
in
  wrapWeechat weechat-unwrapped {}
