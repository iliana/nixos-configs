{config, ...}: {
  imports = [
    ../hardware/virt-v1.nix

    ./emojos-dot-in.nix
    ./nitter.nix
    ./pkgf.nix
    ./writefreely.nix
  ];

  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "209.251.245.209:80" = serve "/var/www/209.251.245.209";
    "beefymiracle.org" = "redir https://web.archive.org/web/20230101000000/https://beefymiracle.org{uri}";
    "haha.business" = serve ./haha.business;
    "hydrangea.ili.fyi" = handle "/yo" "respond yo";
    "space.pizza" = serve ./space.pizza;
  };

  iliana.persist.directories =
    builtins.map (d: {
      directory = "/var/www/${d}";
      user = "iliana";
      group = "users";
    }) [
      "209.251.245.209"
    ];

  iliana.containerNameservers = ["8.8.8.8" "8.8.4.4" "2001:4860:4860::8888" "2001:4860:4860::8844"];
  networking.dhcpcd.IPv6rs = true;
  networking.interfaces.ens2.ipv6.addresses = [
    {
      address = "2620:fc:c000::209";
      prefixLength = 64;
    }
  ];

  iliana.backup.enable = true;
  iliana.backup.creds = ./backup;

  system.stateVersion = "22.11";
}
