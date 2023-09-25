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
      openssh.authorizedKeys.keys = [
        "cert-authority,principals=\"iliana\" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCVuFcrr1PN/f71hrUiun8tfMo4iDjpQlrgIC6mykejdtAvrCyfzm0bwlgN3iCJ/hyZbXB/zL/Iu9gUd8/Wcu9L5kLa9JofLvfnihZOC8M/Us3VOG2B9pZpbjrann9cRpbi5DQEgQsyFeUj+j9Ib11dUEn+cE36QPXXtQTosmhtHvigbh26qLG5tIHBpKh0gCiXsNOx1NMUT9m/4gJTCueLwd3FRs7fBzvaKLc1cwaLpQ6NT6KMsxlAfUUg0Ct1UDG6ilkKe5VLOkNS8pOzY7Tkjz+ixyTOK8AwSG6hnNp602sTh2hWZEjAk9bmXjg+4+OvQE+Zxy/Ou9VbTKk3WN7TrU4noHWIOZ9JeUwHaiIV6sFNfxTgQCa3UAx4XwRcrbUxnDciLGwHvlwxjMzZRDmTw2uCx5CQBh0P4oKDeN5dMeG2W2kq/5oxD3kihgQ/lyL3OaQn3ptRoXholhp/V83/c8Ml35erzZ88EEd/rW3bSGG/zuMnFIaMnVayXNpw+QM= arn:aws:kms:us-west-2:516877725648:key/511ac21d-2c62-4bd2-ae14-e52ddd0052e2"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDC/oZFROia+ElMQ0cp3GD2g3/06YoZhA5EsrlKxT2N iliana@redwood"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECO1ghEFVs0WIFJ5mXvMq0GqIaBb4CTbexL5IYLohZ1 iliana@keysmash"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGmLom09EvwjDo6hSwzBf3kNdf/sMw/lPiswy3u4HR9 iliana@horizon"
      ];
    };
    security.sudo.wheelNeedsPassword = false;

    services.openssh.enable = true;
    services.openssh.hostKeys = [
      {
        type = "ed25519";
        path = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
      }
    ];
    services.openssh.settings.KbdInteractiveAuthentication = false;
    services.openssh.settings.PasswordAuthentication = false;

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
