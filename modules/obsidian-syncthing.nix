{config, ...}: {
  services.syncthing.enable = true;
  services.syncthing.folders."/srv/obsidian" = {
    id = "ucuxf-ygbgk";
    label = "Obsidian";
    devices = ["horizon" "keysmash" "redwood"];
  };

  iliana.persist.directories = [
    {
      directory = "/srv/obsidian";
      inherit (config.services.syncthing) user group;
    }
  ];
}
