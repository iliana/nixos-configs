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
  };
}
