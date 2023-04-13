{ config, lib, pkgs-iliana, ... }: {
  networking.hostName = "hydrangea";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/containers.nix
    ../profiles/tailscale.nix
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    email = "iliana@buttslol.net";

    virtualHosts =
      let
        common = ''
          encode zstd gzip
          tls {
            on_demand
          }
        '';
        container = name: port: {
          extraConfig = ''
            ${common}
            reverse_proxy ${config.containers.${name}.localAddress}:${toString port}
          '';
        };

        virtualHosts = {
          "emojos.in" = container "emojos" 8000;
          "nitter.home.arpa:80" = container "nitter" 8080;
        };

        # `on_demand` is safe only if only if the `on_demand_tls` global option
        # is configured or there are no wildcard hosts with `on_demand`. (caddy
        # will still warn until caddyserver/caddy#5384 lands in a release.)
        wildcardHosts = builtins.filter
          (host: lib.strings.hasInfix "*" host)
          (builtins.attrNames virtualHosts);
      in
      lib.mkAssert
        (wildcardHosts == [ ])
        "wildcard virtual hosts detected: ${toString wildcardHosts}"
        virtualHosts;
  };
  iliana.persist.directories = [
    {
      directory = "/var/lib/caddy";
      user = "caddy";
      group = "caddy";
    }
  ];

  iliana.containerNameservers = [ "8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844" ];
  iliana.containers = {
    emojos = {
      cfg = { config, ... }: {
        systemd.services.emojos-dot-in = {
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs-iliana.emojos-dot-in}/bin/emojos-dot-in";
            Environment = [ "ROCKET_ADDRESS=0.0.0.0" ];

            CapabilityBoundingSet = "";
            DynamicUser = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectHome = true;
            RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
            RestrictNamespaces = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = "@system-service";
          };
        };

        networking.firewall.allowedTCPPorts = [ 8000 ];
      };
    };

    nitter = {
      cfg = { config, ... }: {
        services.nitter = {
          package = pkgs-iliana.nitter;
          enable = true;
          openFirewall = true;
          server = {
            hostname = "nitter.home.arpa";
            port = 8080;
          };
          preferences = {
            autoplayGifs = false;
            hlsPlayback = true;
            muteVideos = true;
            replaceTwitter = "nitter.home.arpa";
          };
          cache = {
            rssMinutes = 60;
          };
        };
      };
    };
  };

  system.stateVersion = "22.11";
}
