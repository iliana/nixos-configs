{
  config,
  lib,
  test,
  ...
}: let
  cfg = config.iliana.www;
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
  };

  config = lib.mkIf (cfg.virtualHosts != {}) {
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [443];
    };

    services.caddy = {
      enable = true;
      email = "iliana@buttslol.net";
      globalConfig = lib.mkIf test ''
        local_certs
        skip_install_trust
      '';
      virtualHosts =
        builtins.mapAttrs
        (_: cfg: {
          extraConfig = ''
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
          '';
          logFormat = lib.mkIf test ''
            output stderr
          '';
        })
        cfg.virtualHosts;
    };

    # Unset the custom Exec* settings that the Caddy NixOS module sets. Instead,
    # symlink the generated Caddyfile to /etc/caddy/Caddyfile as the upstream
    # unit expects, and add `X-Reload-Triggers` with the path to the generated
    # Caddyfile. This avoids restarting the unit unless it meaningfully changes
    # (i.e. new version of Caddy).
    systemd.services.caddy.serviceConfig = {
      ExecReload = lib.mkForce [];
      ExecStart = lib.mkForce [];
      ExecStartPre = lib.mkForce [];
    };
    environment.etc."caddy/Caddyfile".source = config.services.caddy.configFile;
    systemd.services.caddy.reloadTriggers = [config.services.caddy.configFile];
    # To reduce downtime even further, restart instead of stop-then-start. This
    # can result in undesired behavior if any ExecStop* settings are set.
    systemd.services.caddy.stopIfChanged = false;

    iliana.persist.directories = lib.mkOrder 1200 [
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
      }
    ];
  };
}
