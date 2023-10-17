{
  helpers,
  lib,
  pkgs,
  sources,
  test,
  ...
}: let
  package = pkgs.craneLib.buildPackage {
    name = "cohost-20020-bot";
    src = sources.cohost-20020-bot;
    cargoArtifacts = null;
    buildInputs = [pkgs.pkg-config pkgs.openssl];
  };
in
  lib.mkIf (!test) {
    systemd.services.cohost-20020-bot = {
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig =
        helpers.systemdSandbox {}
        // helpers.credentials {
          password.encrypted = ./cohost.enc;
        }
        // {
          ExecStart = "${package}/bin/cohost-20020-bot --post";
          Type = "oneshot";
          Environment = [
            "COHOST_EMAIL=iliana+cohost-bot-auth@buttslol.net"
            "COHOST_PASSWORD_FILE=%d/password"
            "COHOST_PROJECT=the-future-of-football"
            "COHOST_LIVE=true"
          ];
        };
    };
    systemd.timers.cohost-20020-bot = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnActiveSec = "35h";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };
  }
