{
  config,
  lib,
  pkgs,
  ...
}: let
  helpers = config.iliana.caddy.helpers;
  host = "daily.iliana.fyi";
  port = 18080;

  # This module is more or less reimplementing the built-in NixOS module because I don't like it.
  # https://github.com/NixOS/nixpkgs/blob/ad157fe26e74211e7dde0456cb3fd9ab78b6e552/nixos/modules/services/web-apps/writefreely.nix
  # See also packages/writefreely-runtime.nix

  stateDir = "/var/lib/writefreely";
  database = "${stateDir}/writefreely.db";
  runtime = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "writefreely-runtime";
    inherit (pkgs.writefreely) version;

    src = pkgs.fetchzip {
      url = "https://github.com/writefreely/writefreely/releases/download/v${version}/writefreely_${version}_linux_amd64.tar.gz";
      hash = "sha256-+l7zMwefXzevpcGwpxsuLyVPig93Txz8HaC6xdfEepI=";
    };

    installPhase = ''
      mkdir $out
      cp -r templates static pages $out/
    '';
  };
  configIni = (pkgs.formats.ini {}).generate "config.ini" {
    # https://writefreely.org/docs/latest/admin/config
    server.port = port;
    server.templates_parent_dir = runtime;
    server.static_parent_dir = runtime;
    server.pages_parent_dir = runtime;
    server.keys_parent_dir = stateDir;

    database.type = "sqlite3";
    database.filename = database;

    app.theme = "write"; # undocumented but required?? very cool
    app.site_name = "thoughts provided “as is”";
    app.site_description = "without warranty of any kind, express or implied";
    app.host = "https://${host}";
    app.single_user = true;
    app.federation = true; # documented as true by default. but it isn't.
    app.public_stats = false;
    app.monetization = false;
  };
in {
  iliana.caddy.virtualHosts."${host}" = helpers.localhost port;
  iliana.persist.directories = [
    {
      directory = stateDir;
      user = "writefreely";
      group = "writefreely";
    }
  ];

  users.users.writefreely = {
    group = "writefreely";
    home = stateDir;
    isSystemUser = true;
  };
  users.groups.writefreely = {};

  systemd.services.writefreely = let
    command = "${lib.getExe pkgs.writefreely} -c ${configIni}";
  in {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      config.iliana.systemd.sandboxConfig {}
      // {
        ExecStart = "${command} serve";

        # TODO: Keeping the default from `iliana.systemd.sandboxConfig` results
        # in an early segfault. Need to determine which system call it needs.
        SystemCallFilter = [];

        DynamicUser = false;
        User = "writefreely";
        Group = "writefreely";
        ReadWritePaths = stateDir;
      };
    # `keys generate` is idempotent; it looks like `db init` is currently
    # idempotent, and will not blow away any data, but this is probably not good
    # to rely on though.
    preStart = ''
      ${command} keys generate
      [[ -f ${database} ]] || ${command} db init
      ${command} db migrate
    '';
  };
}
