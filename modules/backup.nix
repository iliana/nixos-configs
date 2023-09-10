{
  config,
  lib,
  pkgs,
  test,
  ...
}: {
  options.iliana.backup = {
    exclude = lib.mkOption {
      default = [];
      type = with lib.types; listOf string;
    };
  };

  config = let
    cfg = config.iliana.backup;
    dirs = ["/" "/nix/persist"];
    creds = ../backup/${config.networking.hostName};
  in
    lib.mkIf (!test) {
      systemd.services.ili-backup = {
        after = ["network-online.target"];
        wants = ["network-online.target"];

        path = [pkgs.restic];
        script = ''
          restic backup \
            --compression auto \
            --one-file-system \
            ${builtins.concatStringsSep " " (builtins.map (dir: "-e ${lib.escapeShellArg dir}") cfg.exclude)} \
            ${lib.escapeShellArgs dirs}
          restic forget \
            --keep-within-hourly 24h \
            --keep-within-daily 1m \
            --keep-within-weekly 100y \
            --prune --repack-cacheable-only
        '';

        serviceConfig = {
          Type = "oneshot";
          LoadCredentialEncrypted = builtins.map (key: "${key}:${creds + "/${key}.enc"}") ["password" "repo" "s3"];
          Environment = [
            "AWS_SHARED_CREDENTIALS_FILE=%d/s3"
            "HOME=%h"
            "RESTIC_PASSWORD_FILE=%d/password"
            "RESTIC_REPOSITORY_FILE=%d/repo"
          ];
        };
      };

      systemd.timers.ili-backup = {
        wantedBy = ["timers.target"];
        timerConfig = {
          FixedRandomDelay = true;
          OnCalendar = "hourly";
          RandomizedDelaySec = "50m";
        };
      };
    };
}
