{ config, lib, inputs, pkgs, pkgs-unstable, ... }: {
  imports = [
    ./caddy.nix
    ./containers.nix
    ./pdns.nix
    ./registry.nix
    ./tailscale.nix
  ];

  options = with lib; {
    iliana.persist.directories = mkOption { default = [ ]; };
    iliana.persist.files = mkOption { default = [ ]; };
  };

  config = {
    users.mutableUsers = false;
    users.users.iliana = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keyFiles = [ ../etc/iliana-ssh.pub ];
      packages = [
        pkgs.nil
        pkgs.nixpkgs-fmt
        pkgs.shellcheck
        pkgs-unstable.helix
      ];
    };
    security.sudo.wheelNeedsPassword = false;
    system.activationScripts.ilianaDotfiles = {
      deps = [ "users" ];
      text = ''
        ${pkgs.sudo}/bin/sudo -H -u iliana ${pkgs.bash}/bin/bash ${./dotfiles.sh} ${inputs.dotfiles.dotfiles}
      '';
    };

    environment.systemPackages = [
      pkgs.fd
      pkgs.gitMinimal
      pkgs.htop
      pkgs.jq
      pkgs.ncdu
      pkgs.ripgrep
      pkgs.tree
    ];

    environment.persistence."/nix/persist" = with config.iliana.persist; {
      inherit directories files;
      hideMounts = true;
    };
    iliana.persist.directories = lib.mkMerge [
      [
        "/var/db/dhcpcd"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timers"

        {
          directory = "/var/lib/chrony";
          user = "chrony";
          group = "chrony";
        }
      ]
      # Setting these as persistent directories makes booting test VMs fail.
      (lib.mkIf (!config.system.activationScripts ? testHwMakePersistDir) [
        "/var/lib/nixos"
        "/var/log"
      ])
    ];
    iliana.persist.files = lib.mkMerge [
      [
        "/etc/machine-id"
      ]
      (lib.mkIf config.services.openssh.enable [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ])
    ];

    time.timeZone = "Etc/UTC";
    # maintenance window: 02:30-05:30 Pacific -> 10:30-12:30 UTC (accounting for DST)
    nix.gc = {
      automatic = true;
      dates = "10:30";
      options = "--delete-older-than 2d";
      randomizedDelaySec = "45min";
    };
    # system.autoUpgrade = {
    #   enable = true;
    #   dates = "11:30";
    #   flags = [ "--update-input" "iliana" ];
    #   flake = "''";
    #   randomizedDelaySec = "45min";
    # };
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://cache.garnix.io" ];
      trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
    };

    # explicitly set default so we can add timeservers in other profiles
    networking.timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    networking.firewall.logRefusedConnections = false;
    programs.command-not-found.enable = false;
    services.chrony.enable = true;
  };
}
