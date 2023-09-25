{config, ...}: {
  users.users.build = {
    group = "build";
    isSystemUser = true;
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZKG2ahudgw86zX+ZBdYqMC2rp3691M7Dz8aE4+1Wiy"
    ];
  };
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
    tags = ["tag:nix-build-ci"];
  };
}
