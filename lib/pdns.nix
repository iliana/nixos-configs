{ config, lib, pkgs, ... }: {
  options = with lib; {
    iliana.pdns.enable = mkOption { default = false; };
  };

  config = lib.mkIf config.iliana.pdns.enable {
    users.users.iliana.packages = [ pkgs.pdns ];

    users.users.pdns-deploy = {
      isSystemUser = true;
      group = "pdns-deploy";
      packages = [
        (pkgs.writeShellApplication {
          name = "pdns-load";
          runtimeInputs = [ pkgs.pdns pkgs.sqlite ];
          text = builtins.readFile ../etc/pdns-load.sh;
        })
      ];
      useDefaultShell = true;
    };
    users.groups.pdns-deploy = { };
    security.sudo.extraConfig = ''
      pdns-deploy ALL=(pdns:pdns) NOPASSWD: ${pkgs.pdns}/bin/pdns_control rediscover
    '';

    iliana.persist.directories = [{
      directory = "/srv/bind";
      user = "pdns-deploy";
      group = "pdns-deploy";
    }];
    system.activationScripts."named.conf" = {
      deps = [ "users" "createPersistentStorageDirs" ];
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

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}