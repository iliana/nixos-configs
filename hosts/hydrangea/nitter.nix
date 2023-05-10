{
  config,
  pkgs-unstable,
  ...
}: let
  helpers = config.iliana.caddy.helpers;
in {
  iliana.caddy.virtualHosts."nitter.home.arpa:80" = helpers.tsOnly (helpers.container "nitter" 8080);

  iliana.containers.nitter = {
    cfg = {...}: {
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
}
