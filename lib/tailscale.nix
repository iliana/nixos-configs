{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    iliana.tailscale.acceptRoutes = lib.mkOption {
      default = false;
    };
    iliana.tailscale.tags = lib.mkOption {
      default = ["tag:server"];
    };
    iliana.tailscale.cert = {
      enable = lib.mkOption {default = false;};
      users = lib.mkOption {
        default = [];
        type = with lib.types; listOf string;
      };
      certPath = lib.mkOption {
        default = "/run/ts-cert/cert.pem";
        readOnly = true;
      };
      keyPath = lib.mkOption {
        default = "/run/ts-cert/key.pem";
        readOnly = true;
      };
    };
  };

  config = let
    cfg = config.iliana.tailscale;
  in
    lib.mkIf (!config.iliana.test) {
      services.tailscale.enable = true;
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

      systemd.services.ts-cert = lib.mkIf cfg.cert.enable {
        after = ["tailscale.service" "network-online.target" "tailscale-up.service"];
        wants = ["tailscale.service" "network-online.target" "tailscale-up.service"];
        wantedBy = ["multi-user.target"];

        path = [config.services.tailscale.package pkgs.acl pkgs.jq];
        script = ''
          set -euo pipefail
          domain=$(tailscale status --json | jq -r .CertDomains[])
          tailscale cert --cert-file ${cfg.cert.certPath} --key-file ${cfg.cert.keyPath} "$domain"
          setfacl --remove-all --modify ${
            lib.escapeShellArg (builtins.concatStringsSep "," (builtins.map (user: "u:${user}:r") cfg.cert.users))
          } ${cfg.cert.keyPath}
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectoryPreserve = true;
          RuntimeDirectory = "ts-cert";
        };
      };
      systemd.timers.ts-cert = lib.mkIf cfg.cert.enable {
        wantedBy = ["timers.target"];
        timerConfig = {
          FixedRandomDelay = true;
          OnCalendar = "daily";
          RandomizedDelaySec = "6h";
        };
      };

      # networking.timeServers = ["hubble.cat-herring.ts.net"];
    };
}
