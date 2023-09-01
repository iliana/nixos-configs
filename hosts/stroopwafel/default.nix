{
  config,
  lib,
  myPkgs,
  pkgs,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix
    ../../lib/media.nix
  ];

  users.users.iliana.packages = [
    (pkgs.writeShellApplication {
      name = "sync-bcbits";
      runtimeInputs = [myPkgs.bandcamp-dl];
      text = ''
        cd /media/bcbits
        sudo systemd-creds decrypt ${./bcbits.enc} - | awk '{ print $1 }' | while read -r session; do
          bandcamp-dl --identity "$session"
        done
      '';
    })
    (pkgs.writeShellApplication {
      name = "sync-yt";
      runtimeInputs = [pkgs.yt-dlp];
      text = builtins.readFile ./sync-yt.sh;
    })

    pkgs.yt-dlp
  ];

  iliana.caddy.virtualHosts."pancake.ili.fyi:80" = config.iliana.caddy.helpers.tsOnly ''
    root * /media
    file_server {
      hide /media/z *.part *.torrent
      browse
    }
  '';
  iliana.caddy.openFirewall = false;
  services.caddy.virtualHosts."pancake.ili.fyi:80".listenAddresses = [config.iliana.tailscale.ip];

  services.syncthing = {
    enable = true;
    guiAddress = "${config.iliana.tailscale.ip}:8384";
    openDefaultPorts = true;

    extraOptions = {
      gui.insecureAdminAccess = true;
      gui.theme = "black";
    };

    devices.tartarus.id = "OFXYQDC-4UXU4A7-UYD47EY-DQQW4NN-BUMMNQL-WQSEWQW-TMLTN7A-54J32A6";
    folders."/media/z/scuttlebutt" = {
      id = "fystg-75vui";
      label = "scuttlebutt";
      devices = ["tartarus"];
      rescanInterval = 21600;
      type = "sendonly";
    };
  };
  iliana.persist.directories = [
    {
      directory = config.services.syncthing.dataDir;
      inherit (config.services.syncthing) user group;
    }
  ];

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github" "autogroup:shared" "tag:tartarus"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:80"];
    }
    {
      action = "accept";
      src = ["iliana@github"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:8384"];
    }
  ];

  system.stateVersion = "23.05";
}
