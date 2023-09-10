{helpers, ...}: {
  services.openvpn.restartAfterSleep = false;
  services.openvpn.servers.mocha0.config = ''
    config /run/credentials/openvpn-mocha0.service/config
    dev mocha0
    dev-type tun
  '';
  systemd.services.openvpn-mocha0.serviceConfig = helpers.credentials {
    config.encrypted = ./mocha0.ovpn.enc;
  };

  iliana.tailscale = let
    routes = ["172.20.0.0/16" "172.30.0.0/16" "172.31.0.0/16"];
  in {
    advertiseRoutes = routes;
    policy.acls = [
      {
        action = "accept";
        src = ["iliana@github"];
        proto = ["tcp" "udp"];
        dst = builtins.map (route: "${route}:*") routes;
      }
    ];
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
}
