{
  config,
  lib,
  myPkgs,
  ...
}: let
  helpers = config.iliana.caddy.helpers;
in {
  iliana.caddy.virtualHosts."emojos.in" = helpers.localhost 8000;

  systemd.services.emojos-dot-in = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      config.iliana.systemd.sandboxConfig {}
      // {
        ExecStart = lib.getExe myPkgs.emojos-dot-in;
      };
  };
}
