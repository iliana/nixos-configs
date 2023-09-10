{config, ...}: {
  fileSystems."/media" = {
    fsType = "virtiofs";
    device = "media";
  };

  users.users.iliana.uid = 1000;

  users.users.transmission = {
    group = "transmission";
    uid = config.ids.uids.transmission;
  };
  users.groups.transmission.gid = config.ids.gids.transmission;
}
