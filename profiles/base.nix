{ config, pkgs, inputs, ... }:
let
  emptyFlakeRegistry = pkgs.writeText "flake-registry.json" (builtins.toJSON { flakes = [ ]; version = 2; });
in
{
  users.users.iliana = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    fd
    git
    helix
    htop
    jq
    ripgrep
  ];

  system.autoUpgrade = {
    enable = true;
    dates = "04:40";
    flags = [ "--update-input" "nixpkgs" ];
    flake = "''";
    randomizedDelaySec = "45min";
  };
  nix.gc = {
    automatic = true;
    dates = "03:15";
    randomizedDelaySec = "45min";
  };

  nix.registry.iliana.flake = inputs.self;
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.settings.flake-registry = emptyFlakeRegistry;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.command-not-found.enable = false;
  services.chrony.enable = true;
}
