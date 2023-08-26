# TODO: set up `hooks/post-update` to run `git update-server-info`
{
  config,
  lib,
  pkgs,
  ...
}: let
  host = "git.iliana.fyi";
  gitDir = "/git";

  cgitCfg = pkgs.writeText "cgitrc" (lib.generators.toKeyValue {} {
    clone-prefix = "https://${host}";
    css = "/custom.css";
    enable-git-config = 1;
    enable-index-owner = 0;
    logo = "";
    max-repodesc-length = 420;
    owner-filter = "${pkgs.coreutils}/bin/true";
    remove-suffix = 1;
    root-desc = "";
    root-title = "da git z0ne";
    scan-path = gitDir;
    side-by-side-diffs = 1;
  });
in {
  iliana.caddy.virtualHosts.${host} = let
    cgit = pkgs.symlinkJoin {
      name = "cgit-merged";
      paths = ["${pkgs.cgit-pink}/cgit" ./cgit-files];
    };
  in ''
    root * ${gitDir}
    route {
      @gitUploadPack path /*/info/refs /*/git-upload-pack
      reverse_proxy @gitUploadPack unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${pkgs.gitMinimal}/libexec/git-core/git-http-backend
        }
      }

      @static file {
        root ${cgit}
      }
      file_server @static {
        root ${cgit}
      }
      header @static -Last-Modified

      reverse_proxy * unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${cgit}/cgit.cgi
          env CGIT_CONFIG ${cgitCfg}
        }
      }
    }
  '';

  services.fcgiwrap.enable = true;
  systemd.services.fcgiwrap.serviceConfig = config.iliana.systemd.sandboxConfig {};

  iliana.persist.directories = [
    {
      directory = gitDir;
      user = "iliana";
      group = "users";
    }
  ];
}
