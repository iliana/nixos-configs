{pkgs, ...}: {
  imports = [
    ../hardware/virt-v1.nix
    ../../lib/media.nix
  ];

  users.users.iliana.packages = [
    pkgs.yt-dlp
    (pkgs.writeShellApplication {
      name = "sync-yt";
      runtimeInputs = [pkgs.yt-dlp];
      text = builtins.readFile ./sync-yt.sh;
    })
  ];

  iliana.caddy.virtualHosts."pancake.ili.fyi:80" = ''
    root * /media
    file_server {
      hide /media/z *.part *.torrent
      browse
    }
  '';

  system.stateVersion = "23.05";
}
