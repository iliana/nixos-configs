{ config, lib, pkgs, pkgs-unstable, ... }: {
  imports = [
    ./registry.nix
  ];

  options = with lib; {
    iliana.persist.directories = mkOption { default = [ ]; };
    iliana.persist.files = mkOption { default = [ ]; };
    iliana.persist.user.directories = mkOption { default = [ ]; };
    iliana.persist.user.files = mkOption { default = [ ]; };
  };

  config = {
    users.mutableUsers = false;
    users.users.iliana = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = [ ../etc/iliana-ssh.pub ];
    };
    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = [
      pkgs.fd
      pkgs.git
      pkgs.htop
      pkgs.jq
      pkgs.ncdu
      pkgs.nil
      pkgs.nixpkgs-fmt
      pkgs.ripgrep
      pkgs.shellcheck
      pkgs.tree
      pkgs-unstable.helix
    ];

    iliana.persist.directories = [
      "/var/db/dhcpcd"
      "/var/lib/chrony"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
      "/var/log"
    ];
    iliana.persist.files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    time.timeZone = "Etc/UTC";
    # maintenance window: 02:30-05:30 Pacific -> 10:30-12:30 UTC (accounting for DST)
    nix.gc = {
      automatic = true;
      dates = "10:30";
      options = "--delete-older-than 7d";
      randomizedDelaySec = "45min";
    };
    system.autoUpgrade = {
      enable = true;
      dates = "11:30";
      flags = [
        "--update-input"
        "iliana"
        "--update-input"
        "nixpkgs"
        "--update-input"
        "nixpkgs-unstable"
      ];
      flake = "''";
      randomizedDelaySec = "45min";
    };

    networking.firewall.logRefusedConnections = false;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    programs.command-not-found.enable = false;
    services.chrony.enable = true;
  };
}
