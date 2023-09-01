{
  config,
  pkgs,
  ...
}: {
  # Remove the default flake registry.
  nix.settings.flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
    flakes = [];
    version = 2;
  });
  # Add `nixpkgs` back, but from the release branch we're currently on.
  nix.registry.nixpkgs.to = {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    ref = "nixos-${config.system.nixos.release}";
  };
}
