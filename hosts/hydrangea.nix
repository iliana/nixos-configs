{
  config,
  myPkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  networking.firewall.allowedTCPPorts = [80 443];

  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "emojos.in" = container "emojos" 8000;
    "haha.business" = serve ../etc/haha.business;
    "nitter.home.arpa:80" = tsOnly (container "nitter" 8080);
  };

  iliana.containerNameservers = ["8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
  iliana.containers = {
    emojos = {
      cfg = {config, ...}: {
        systemd.services.emojos-dot-in = {
          after = ["network.target"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            ExecStart = "${myPkgs.emojos-dot-in}/bin/emojos-dot-in";
            Environment = ["ROCKET_ADDRESS=0.0.0.0"];

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

        networking.firewall.allowedTCPPorts = [8000];
      };
    };

    nitter = {
      cfg = {config, ...}: {
        services.nitter = {
          package = pkgs-unstable.nitter;
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
