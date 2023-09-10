{
  helpers,
  lib,
  pkgs,
  ...
}: {
  networking = {
    usePredictableInterfaceNames = false;
    bridges.br0.interfaces = ["eth0.5" "tap0"];
    vlans."eth0.5" = {
      id = 5;
      interface = "eth0";
    };
  };

  # fastd-phone creates the "tap0" interface
  systemd.services.fastd-phone = {
    after = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig =
      helpers.credentials {config.encrypted = ./fastd.conf.enc;}
      // {
        ExecStart = "${pkgs.fastd}/bin/fastd -c %d/config";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
  };

  # NixOS assumes tap0/br0 need to come up before the network can be online, but
  # they can only come up after the network is online. Break the loop.
  systemd.services.network-addresses-tap0 = {
    before = lib.mkForce [];
    after = ["fastd-phone.service"];
    requires = ["fastd-phone.service"];
    wantedBy = lib.mkForce ["multi-user.target"];
  };
  systemd.services.br0-netdev = {
    before = lib.mkForce [];
    partOf = lib.mkForce [];
    wantedBy = lib.mkForce ["multi-user.target"];
  };
}
