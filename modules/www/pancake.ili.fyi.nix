{
  config,
  helpers,
  lib,
  ...
}: {
  iliana.www.virtualHosts."pancake.ili.fyi:80" = helpers.caddy.requireTailscale ''
    bind ${config.iliana.tailscale.ip}
    root * /media
    file_server {
      hide /media/z *.part *.torrent
      browse
    }
  '';
  iliana.www.openFirewall = lib.mkDefault false;
  iliana.www.denyTailscale = false;
  systemd.services.caddy.after = ["tailscale-up.service"];

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github" "autogroup:shared" "tag:tartarus"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:80"];
    }
  ];
}
