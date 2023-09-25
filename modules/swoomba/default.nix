{
  helpers,
  lib,
  pkgs,
  sources,
  test,
  ...
}: let
  swoomba = pkgs.craneLib.buildPackage {
    name = "swoomba";
    src = sources.swoomba;
    cargoArtifacts = null;
    buildInputs = [pkgs.pkg-config pkgs.openssl];
  };
in
  lib.mkIf (!test) {
    users.users.swoomba = {
      isSystemUser = true;
      group = "swoomba";
      home = "/var/lib/swoomba";
    };
    users.groups.swoomba = {};

    iliana.persist.directories = [
      {
        directory = "/var/lib/swoomba";
        user = "swoomba";
        group = "swoomba";
        mode = "0700";
      }
    ];

    systemd.services.swoomba = {
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig =
        helpers.systemdSandbox {user = "swoomba";}
        // helpers.credentials {
          token.encrypted = ./token.enc;
        }
        // {
          ExecStart = "${swoomba}/bin/swoomba";
          Environment = [
            "DISCORD_TOKEN_FILE=%d/token"
            "RUST_LOG=error,swoomba=debug"
            "SWOOMBA_DB=/var/lib/swoomba/db"
          ];
          StateDirectory = "swoomba";
        };
    };
  }
