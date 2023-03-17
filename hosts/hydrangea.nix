{ config, pkgs, ... }: {
  networking.hostName = "hydrangea";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  services.caddy = {
    enable = true;
    virtualHosts."http://nitter.home.arpa".extraConfig = ''
      reverse_proxy :8080
    '';
  };

  services.nitter = {
    enable = true;
    server = {
      hostname = "nitter.home.arpa";
      address = "127.0.0.1";
      port = 8080;
    };
    preferences = {
      autoplayGifs = false;
      hlsPlayback = true;
      muteVideos = true;
      replaceTwitter = "nitter.home.arpa";
    };
  };

  system.stateVersion = "22.11";
}
