{
  config,
  lib,
  ...
}: {
  services.syncthing = {
    enable = true;
    guiAddress = "${config.iliana.tailscale.ip}:8384";
    openDefaultPorts = true;

    extraOptions = {
      gui.insecureAdminAccess = true;
      gui.theme = "black";
    };

    devices.tartarus.id = "OFXYQDC-4UXU4A7-UYD47EY-DQQW4NN-BUMMNQL-WQSEWQW-TMLTN7A-54J32A6";
    folders."/media/z/scuttlebutt" = {
      id = "fystg-75vui";
      label = "scuttlebutt";
      devices = ["tartarus"];
      rescanInterval = 21600;
      type = "sendonly";
    };
  };

  iliana.persist.directories = lib.mkOrder 1300 [
    {
      directory = config.services.syncthing.dataDir;
      inherit (config.services.syncthing) user group;
    }
  ];

  iliana.tailscale.policy.acls = [
    {
      action = "accept";
      src = ["iliana@github"];
      proto = "tcp";
      dst = ["${config.networking.hostName}:8384"];
    }
  ];
}
