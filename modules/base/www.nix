{
  config,
  helpers,
  lib,
  pkgs,
  test,
  ...
}: let
  mkVHost = host: cfg: ''
    ${host} {
      log {
        output file /var/log/caddy/access-${host}.log
      }

      encode zstd gzip
      header {
        ?cache-control "private, max-age=0, must-revalidate"
        permissions-policy "interest-cohort=()"
        ?referrer-policy "no-referrer-when-downgrade"
      }
      tls {
        on_demand
      }
    ${
      if builtins.isAttrs cfg
      then
        lib.concatStrings (lib.mapAttrsToList
          (matcher: value: ''
            handle ${matcher} {
              ${value}
            }
          '')
          ({"*" = "error 404";} // cfg))
      else cfg
    }
    }
  '';

  cfg = config.iliana.www;
  user = "caddy";
  dataDir = "/var/lib/caddy";

  caddyfileUnformatted = pkgs.writeText "Caddyfile" ''
    {
      email ${config.security.acme.defaults.email}
      acme_ca ${config.security.acme.defaults.server}
      log {
        level ERROR
      }
    ${lib.optionalString test ''
      local_certs
      skip_install_trust
    ''}
    }
    ${builtins.concatStringsSep "\n" (lib.mapAttrsToList mkVHost cfg.virtualHosts)}
  '';
  caddyfile = pkgs.runCommand "Caddyfile-formatted" {} ''
    cat ${caddyfileUnformatted} >$out
    ${pkgs.caddy}/bin/caddy fmt --overwrite $out
  '';
in {
  options.iliana.www = with lib; {
    virtualHosts = mkOption {
      default = {};
      type = with lib.types; attrsOf (either lines (attrsOf str));
    };
    openFirewall = mkOption {
      default = true;
      type = lib.types.bool;
    };
    denyTailscale = mkOption {
      default = true;
      type = lib.types.bool;
    };
  };

  config = lib.mkIf (cfg.virtualHosts != {}) {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [443];
    };

    environment.etc."caddy/Caddyfile".source = caddyfile;

    users.users.${user} = {
      group = user;
      uid = config.ids.uids.${user};
      home = dataDir;
    };
    users.groups.${user}.gid = config.ids.gids.${user};

    systemd.services.caddy = {
      after = ["network.target" "network-online.target"];
      requires = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      reloadTriggers = [caddyfile];
      stopIfChanged = false;

      startLimitIntervalSec = 14400;
      startLimitBurst = 10;

      serviceConfig =
        helpers.systemdSandbox {
          user = "caddy";
          inherit (cfg) denyTailscale;
        }
        // {
          Type = "notify";
          ExecStart = "${pkgs.caddy}/bin/caddy run --config /etc/caddy/Caddyfile";
          ExecReload = "${pkgs.caddy}/bin/caddy reload --config /etc/caddy/Caddyfile --force";
          Restart = "on-abnormal";

          AmbientCapabilities = ["cap_net_admin" "cap_net_bind_service"];
          CapabilityBoundingSet = ["cap_net_admin" "cap_net_bind_service"];
          PrivateUsers = false;

          LimitNOFILE = 1048576;
          LimitNPROC = 512;
          TimeoutStopSec = "5s";

          LogsDirectory = "caddy";
          StateDirectory = "caddy";
        };
    };

    iliana.persist.directories = [
      {
        directory = dataDir;
        inherit user;
        group = user;
      }
    ];

    # https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size
    boot.kernel.sysctl."net.core.rmem_max" = 2500000;
  };
}
