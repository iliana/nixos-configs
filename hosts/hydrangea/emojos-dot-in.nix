{
  config,
  myPkgs,
  ...
}: let
  helpers = config.iliana.caddy.helpers;
in {
  iliana.caddy.virtualHosts."emojos.in" = helpers.container "emojos" 8000;

  iliana.containers.emojos = {
    cfg = {...}: {
      systemd.services.emojos-dot-in = {
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig =
          config.iliana.systemd.sandboxConfig {}
          // {
            ExecStart = "${myPkgs.emojos-dot-in}/bin/emojos-dot-in";
            Environment = ["ROCKET_ADDRESS=0.0.0.0"];
          };
      };

      networking.firewall.allowedTCPPorts = [8000];
    };
  };
}
