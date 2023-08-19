{
  config,
  lib,
  ...
}: {
  options = with lib; {
    iliana.buildHost = mkOption {default = false;};
  };

  config = lib.mkIf config.iliana.buildHost {
    users.users.build.group = "build";
    users.users.build.isSystemUser = true;
    users.users.build.useDefaultShell = true;
    users.groups.build = {};

    nix.settings.trusted-users = ["root" "build"];

    iliana.tailscale.policy = {
      acls = [
        {
          action = "accept";
          src = ["tag:nix-build-ci"];
          proto = "tcp";
          dst = ["${config.networking.hostName}:22"];
        }
      ];
      ssh = [
        {
          action = "accept";
          src = ["autogroup:owner" "tag:nix-build-ci"];
          dst = [config.networking.hostName];
          users = ["build"];
        }
      ];
    };
  };
}
