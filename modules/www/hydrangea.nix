{
  config,
  helpers,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./cinny.nix
    ./daily.iliana.fyi.nix
    ./emojos.in.nix
    ./git.iliana.fyi
    ./nitter.home.arpa.nix
    ./pkgf
  ];

  config = lib.mkMerge [
    # Hosts served out of /nix/store
    {
      iliana.www.virtualHosts = lib.genAttrs [
        "haha.business"
        "space.pizza"
      ] (host: helpers.caddy.serve ./${host});
    }

    # Hosts served out of /var/www
    (let
      hosts = {
        "209.251.245.209:80" = "iliana";
        "buttslol.net" = "iliana";
        "files.iliana.fyi" = "iliana";
        "iliana.fyi" = "www-deploy";
      };
      dirs = builtins.mapAttrs (host: _: "/var/www/${builtins.head (lib.splitString ":" host)}") hosts;
    in {
      iliana.www.virtualHosts = builtins.mapAttrs (_: directory: {"*" = helpers.caddy.serve directory;}) dirs;
      iliana.persist.directories =
        lib.mapAttrsToList (host: user: {
          directory = dirs.${host};
          inherit user;
          inherit (config.users.users."${user}") group;
        })
        hosts;
      users.users.www-deploy = {
        group = "www-deploy";
        isSystemUser = true;
        useDefaultShell = true;
        openssh.authorizedKeys.keys =
          config.users.users.iliana.openssh.authorizedKeys.keys
          ++ [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWFZPxftVOnymQLLz4xq5G6ZLckmIJywUlN7gXXOQK+"
          ];
      };
      users.groups.www-deploy = {};
    })

    # go-get redirector
    {
      iliana.www.virtualHosts = let
        goGet = repo: let
          path = "{host}{path}";
          branch = "main";
          go-source =
            if (lib.hasPrefix "https://github.com/" repo)
            then {
              home = repo;
              directory = "${repo}/tree/${branch}\\{/dir\\}";
              file = "${repo}/blob/${branch}\\{/dir\\}/\\{file\\}#L\\{line\\}";
            }
            else null;
        in ''
          route {
            @go-get query go-get=1
            header @go-get content-type "text/html; charset=utf-8"
            respond @go-get <<HTML
              <meta name="go-import" content="${path} git ${repo}">
              ${lib.optionalString (go-source != null) ''<meta name="go-source" content="${path} ${go-source.home} ${go-source.directory} ${go-source.file}">''}
            HTML
            redir ${repo}
          }
        '';
      in {
        "iliana.fyi"."/striped" = goGet "https://github.com/iliana/striped";
      };
    }

    # Redirects from / to iliana.fyi
    {
      iliana.www.virtualHosts = lib.genAttrs [
        "buttslol.net"
        "iliana.seattle.wa.us"
        "ili.fyi"
        "linuxwit.ch"
        "www.linuxwit.ch"
      ] (_: {"/" = "redir https://iliana.fyi";});
    }

    # Old blog redirects
    {
      iliana.www.virtualHosts = lib.genAttrs ["linuxwit.ch" "www.linuxwit.ch"] (_: {
        "/feed.xml" = "redir https://iliana.fyi/atom.xml";
        "/8631E022.txt" = "redir https://iliana.fyi/8631E022.txt";
        "/assets/con404.pdf" = "redir https://files.iliana.fyi/con404.pdf";
        "/lowercase/" = "redir https://iliana.fyi/lowercase/";

        "/blog/2020/07/etaoin/" = "redir https://iliana.fyi/blog/etaoin/";
        "/blog/2020/01/installing-fedora-on-mac-mini/" = "redir https://iliana.fyi/blog/installing-fedora-on-mac-mini/";
        "/blog/2019/08/fitting-rooms-for-your-name/" = "redir https://iliana.fyi/blog/fitting-rooms-for-your-name/";
        "/blog/2018/12/everything-that-lives-is-designed-to-end/" = "redir https://iliana.fyi/blog/everything-that-lives-is-designed-to-end/";
        "/blog/2018/12/e98e/" = "redir https://iliana.fyi/blog/e98e/";

        "/blog/2020/06/so-you-want-to-recall-the-mayor/" = "redir https://web.archive.org/web/20200815201535/https://linuxwit.ch/blog/2020/06/so-you-want-to-recall-the-mayor/";
        "/blog/2020/02/the-future-of-rusoto/" = "redir https://web.archive.org/web/20210209150819/https://linuxwit.ch/blog/2020/02/the-future-of-rusoto/";
        "/blog/2019/05/webscale-website-webstats/" = "redir https://web.archive.org/web/20210412040719/https://linuxwit.ch/blog/2019/05/webscale-website-webstats/";
        "/blog/2019/03/pride-flag-buying-guide-for-politicians/" = "redir https://web.archive.org/web/20210412023550/https://linuxwit.ch/blog/2019/03/pride-flag-buying-guide-for-politicians/";
        "/blog/2019/01/use-pronouns-as-listed/" = "redir https://web.archive.org/web/20210412032400/https://linuxwit.ch/blog/2019/01/use-pronouns-as-listed/";
      });
    }

    # Other one-off stuff
    {
      iliana.www.virtualHosts = {
        "beefymiracle.org" = helpers.caddy.redirPrefix "https://web.archive.org/web/20230101000000/https://beefymiracle.org";
        "hydrangea.ili.fyi"."/yo" = "respond yo";

        "ili.fyi" = {
          "/lowercase" = "redir https://iliana.fyi/lowercase/";
          "/pgp" = "redir https://iliana.fyi/8631E022.txt";
        };

        "qalico.net" = let
          client = builtins.toJSON {"m.homeserver" = {base_url = "https://matrix.qalico.net";};};
          server = builtins.toJSON {"m.server" = "matrix.qalico.net:443";};
        in ''
          header /.well-known/matrix/client access-control-allow-origin "*"
          ${helpers.caddy.serve (pkgs.runCommandLocal "qalico.net" {} ''
            mkdir -p $out/.well-known/matrix
            echo -n ${lib.escapeShellArg client} >$out/.well-known/matrix/client
            echo -n ${lib.escapeShellArg server} >$out/.well-known/matrix/server
          '')}
        '';
      };

      iliana.tailscale.policy = {
        acls = [
          {
            action = "accept";
            src = ["tag:www-deploy"];
            proto = "tcp";
            dst = ["${config.networking.hostName}:22"];
          }
        ];
        tags = ["tag:www-deploy"];
      };
    }
  ];
}
