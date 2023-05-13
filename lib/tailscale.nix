{
  config,
  lib,
  pkgs-unstable,
  ...
}: {
  options = {
    iliana.tailscale.tags = lib.mkOption {
      default = ["tag:server"];
    };
  };

  config = let
    cfg = config.iliana.tailscale;
  in
    lib.mkIf (!config.iliana.test) {
      services.tailscale.enable = true;
      services.tailscale.package = pkgs-unstable.tailscale;
      iliana.persist.directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];

      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = ["tailscale0"];
      services.openssh.openFirewall = false;

      systemd.services.tailscale-up = {
        description = "tailscale up";

        after = ["tailscale.service" "network-online.target"];
        wants = ["tailscale.service" "network-online.target"];
        wantedBy = ["multi-user.target"];

        script = let
          advertiseTags =
            if (cfg.tags == null || cfg.tags == [])
            then ""
            else "--advertise-tags=${builtins.concatStringsSep "," cfg.tags}";
        in ''
          ${pkgs-unstable.tailscale}/bin/tailscale up --ssh ${advertiseTags}
        '';

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StandardOutput = "journal+console";
          StandardError = "inherit";
        };
      };

      networking.timeServers = ["hubble.cat-herring.ts.net"];

      age.identityPaths = lib.mkIf (!config.services.openssh.enable) ["/nix/persist/var/lib/tailscale/ssh/ssh_host_ed25519_key"];
    };
}
