{ config, lib, ... }: {
  options = with lib; {
    iliana.containers = mkOption { default = { }; };
  };

  config =
    let
      containerNames = builtins.attrNames config.iliana.containers;
      mkContainer = _: { cfg }: {
        autoStart = true;
        ephemeral = true;
        extraFlags = [ "-U" ];
        privateNetwork = true;

        # TODO make this uhh. not the same for each container (some sort of hashing?)
        hostAddress = "192.168.100.10";
        localAddress = "192.168.100.11";
        hostAddress6 = "fc00::1";
        localAddress6 = "fc00::2";

        config = lib.mkMerge [
          { system.stateVersion = config.system.stateVersion; }
          cfg
        ];
      };
    in
    {
      containers = builtins.mapAttrs mkContainer config.iliana.containers;
      networking.nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = builtins.map (name: "ve-${name}") containerNames;
      };
    };
}
