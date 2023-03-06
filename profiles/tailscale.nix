{ config, pkgs, ... }: {
  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose";
  services.openssh.openFirewall = false;

  systemd.services.tailscale-up = {
    description = "tailscale up";

    after = [ "tailscale.service" "network-online.target" ];
    wants = [ "tailscale.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    script = ''
      ${pkgs.tailscale}/bin/tailscale up --ssh --advertise-tags=tag:server
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StandardOutput = "journal+console";
      StandardError = "inherit";
    };
  };
}
