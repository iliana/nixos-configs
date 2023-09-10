{
  config,
  helpers,
  lib,
  ...
}: {
  iliana.www.virtualHosts."pancake.ili.fyi:80" = helpers.caddy.requireTailscale ''
    root * /media
    file_server {
      hide /media/z *.part *.torrent
      browse
    }
  '';
  iliana.www.openFirewall = lib.mkDefault false;
  services.caddy.virtualHosts."pancake.ili.fyi:80".listenAddresses = [config.iliana.tailscale.ip];

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github" "autogroup:shared" "tag:tartarus"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:80"];
    }
  ];
}
