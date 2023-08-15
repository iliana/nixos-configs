{
  config,
  lib,
  myPkgs,
  ...
}: {
  imports = [
    ./hardware/virt-v1.nix
    ../lib/media.nix
  ];

  services.transmission = {
    enable = true;
    package = myPkgs.transmission;
    openRPCPort = false;
    openPeerPorts = false;
    downloadDirPermissions = "0755";
    settings = {
      download-dir = "/media/tx";
      incomplete-dir-enabled = false;
      peer-port = 17259;
      port-forwarding-enabled = false;
      rpc-bind-address = "100.75.61.128";
      rpc-host-whitelist = "${config.networking.hostName},${config.networking.hostName}.cat-herring.ts.net";
      rpc-whitelist-enabled = false; # because we bind to a tailscale address
      umask = 18; # octal 0022
      watch-dir-enabled = false;
    };
  };
  systemd.services.transmission.unitConfig.After = lib.mkForce ["network.target" "tailscaled.service"];
  systemd.services.transmission.unitConfig.BindsTo = ["tailscaled.service"];
  iliana.persist.directories = [
    {
      inherit (config.services.transmission) user group;
      directory = config.services.transmission.home;
    }
  ];

  iliana.tailscale.exitNode = "gaia";

  system.stateVersion = "23.05";
}
