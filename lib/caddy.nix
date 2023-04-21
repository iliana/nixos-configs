{ config, lib, ... }: {
  options = with lib; {
    iliana.caddy = {
      virtualHosts = mkOption { default = { }; };

      helpers = mkOption {
        readOnly = true;
        default =
          let
            common = ''
              encode zstd gzip
              tls {
                on_demand
              }
            '';
          in
          {
            container = name: port: {
              extraConfig = ''
                ${common}
                reverse_proxy ${config.containers.${name}.localAddress}:${toString port}
              '';
            };
            route = routes: {
              extraConfig = ''
                ${common}
                route {
                  ${builtins.concatStringsSep "\n" routes}
                  error 404
                }
              '';
            };
          };
      };
    };
  };

  config = lib.mkIf (config.iliana.caddy.virtualHosts != { }) {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.caddy = {
      enable = true;
      email = "iliana@buttslol.net";
      virtualHosts =
        let
          # `on_demand` is safe only if only if the `on_demand_tls` global option
          # is configured or there are no wildcard hosts with `on_demand`. (caddy
          # will still warn until caddyserver/caddy#5384 lands in a release.)
          wildcardHosts = builtins.filter
            (host: lib.strings.hasInfix "*" host)
            (builtins.attrNames config.iliana.caddy.virtualHosts);
        in
        lib.mkAssert
          (wildcardHosts == [ ])
          "wildcard virtual hosts detected: ${toString wildcardHosts}"
          config.iliana.caddy.virtualHosts;
    };

    iliana.persist.directories = [
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
      }
    ];
  };
}
