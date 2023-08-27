{
  config,
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

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github" "autogroup:shared" "tag:tartarus"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:80"];
    }
  ];

  system.stateVersion = "23.05";
}
