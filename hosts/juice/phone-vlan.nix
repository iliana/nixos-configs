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

    # ensure ordering is correct in activation script below
    before = ["systemd-udev-trigger.service"];

    serviceConfig = {
      ExecStart = "${pkgs.fastd}/bin/fastd -c %d/config";
      ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      LoadCredentialEncrypted = "config:${./fastd.conf.enc}";
    };
  };

  # workaround for (roughly) https://github.com/NixOS/nixpkgs/issues/195777
  system.activationScripts.restart-udev.text = ''
    if ! ${pkgs.diffutils}/bin/cmp {/run/current-system,"$systemConfig"}/etc/systemd/system/fastd-phone.service >/dev/null; then
      echo "systemd-udev-trigger.service" >>/run/nixos/activation-restart-list
    fi
  '';
}
