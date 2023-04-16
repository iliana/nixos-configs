{ pkgs, inputs, ... }:
let
  flakeDotNix = pkgs.writeText "flake.nix" ''
    {
      inputs.iliana.url = "github:iliana/nixos-configs";
      outputs = { iliana, ... }: iliana;
    }
  '';
in
{
  fileSystems."/etc/nixos/flake.nix" = {
    device = toString flakeDotNix;
    options = [ "bind" ];
  };

  iliana.persist.files = [ "/etc/nixos/flake.lock" ];

  nix.registry.iliana.flake = inputs.self;
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;

  nix.settings.flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON { flakes = [ ]; version = 2; });
}
