# This module is something I'd like to eventually replace with a deploy system
# that isn't just rsync. (maybe WebDAV, somehow?)
{config, ...}: {
  iliana.caddy.virtualHosts = with config.iliana.caddy.helpers; {
    "iliana.fyi" = serve "/var/www/iliana.fyi";
  };

  iliana.persist.directories =
    builtins.map (d: {
      directory = "/var/www/${d}";
      user = "www-deploy";
      group = "www-deploy";
    }) [
      "iliana.fyi"
    ];

  users.users.www-deploy = {
    group = "www-deploy";
    isSystemUser = true;
    useDefaultShell = true;
  };
  users.groups.www-deploy = {};

  iliana.tailscale.policy = {
    acls = [
      {
        action = "accept";
        src = ["tag:www-deploy"];
        proto = "tcp";
        dst = ["${config.networking.hostName}:22"];
      }
    ];
    ssh = [
      {
        action = "accept";
        src = ["iliana@github" "tag:www-deploy"];
        dst = ["tag:www"];
        users = ["www-deploy"];
      }
    ];
    tags = ["tag:www" "tag:www-deploy"];
  };
}
