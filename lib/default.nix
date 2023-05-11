{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./caddy.nix
    ./containers.nix
    ./dotfiles.nix
    ./pdns
    ./registry.nix
    ./systemd.nix
    ./tailscale.nix
  ];

  options = with lib; {
    iliana.persist.directories = mkOption {default = [];};
    iliana.persist.files = mkOption {default = [];};

    iliana.test = mkOption {default = false;};
  };

  config = {
    users.mutableUsers = false;
    users.users.iliana = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keyFiles = [./iliana-ssh.pub];
      packages = [
        pkgs-unstable.helix
        pkgs-unstable.nil
        pkgs-unstable.shellcheck
      ];
    };
    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = [
      pkgs.fd
      pkgs.gitMinimal
      pkgs.htop
      pkgs.jq
      pkgs.ncdu
      pkgs.ripgrep
      pkgs.tmux
      pkgs.tree
    ];

    environment.persistence."/nix/persist" = {
      inherit (config.iliana.persist) directories files;
      hideMounts = true;
    };
    system.activationScripts.createNixPersist.text = "[ -d /nix/persist ] || mkdir /nix/persist";
    system.activationScripts.createPersistentStorageDirs.deps = ["createNixPersist"];
    iliana.persist.directories = [
      "/var/db/dhcpcd"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
      "/var/log"

      {
        directory = "/var/lib/chrony";
        user = "chrony";
        group = "chrony";
      }
    ];
    iliana.persist.files =
      [
        "/etc/machine-id"
      ]
      ++ lib.lists.optionals config.services.openssh.enable [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];

    time.timeZone = "Etc/UTC";
    nix.gc = {
      automatic = true;
      dates = "10:30";
      options = "--delete-older-than 2d";
      randomizedDelaySec = "45min";
    };
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://cache.garnix.io"];
      trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
    };

    # explicitly set default so we can add timeservers in other profiles
    networking.timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    # tailscale generates PKCS#8-encoded ed25519 private keys, which are
    # supported by age since v1.1.0, and not rage.
    age.ageBin = "${pkgs-unstable.age}/bin/age";

    networking.firewall.logRefusedConnections = false;
    programs.command-not-found.enable = false;
    services.chrony.enable = true;
  };
}
