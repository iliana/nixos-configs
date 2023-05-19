{
  config,
  lib,
  myPkgs,
  ...
}: {
  options = {
    iliana.tailscale.acceptRoutes = lib.mkOption {
      default = false;
    };
    iliana.tailscale.tags = lib.mkOption {
      default = ["tag:server"];
    };
  };

  config = let
    cfg = config.iliana.tailscale;
  in
    lib.mkIf (!config.iliana.test) {
      services.tailscale.enable = true;
      services.tailscale.package = myPkgs.tailscale;
      iliana.persist.directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];

      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = ["tailscale0"];
      services.openssh.openFirewall = false;

      systemd.services.tailscale-up = {
        description = "tailscale up";

        after = ["tailscale.service" "network-online.target"];
        wants = ["tailscale.service" "network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = let
            advertiseTags =
              lib.optionalString
              (builtins.isList cfg.tags && builtins.length cfg.tags > 0)
              "--advertise-tags=${builtins.concatStringsSep "," cfg.tags}";
            acceptRoutes = lib.optionalString cfg.acceptRoutes "--accept-routes";
          in "${lib.getExe config.services.tailscale.package} up --ssh ${advertiseTags} ${acceptRoutes}";
          RemainAfterExit = true;
          StandardOutput = "journal+console";
          StandardError = "inherit";
        };
      };

      networking.timeServers = ["hubble.cat-herring.ts.net"];
    };
}
