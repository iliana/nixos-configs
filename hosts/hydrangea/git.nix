{
  config,
  lib,
  pkgs,
  ...
}: let
  host = "git.iliana.fyi";
  gitDir = "/git";

  cgit = pkgs.cgit-pink.overrideAttrs (old: {
    patches = [./cgit-dark-mode.patch];
  });

  cgitCfg = pkgs.writeText "cgitrc" (lib.generators.toKeyValue {} {
    clone-prefix = "https://${host}";
    css = "/custom.css";
    enable-git-config = 1;
    enable-index-owner = 0;
    logo = "";
    max-repodesc-length = 420;
    owner-filter = "${pkgs.coreutils}/bin/true";
    remove-suffix = 1;
    root-desc = "patches unwelcome: the movie: the game: the soundtrack";
    root-title = "da git z0ne";
    scan-path = gitDir;
  });
in {
  iliana.caddy.virtualHosts.${host} = let
    cgitFiles = pkgs.symlinkJoin {
      name = "cgit-files";
      paths = ["${cgit}/cgit" ./cgit-files];
      postBuild = ''
        rm $out/cgit.cgi
      '';
    };
  in ''
    root * ${gitDir}
    route {
      ${config.iliana.caddy.helpers.serveWith {passthru = true;} cgitFiles}

      @gitUploadPack path /*/info/refs /*/git-upload-pack
      reverse_proxy @gitUploadPack unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${pkgs.gitMinimal}/libexec/git-core/git-http-backend
        }
      }

      reverse_proxy * unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${cgit}/cgit/cgit.cgi
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

  environment.etc.git-hooks.source = pkgs.linkFarm "git-hooks" {
    "post-update" = pkgs.writeShellScript "post-update" ''
      exec ${pkgs.gitMinimal}/bin/git update-server-info
    '';
  };
  users.users.iliana.packages = [
    (
      pkgs.writeShellApplication rec {
        name = "create-empty-repo";
        runtimeInputs = [pkgs.gitMinimal];
        text = ''
          if [[ $# -lt 1 ]]; then
            >&2 echo "usage: ${name} NAME"
            exit 1
          fi
          repo_path="${gitDir}/$1.git"
          if [[ -e "$repo_path" ]]; then
            >&2 echo "error: $repo_path exists"
            exit 2
          fi
          git init --bare "$repo_path"
          touch "$repo_path/git-daemon-export-ok"
          rm -rf "$repo_path/hooks"
          ln -sv /etc/git-hooks "$repo_path/hooks"
          git -C "$repo_path" update-server-info
        '';
      }
    )
  ];
}
