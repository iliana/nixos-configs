{
  config,
  pkgs,
  ...
}: let
  swoomba = pkgs.craneLib.buildPackage {
    name = "swoomba";
    src = pkgs.fetchgit {
      url = "https://git.iliana.fyi/swoomba";
      rev = "6b3461591cc38e506a469256b6dc7cbed9f5056f";
      hash = "sha256-vGtyXYwRjaSCtG2Grne/8JLR7yPPS6C44T+/6x7vtdo=";
    };
    cargoArtifacts = null;
    buildInputs = [pkgs.pkg-config pkgs.openssl];
  };
in {
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

  iliana.creds.swoomba.token.encrypted = ./token.enc;
  systemd.services.swoomba = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig =
      config.iliana.systemd.sandboxConfig {user = "swoomba";}
      // {
        ExecStart = "${swoomba}/bin/swoomba";
        Environment = [
          "DISCORD_TOKEN_FILE=%d/token"
          "SWOOMBA_DB=/var/lib/swoomba/db"
        ];
        StateDirectory = "swoomba";
      };
  };
}
