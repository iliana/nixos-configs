{
  config,
  helpers,
  lib,
  ...
}: {
  iliana.www.virtualHosts."nitter.home.arpa:80" = let
    # https://status.d420.de/
    instances = [
      "https://nitter.d420.de"
      "https://nitter.x86-64-unknown-linux-gnu.zip"
    ];

    # Because different instances can set different default preferences, set
    # everything from `src/prefs_impl.nim` explicitly.
    preferences = {
      theme = "Nitter";
      infiniteScroll = false;
      stickyProfile = true;
      bidiSupport = false;
      hideTweetStats = false;
      hideBanner = false;
      hidePins = false;
      hideReplies = false;
      squareAvatars = false;

      mp4Playback = true;
      hlsPlayback = true;
      # respect whatever our instance sets
      # proxyVideos = true;
      muteVideos = false;
      autoplayGifs = false;

      replaceTwitter = "nitter.home.arpa";
      replaceYouTube = "";
      replaceReddit = "";
    };

    cookieValue = v:
      if builtins.isBool v
      then lib.optionalString v "on"
      else v;
    prefsCookie =
      builtins.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k}=${cookieValue v}") preferences);
  in
    helpers.caddy.requireTailscale ''
      reverse_proxy ${builtins.concatStringsSep " " instances} {
        lb_policy cookie lb

        fail_duration 15m
        unhealthy_status 429

        header_up Cookie "${prefsCookie}"
        header_up Host {upstream_hostport}
        header_down Which-Upstream {upstream_hostport}
      }
    '';
  iliana.www.denyTailscale = false;

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:80"];
    }
  ];
}
