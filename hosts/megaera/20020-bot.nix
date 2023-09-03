{
  config,
  lib,
  pkgs,
  ...
}: let
  package = pkgs.craneLib.buildPackage {
    name = "cohost-20020-bot";
    src = pkgs.fetchgit {
      url = "https://git.iliana.fyi/cohost-20020-bot";
      rev = "277669582112129a1cbd0c7cbb32856d9169ddbe";
      hash = "sha256-sLPtfKR/bCogI2F3nZzHHpg2xwvyN7ZUD6FSwk5PdFQ=";
    };
    cargoArtifacts = null;
    buildInputs = [pkgs.pkg-config pkgs.openssl];
  };
in
  lib.mkIf (!config.iliana.test) {
    iliana.creds.cohost-20020-bot.password.encrypted = ./cohost.enc;
    systemd.services.cohost-20020-bot = {
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig =
        config.iliana.systemd.sandboxConfig {}
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
