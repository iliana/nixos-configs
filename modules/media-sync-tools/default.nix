{pkgs, ...}: {
  users.users.iliana.packages = [
    (pkgs.writeShellApplication {
      name = "sync-bcbits";
      runtimeInputs = [pkgs.bandcamp-dl];
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
}
