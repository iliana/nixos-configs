{ config, pkgs-unstable, ... }: {
  services.tailscale.enable = true;
  services.tailscale.package = pkgs-unstable.tailscale;
  iliana.persist.directories = [{ directory = "/var/lib/tailscale"; mode = "0700"; }];

  networking.firewall.checkReversePath = "loose";
  services.openssh.openFirewall = false;

  systemd.services.tailscale-up = {
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
}
