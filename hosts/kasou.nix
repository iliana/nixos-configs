{
  config,
  lib,
  pkgs,
  ...
}: let
  sslCert = "/nix/persist/kasou.crt";
  sslKey = "/nix/persist/kasou.key";
  certScript = ''
    ${lib.getExe config.services.tailscale.package} cert \
      --cert-file ${sslCert} --key-file ${sslKey} kasou.cat-herring.ts.net
    chown xrdp:xrdp ${sslCert} ${sslKey}
  '';
in {
  imports = [
    ./hardware/virt-v1.nix
  ];

  system.activationScripts.xrdpTsCert = {
    deps = ["createNixPersist" "users"];
    text = certScript;
  };
  systemd.timers."xrdp-ts-cert" = {
    timerConfig.FixedRandomDelay = true;
    timerConfig.OnCalendar = "daily";
    timerConfig.RandomizedDelaySec = "6h";
    wantedBy = ["timers.target"];
  };
  systemd.services."xrdp-ts-cert" = {
    script = certScript;
    serviceConfig.Type = "oneshot";
  };

  iliana.persist.directories = [
    {
      directory = "/home/iliana";
      user = "iliana";
      group = "users";
      mode = "0700";
    }
  ];
  iliana.dotfiles = false;
  services.xrdp = {
    inherit sslCert sslKey;
    enable = true;
    defaultWindowManager = "xfce4-session";
  };
  services.xserver.desktopManager.xfce = {
    enable = true;
    enableScreensaver = false;
  };
  services.xserver.enable = true;
  users.users.iliana.hashedPassword = "$y$j9T$FjAoXxDC8Pxs/69Sl543G1$9L5uiaQnAbcMNQSeyoDjVYbpwgjkYV5QsGCHaQns5KB";

  users.users.iliana.packages = [pkgs.gnucash];
  fileSystems."/accounting" = {
    fsType = "9p";
    device = "accounting";
    options = ["trans=virtio" "version=9p2000.L"];
  };

  system.stateVersion = "22.11";
}
