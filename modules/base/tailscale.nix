{
  config,
  lib,
  pkgs,
  test,
  ...
}: {
  options.iliana.tailscale = {
    acceptRoutes = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    advertiseRoutes = lib.mkOption {
      default = [];
      type = with lib.types; listOf string;
    };
    advertiseServerTag = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    exitNode = lib.mkOption {
      default = null;
      type = with lib.types; nullOr string;
    };
    ssh = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };

    authKeyFile = lib.mkOption {
      default = null;
      type = with lib.types; nullOr string;
    };

    cert = {
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

    ip = lib.mkOption {
      default = (lib.importJSON ./hosts.json).${config.networking.hostName};
      readOnly = true;
    };
  };

  config = let
    cfg = config.iliana.tailscale;
  in
    lib.mkIf (!test) {
      services.tailscale.enable = true;
      iliana.persist.directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];

      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = ["tailscale0"];
      services.openssh.openFirewall = lib.mkDefault false;

      systemd.services.tailscale-up = {
        description = "tailscale up";

        after = ["tailscale.service" "network-online.target"];
        wants = ["tailscale.service" "network-online.target"];
        wantedBy = ["multi-user.target"];

        path = [config.services.tailscale.package];
        script = ''
          tailscale up \
            --accept-routes=${lib.boolToString cfg.acceptRoutes} \
            --advertise-routes=${lib.escapeShellArg (builtins.concatStringsSep "," cfg.advertiseRoutes)} \
            --advertise-tags=${lib.optionalString cfg.advertiseServerTag "tag:server"} \
            --auth-key="${lib.optionalString (cfg.authKeyFile != null) "$(if [[ -f ${lib.escapeShellArg cfg.authKeyFile} ]]; then echo ${lib.escapeShellArg "file:${cfg.authKeyFile}"}; fi)"}" \
            --exit-node=${lib.optionalString (cfg.exitNode != null) (lib.escapeShellArg cfg.exitNode)} \
            --ssh=${lib.boolToString cfg.ssh}
          ${lib.optionalString (cfg.authKeyFile != null) "rm -fv ${lib.escapeShellArg cfg.authKeyFile}"}
        '';

        serviceConfig = {
          Type = "oneshot";
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
    };
}
