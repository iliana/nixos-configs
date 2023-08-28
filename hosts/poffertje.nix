{
  config,
  lib,
  myPkgs,
  pkgs,
  ...
}: let
  myIp = (lib.importJSON ../lib/hosts.json).${config.networking.hostName};
  peerPort = 17259;
in {
  imports = [
    ./hardware/virt-v1.nix
    ../lib/media.nix
  ];

  users.users.iliana.packages = [
    (pkgs.writeShellApplication {
      name = "tx-untracked";
      runtimeInputs = [pkgs.jq];
      text = ''
        session_id=$(curl -s -o /dev/null -w '%header{x-transmission-session-id}' http://${myIp}:9091/transmission/rpc)
        comm -23 \
            <(find /media/tx -type f | sort) \
            <(curl -fsS http://${myIp}:9091/transmission/rpc -H "x-transmission-session-id: $session_id" \
                --json '{"method":"torrent-get","arguments":{"fields":["downloadDir","files"]}}' | \
                jq -r '.arguments.torrents[] | .downloadDir as $dir | .files[] | $dir + "/" + .name' | sort)
      '';
    })
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
      peer-port = peerPort;
      port-forwarding-enabled = false;
      rpc-bind-address = myIp;
      rpc-host-whitelist = "${config.networking.hostName},${config.networking.hostName}.cat-herring.ts.net";
      rpc-whitelist-enabled = false; # because we bind to a tailscale address
      torrent-added-verify-mode = "full";
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

  iliana.tailscale.exitNode = "100.94.213.2";
  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = [config.networking.hostName];
      proto = ["tcp" "udp"];
      dst = ["autogroup:internet:*"];
    }
    {
      action = "accept";
      src = ["tag:gaia"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:${builtins.toString peerPort}"];
    }
    {
      action = "accept";
      src = ["iliana@github"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:9091"];
    }
  ];
  iliana.tailscale.policy.tags = ["tag:gaia"];

  system.stateVersion = "23.05";
}
