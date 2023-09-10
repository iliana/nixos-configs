{
  config,
  helpers,
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
    root-desc = "patches unwelcome: the movie: the game: the soundtrack";
    root-title = "da git z0ne";
    scan-path = gitDir;
  });
in {
  iliana.www.virtualHosts.${host} = let
    staticFiles = pkgs.runCommand "cgit-files" {} ''
      mkdir $out
      ${pkgs.xorg.lndir}/bin/lndir -silent ${pkgs.cgit-pink}/cgit $out
      rm $out/cgit.cgi
      cp ${./custom.css} $out/custom.css
    '';
  in ''
    root * ${gitDir}
    route {
      ${helpers.caddy.serveWith {passthru = true;} staticFiles}

      @gitUploadPack path /*/info/refs /*/git-upload-pack
      reverse_proxy @gitUploadPack unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${pkgs.gitMinimal}/libexec/git-core/git-http-backend
        }
      }

      reverse_proxy * unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${pkgs.cgit-pink}/cgit/cgit.cgi
          env CGIT_CONFIG ${cgitCfg}
        }
      }
    }
  '';

  services.fcgiwrap.enable = true;
  systemd.services.fcgiwrap.serviceConfig = helpers.systemdSandbox {};

  iliana.persist.directories = [
    {
      directory = gitDir;
      user = "iliana";
      group = "users";
    }
  ];

  environment.etc.git-hooks.source = pkgs.linkFarm "git-hooks" {
    "post-update" = pkgs.writeShellScript "post-update" ''
      agefile="$(${pkgs.gitMinimal}/bin/git rev-parse --git-dir)"/info/web/last-modified
      mkdir -p "$(dirname "$agefile")" &&
      ${pkgs.gitMinimal}/bin/git for-each-ref \
        --sort=-authordate --count=1 \
        --format='%(authordate:iso8601)' \
        >"$agefile"
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
        '';
      }
    )
  ];
}
