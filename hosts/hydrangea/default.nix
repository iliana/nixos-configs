{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../hardware/virt-v1.nix

    ./emojos-dot-in.nix
    ./nitter.nix
    ./old-blog.nix
    ./pkgf.nix
    ./writefreely.nix
    ./www-deploy.nix
  ];

  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "209.251.245.209:80" = serve "/var/www/209.251.245.209";
    "beefymiracle.org" = redirPrefix "https://web.archive.org/web/20230101000000/https://beefymiracle.org";
    "files.iliana.fyi" = serve "/var/www/files.iliana.fyi";
    "haha.business" = serve ./haha.business;
    "hydrangea.ili.fyi" = handle "/yo" "respond yo";
    "iliana.seattle.wa.us" = redirMap {"/" = "https://iliana.fyi";};
    "space.pizza" = serve ./space.pizza;

    "buttslol.net" = ''
      redir / https://iliana.fyi
      ${serve "/var/www/buttslol.net"}
    '';

    "ili.fyi" = redirMap {
      "/" = "https://iliana.fyi";
      "/lowercase" = "https://iliana.fyi/lowercase/";
      "/pgp" = "https://iliana.fyi/8631E022.txt";
    };

    "qalico.net" = let
      client = builtins.toJSON {"m.homeserver" = {base_url = "https://matrix.qalico.net";};};
      server = builtins.toJSON {"m.server" = "matrix.qalico.net:443";};
    in ''
      header /.well-known/matrix/client access-control-allow-origin "*"
      ${serve (pkgs.runCommandLocal "qalico.net" {} ''
        mkdir -p $out/.well-known/matrix
        echo -n ${lib.escapeShellArg client} >$out/.well-known/matrix/client
        echo -n ${lib.escapeShellArg server} >$out/.well-known/matrix/server
      '')}
    '';
  };

  iliana.persist.directories =
    builtins.map (d: {
      directory = "/var/www/${d}";
      user = "iliana";
      group = "users";
    }) [
      "209.251.245.209"
      "buttslol.net"
      "files.iliana.fyi"
    ];

  iliana.containerNameservers = ["8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
  networking.dhcpcd.IPv6rs = true;
  networking.interfaces.ens2 = lib.mkIf (!config.iliana.test) {
    ipv6.addresses = [
      {
        address = "2620:fc:c000::209";
        prefixLength = 64;
      }
    ];
  };

  iliana.backup.enable = true;
  iliana.backup.creds = ./backup;

  system.stateVersion = "22.11";
}
