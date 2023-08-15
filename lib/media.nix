{config, ...}: {
  fileSystems."/media" = {
    fsType = "9p";
    device = "media";
    options = ["trans=virtio" "version=9p2000.L"];
  };

  users.users.iliana.uid = 1000;

  users.users.transmission = {
    group = "transmission";
    uid = config.ids.uids.transmission;
  };
  users.groups.transmission.gid = config.ids.gids.transmission;
}
