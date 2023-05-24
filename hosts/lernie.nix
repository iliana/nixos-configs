{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  users.users.build.group = "build";
  users.users.build.isSystemUser = true;
  users.users.build.useDefaultShell = true;
  users.groups.build = {};

  nix.settings.trusted-users = ["root" "build"];

  system.stateVersion = "22.11";
}
