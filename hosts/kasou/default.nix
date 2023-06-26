{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix
  ];

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
    enable = true;
    defaultWindowManager = "xfce4-session";
    sslCert = config.iliana.tailscale.cert.certPath;
    sslKey = config.iliana.tailscale.cert.keyPath;
  };
  iliana.tailscale.cert.enable = true;
  iliana.tailscale.cert.users = ["xrdp"];
  systemd.services.xrdp.after = ["ts-cert.service"];
  systemd.services.xrdp.requires = ["ts-cert.service"];
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

  iliana.backup = {
    enable = true;
    creds = ./backup;
    dirs = ["/accounting"];
  };

  system.stateVersion = "22.11";
}
