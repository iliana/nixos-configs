{pkgs, ...}: {
  networking = {
    bridges.br0.interfaces = ["eth0.5" "tap0"];
    vlans."eth0.5" = {
      id = 5;
      interface = "eth0";
    };
  };

  # fastd-phone creates the "tap0" interface
  systemd.services.fastd-phone = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.fastd}/bin/fastd -c %d/config";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      LoadCredentialEncrypted = "config:${./fastd.conf.enc}";
    };
  };
}
