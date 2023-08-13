{
  config,
  lib,
  pkgs,
  ...
}: {
  options.iliana.backup = {
    enable = lib.mkOption {
      default = false;
      type = with lib.types; bool;
    };
    exclude = lib.mkOption {
      default = [];
      type = with lib.types; listOf string;
    };
    dirs = lib.mkOption {
      type = with lib.types; listOf string;
    };
    creds = lib.mkOption {
      type = with lib.types; path;
    };
  };

  config = let
    cfg = config.iliana.backup;
  in
    lib.mkIf (cfg.enable && !config.iliana.test) {
      systemd.services.ili-backup = {
        after = ["network-online.target"];
        wants = ["network-online.target"];

        path = [pkgs.restic];
        script = ''
          restic backup \
            --compression auto \
            --one-file-system \
            ${builtins.concatStringsSep " " (builtins.map (dir: "-e ${lib.escapeShellArg dir}") cfg.exclude)} \
            ${lib.escapeShellArgs cfg.dirs}
          restic forget \
            --keep-within-hourly 24h \
            --keep-within-daily 1m \
            --keep-within-weekly 100y \
            --prune --repack-cacheable-only
        '';

        serviceConfig = {
          Type = "oneshot";
          LoadCredentialEncrypted = builtins.map (key: "${key}:${cfg.creds + "/${key}.enc"}") ["password" "repo" "s3"];
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
