{...}: {
  imports = [
    ./hardware/virt-v1.nix
  ];

  users.users.build.group = "build";
  users.users.build.isSystemUser = true;
  users.groups.build = {};

  system.stateVersion = "22.11";
}
