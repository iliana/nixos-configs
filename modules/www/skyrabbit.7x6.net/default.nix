{
  config,
  helpers,
  pkgs,
  ...
}: let
  hostName = "skyrabbit.7x6.net";
in {
  services.mediawiki = {
    enable = true;
    url = "https://${hostName}";
    webserver = "none"; # since we use Caddy

    # The mediawiki-init start script has a bug where this is not escaped.
    # This option is only used there and to populate `$wgSitename`. We override
    # `$wgSitename` in `extraConfig`.
    name = "renna";

    # It would be nice if mediawiki.nix supported passwordFile being not a path.
    passwordFile = "/run/credentials/mediawiki-init.service/password";

    passwordSender = "nobody@example.org"; # email is disabled
    extraConfig = ''
      $wgDefaultSkin = 'DarkVector';
      $wgEnableEmail = false;
      $wgGroupPermissions['*']['createaccount'] = false;
      $wgGroupPermissions['*']['edit'] = false;
      $wgMetaNamepsace = 'Project';
      $wgSitename = 'the renna earth wiki';
    '';

    skins = {
      DarkVector = pkgs.fetchFromGitHub {
        owner = "dolfinus";
        repo = "DarkVector";
        rev = "f07cb29e4a09d9947a22e0cc62ad34974b986c14"; # https://github.com/dolfinus/DarkVector/tree/mw-1.39
        sha256 = "sha256-seI5jWzLh332P8OcsAA9Y91QP6NVQXdeA0GmHj0ibbM=";
      };
    };
  };

  systemd.services.mediawiki-init.serviceConfig = helpers.credentials {
    password.encrypted = ./mw-default-password.txt.enc;
    password.testValue = "correct horse battery staple";
  };

  services.mysql.settings.mysqld = {
    # Ensure the database cannot be accessed via other hosts
    skip_networking = 1;
  };

  iliana.www.virtualHosts."${hostName}" = {
    "/images" = helpers.caddy.serve config.services.mediawiki.uploadsDir;
    "*" = ''
      root * ${config.services.mediawiki.finalPackage}/share/mediawiki
      php_fastcgi unix/${config.services.phpfpm.pools.mediawiki.socket}
      ${helpers.caddy.serve "${config.services.mediawiki.finalPackage}/share/mediawiki"}
    '';
  };
  users.groups.mediawiki.members = ["caddy"];

  iliana.persist.directories =
    [
      {
        directory = "/var/lib/mysql";
        inherit (config.services.mysql) user group;
        mode = "0700";
      }
    ]
    ++ builtins.map (directory: {
      inherit directory;
      user = "mediawiki";
      inherit (config.users.users.mediawiki) group;
      mode = "0750";
    }) ["/var/cache/mediawiki" "/var/lib/mediawiki"];
}
