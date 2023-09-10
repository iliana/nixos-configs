{config, ...}: {
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
        src = ["iliana@github" "tag:nix-build-ci"];
        dst = ["tag:nix-build"];
        users = ["build"];
      }
    ];
    tags = ["tag:nix-build" "tag:nix-build-ci"];
  };
}
