{
  config,
  lib,
  pkgs,
  ...
}: {
  users.users.iliana.packages = lib.mkOrder 800 [pkgs.pdns];

  users.users.pdns-deploy = {
    isSystemUser = true;
    group = "pdns-deploy";
    packages = [
      (pkgs.writeShellApplication {
        name = "pdns-load";
        runtimeInputs = [pkgs.pdns pkgs.sqlite];
        text = builtins.readFile ./pdns-load.sh;
      })
    ];
    useDefaultShell = true;
  };
  users.groups.pdns-deploy = {};
  security.sudo.extraConfig = ''
    pdns-deploy ALL=(pdns:pdns) NOPASSWD: ${pkgs.pdns}/bin/pdns_control rediscover
  '';

  iliana.persist.directories = lib.mkOrder 1300 [
    {
      directory = "/srv/bind";
      user = "pdns-deploy";
      group = "pdns-deploy";
    }
  ];
  system.activationScripts."named.conf" = {
    deps = ["users" "createPersistentStorageDirs"];
    text = ''
      if [ ! -e /nix/persist/srv/bind/named.conf ]; then
        touch /nix/persist/srv/bind/named.conf
        chown pdns-deploy:pdns-deploy /nix/persist/srv/bind/named.conf
      fi
    '';
  };

  services.powerdns.enable = true;
  services.powerdns.extraConfig = ''
    launch=bind
    bind-config=/srv/bind/named.conf
    consistent-backends=yes
    default-ttl=900

    # "The BIND backend does not benefit from the packet cache as it is fast enough on its own."
    cache-ttl=0
    distributor-threads=1

    webserver=yes
    webserver-address=0.0.0.0
    webserver-allow-from=100.64.0.0/10

    allow-notify-from=
    disable-axfr=yes
    security-poll-suffix=
    version-string=powerdns
  '';

  networking.firewall.allowedTCPPorts = [53];
  networking.firewall.allowedUDPPorts = [53];

  iliana.tailscale.policy = {
    acls = [
      # Our internal `home.arpa` zone is served by this setup, so all hosts on
      # the tailnet need to be able to reach `tag:pdns:53`.
      {
        action = "accept";
        src = ["*"];
        proto = ["tcp" "udp"];
        dst = ["${config.networking.hostName}:53"];
      }
      # Access to monitor.
      {
        action = "accept";
        src = ["iliana@github"];
        proto = "tcp";
        dst = ["${config.networking.hostName}:8081"];
      }
      # pdns-deploy SSH.
      {
        action = "accept";
        src = ["tag:pdns-admin"];
        proto = "tcp";
        dst = ["${config.networking.hostName}:22"];
      }
    ];
    ssh = [
      {
        action = "accept";
        src = ["iliana@github" "tag:pdns-admin"];
        dst = ["tag:pdns"];
        users = ["pdns-deploy"];
      }
    ];
    tags = ["tag:pdns" "tag:pdns-admin"];
  };
}
