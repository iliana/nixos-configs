{ config, pkgs, ... }: {
  networking.hostName = "hydrangea";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/containers.nix
    ../profiles/tailscale.nix
  ];

  services.caddy = {
    enable = true;
    virtualHosts."http://nitter.home.arpa".extraConfig = ''
      reverse_proxy ${config.containers.nitter.localAddress}:8080
    '';
  };

  iliana.containers.nitter = {
    cfg = { config, ... }: {
      services.nitter = {
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
      };
    };
  };

  system.stateVersion = "22.11";
}
