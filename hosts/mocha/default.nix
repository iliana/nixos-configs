{...}: {
  imports = [
    ../hardware/virt-v1.nix
  ];

  services.openvpn.restartAfterSleep = false;
  services.openvpn.servers.mocha0.config = ''
    config /run/credentials/openvpn-mocha0.service/config
    dev mocha0
    dev-type tun
  '';
  systemd.services.openvpn-mocha0.serviceConfig = {
    LoadCredentialEncrypted = "config:${./mocha0.ovpn.enc}";
  };

  iliana.tailscale = let
    routes = ["172.20.0.0/16" "172.30.0.0/16" "172.31.0.0/16"];
  in {
    advertiseRoutes = routes;
    policy.acls = builtins.map (proto: {
      action = "accept";
      src = ["autogroup:owner"];
      inherit proto;
      dst = routes;
    }) ["tcp" "udp"];
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";

  system.stateVersion = "23.05";
}
