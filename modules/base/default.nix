{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./dotfiles.nix
    ./nix-settings.nix
    ./persist.nix
    ./policy.nix
    ./tailscale.nix
    ./www.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      fd
      gitMinimal
      helix
      htop
      jq
      ncdu
      pv
      ripgrep
      tmux
      tree
    ];

    users.mutableUsers = false;
    users.allowNoPasswordLogin = true;
    users.users.iliana = {
      isNormalUser = true;
      extraGroups = ["wheel"];
    };
    security.sudo.wheelNeedsPassword = false;

    time.timeZone = "Etc/UTC";
    services.chrony.enable = true;
    # This is the default, but explicitly set it so we can add time servers in
    # other profiles instead of overriding. (If we need to override, we can set
    # `services.chrony.servers`.)
    networking.timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    # Removes the date/revision information from the version string. This makes
    # the result of `config.system.build.toplevel` the same if nothing has
    # changed, which allows us to trivially determine if there are changes that
    # impact us between two different revisions.
    system.nixos.version = config.system.nixos.release;
    # Disables `nixos-version`, which includes the commit hash, and also
    # triggers a dbus reload whenever it changes.
    system.disableInstallerTools = true;

    # Disable documentation we don't use.
    documentation.doc.enable = false;
    documentation.info.enable = false;
    documentation.nixos.enable = false;

    networking.firewall.logRefusedConnections = false;
    programs.command-not-found.enable = false;
  };
}
