{ config, pkgs, inputs, ... }:
let
  emptyFlakeRegistry = pkgs.writeText "flake-registry.json" (builtins.toJSON { flakes = [ ]; version = 2; });
in
{
  users.users.iliana = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ ../etc/iliana-ssh.pub ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    fd
    git
    helix
    htop
    jq
    nil
    nixpkgs-fmt
    ripgrep
  ];

  time.timeZone = "Etc/UTC";
  # maintenance window: 02:30-05:30 Pacific -> 10:30-12:30 UTC (accounting for DST)
  nix.gc = {
    automatic = true;
    dates = "10:30";
    randomizedDelaySec = "45min";
  };
  system.autoUpgrade = {
    enable = true;
    dates = "11:30";
    flags = [ "--update-input" "iliana" "--update-input" "nixpkgs" ];
    flake = "''";
    randomizedDelaySec = "45min";
  };

  networking.firewall.logRefusedConnections = false;
  nix.registry.iliana.flake = inputs.self;
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.flake-registry = emptyFlakeRegistry;
  programs.command-not-found.enable = false;
  services.chrony.enable = true;
  services.openssh.enable = true;
}
