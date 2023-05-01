{ pkgs, craneLib }: {
  emojos-dot-in = pkgs.callPackage ./emojos-dot-in.nix { inherit craneLib; };
}
