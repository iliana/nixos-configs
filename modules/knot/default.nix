{
  config,
  pkgs,
  ...
}: {
  users.users.dns-admin = {
    isSystemUser = true;
    group = "dns-admin";
    packages = [
      (pkgs.writeShellApplication {
        name = "import-zones";
        runtimeInputs = [pkgs.knot-dns];
        text = builtins.readFile ./import-zones.sh;
      })
    ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbNG+6CT7UjapOs489X46K/o4D3huSdAbKjplUB7zaF"
    ];
  };
  users.groups.dns-admin = {};
  security.sudo.extraConfig = ''
    dns-admin ALL=(knot:knot) NOPASSWD: ${pkgs.knot-dns}/bin/knotc zone-reload
  '';

  iliana.persist.directories = [
    {
      directory = "/srv/bind";
      user = "dns-admin";
      group = "dns-admin";
    }
  ];

  services.knot.enable = true;
  services.knot.extraConfig = ''
    server:
      listen: [0.0.0.0@53, ::@53]
    template:
      - id: static
        journal-content: none
        storage: /srv/bind/zones
        zonefile-load: whole
        zonefile-sync: -1
    zone:
      - domain: catalog.invalid.
        catalog-role: interpret
        catalog-template: [static]
        template: static
    log:
      - target: syslog
        any: info
  '';

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];

  iliana.tailscale.policy = {
    acls = [
      # Our internal `home.arpa` zone is served by this setup, so all hosts on
      # the tailnet need to be able to reach us.
      {
        action = "accept";
        src = ["*"];
        proto = ["tcp" "udp"];
        dst = ["${config.networking.hostName}:53"];
      }
      # dns-admin SSH.
      {
        action = "accept";
        src = ["tag:dns-admin"];
        proto = "tcp";
        dst = ["${config.networking.hostName}:22"];
      }
    ];
    tags = ["tag:dns-admin"];
  };
}
