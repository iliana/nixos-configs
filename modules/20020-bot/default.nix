{
  helpers,
  lib,
  pkgs,
  test,
  ...
}: let
  package = pkgs.craneLib.buildPackage {
    name = "cohost-20020-bot";
    src = pkgs.fetchgit {
      url = "https://git.iliana.fyi/cohost-20020-bot";
      rev = "ccfe95d6b54748ad7efdbd907a80684b1712272a";
      hash = "sha256-IinhPGFdLIYMCFXo1NRNO8agcOeeqwgIwbo/Smo2THc=";
    };
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
        OnUnitActiveSec = "35h";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };
  }
