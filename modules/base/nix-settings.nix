{
  config,
  pkgs,
  ...
}: {
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
    substituters = ["https://iliana.cachix.org"];
    trusted-public-keys = ["iliana.cachix.org-1:Az1O3w/Y4SQ4v581CPJQmfacPd363WBjDxdaf9uhnD4="];

    # Remove the default flake registry.
    flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
      flakes = [];
      version = 2;
    });
  };

  # Allow referencing `nixpkgs` via the registry, but from the release branch we're currently on.
  nix.registry.nixpkgs.to = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-${config.system.nixos.release}";
  };

  nix.gc = {
    automatic = true;
    dates = "10:30";
    options = "--delete-older-than 2d";
    randomizedDelaySec = "45min";
  };
}
