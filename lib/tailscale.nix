{ config, lib, pkgs-unstable, ... }:
let
  ifEnabled = lib.mkIf config.services.tailscale.enable;
in
{
  services.tailscale.enable = lib.mkDefault true;
  services.tailscale.package = pkgs-unstable.tailscale;
  iliana.persist.directories = [{ directory = "/var/lib/tailscale"; mode = "0700"; }];

  networking.firewall.checkReversePath = ifEnabled "loose";
  networking.firewall.trustedInterfaces = ifEnabled [ "tailscale0" ];
  services.openssh.openFirewall = ifEnabled false;

  systemd.services.tailscale-up = ifEnabled {
    description = "tailscale up";

    after = [ "tailscale.service" "network-online.target" ];
    wants = [ "tailscale.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      ${pkgs-unstable.tailscale}/bin/tailscale up --ssh --advertise-tags=tag:server
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal+console";
      StandardError = "inherit";
    };
  };

  networking.timeServers = ifEnabled [ "hubble.cat-herring.ts.net" ];
}
