{lib, ...}: {
  iliana.caddy.virtualHosts."nitter.home.arpa:80" = let
    # https://github.com/zedeus/nitter/wiki/Instances
    # Various instances within North America.
    instances = [
      "https://nitter.1d4.us"
      "https://nitter.cutelab.space"
      "https://nitter.moomoo.me"
      "https://nitter.us.projectsegfau.lt"
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
      if v == true
      then "on"
      else if v == false
      then ""
      else v;
    prefsCookie =
      builtins.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k}=${cookieValue v}") preferences);
  in ''
    reverse_proxy ${builtins.concatStringsSep " " instances} {
      lb_policy cookie lb

      fail_duration 15m
      unhealthy_status 429

      header_up Cookie "${prefsCookie}"
      header_up Host {upstream_hostport}
      header_down Which-Upstream {upstream_hostport}
    }
  '';
}
