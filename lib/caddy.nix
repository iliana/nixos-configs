{
  config,
  lib,
  myPkgs,
  ...
}: {
  options = with lib; {
    iliana.caddy = {
      virtualHosts = mkOption {
        default = {};
        type = with lib.types; attrsOf (either lines (attrsOf lines));
      };

      helpers = mkOption {
        readOnly = true;
        default = rec {
          container = name: port: ''
            reverse_proxy ${config.containers.${name}.localAddress}:${toString port}
          '';
          localhost = port: ''
            reverse_proxy localhost:${toString port}
          '';
          redirMap = map: ''
            route {
              ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (matcher: to: "redir ${matcher} ${to}") map)}
              error 404
            }
          '';
          redirPrefix = prefix: ''
            redir ${prefix}{uri}
          '';
          serveWith = {
            index ? ["index.html"],
            passthru ? false,
          }: root: let
            matcher = "@exists${builtins.hashString "sha256" "${root}"}";
          in ''
            ${
              lib.optionalString (lib.hasPrefix builtins.storeDir root) ''
                ${matcher} file {
                  root ${root}
                  try_files {path} ${builtins.concatStringsSep " " (builtins.map (x: "{path}/${x}") index)}
                }
                header ${matcher} -last-modified
                header ${matcher} etag `"${builtins.substring (builtins.stringLength builtins.storeDir + 1) 32 root}"`
              ''
            }
            file_server {
              root ${root}
              index ${builtins.concatStringsSep " " index}
              ${lib.optionalString passthru "pass_thru"}
            }
          '';
          serve = serveWith {};
          tsOnly = config: ''
            @external not remote_ip 100.64.0.0/10 127.0.0.0/24
            abort @external

            ${config}
          '';
        };
      };
    };
  };

  config = lib.mkIf (config.iliana.caddy.virtualHosts != {}) {
    networking.firewall.allowedTCPPorts = [80 443];
    networking.firewall.allowedUDPPorts = [443];

    services.caddy = {
      enable = true;
      package = myPkgs.caddy;
      email = "iliana@buttslol.net";
      globalConfig = lib.mkIf config.iliana.test ''
        local_certs
        skip_install_trust
      '';
      virtualHosts = let
        final =
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
                then let
                  matchers = lib.sort (left: right: (builtins.stringLength left) > (builtins.stringLength right)) (builtins.attrNames cfg);
                in
                  lib.concatStrings (builtins.map
                    (matcher: ''
                      handle ${matcher} {
                        ${cfg.${matcher}}
                      }
                    '')
                    matchers)
                  + lib.optionalString (!(cfg ? "*")) ''
                    handle * {
                      error 404
                    }
                  ''
                else cfg
              }
            '';
            logFormat = lib.mkIf config.iliana.test ''
              output stderr
            '';
          })
          config.iliana.caddy.virtualHosts;

        # `on_demand` is safe only if only if the `on_demand_tls` global option
        # is configured or there are no wildcard hosts with `on_demand`. (caddy
        # will still warn until caddyserver/caddy#5384 lands in a release.)
        wildcardHosts =
          builtins.filter
          (lib.strings.hasInfix "*")
          (builtins.attrNames final);
      in
        lib.mkAssert
        (wildcardHosts == [])
        "wildcard virtual hosts detected: ${toString wildcardHosts}"
        final;
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

    iliana.persist.directories = [
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
      }
    ];
  };
}
