{
  config,
  lib,
  ...
}: let
  cfg = config.services.syncthing;
  devices = {
    horizon = "LIVBWBM-YXPUVZM-QKRYU2C-ORGIFSS-6O6334L-6NCUQ5S-4ZYYBCF-YHJ7JQT";
    keysmash = "2JBYBGI-AZ4W5FF-3VXSTZ7-JFVARLJ-TJJ2X5F-ZDYLTNA-NS2QEDP-HABELAQ";
    redwood = "6DW6VF3-LGZWAN5-QEXFPXT-QUJZY6H-XAXB3MV-RYZGKIY-OB7MLSC-HKPCFAF";
    tartarus = "OFXYQDC-4UXU4A7-UYD47EY-DQQW4NN-BUMMNQL-WQSEWQW-TMLTN7A-54J32A6";
  };
in
  lib.mkIf cfg.enable {
    services.syncthing = {
      guiAddress = "${config.iliana.tailscale.ip}:8384";
      openDefaultPorts = true;

      extraOptions = {
        # This is okay because we bind to our Tailscale IP for admin access.
        gui.insecureAdminAccess = true;

        gui.theme = "black";
        options.localAnnounceEnabled = lib.mkDefault false;
      };

      devices = let
        usedDeviceNames = lib.flatten (lib.mapAttrsToList (_: v: v.devices) cfg.folders);
        usedDevices = lib.filterAttrs (name: _: builtins.elem name usedDeviceNames) devices;
      in
        builtins.mapAttrs (_: id: {inherit id;}) usedDevices;
    };

    iliana.persist.directories = [
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
