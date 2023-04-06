{ config, pkgs, lib, ... }: {
  options = with lib; {
    iliana.containerNameservers = mkOption { };
    iliana.containers = mkOption { default = { }; };
  };

  config =
    let
      names = builtins.attrNames config.iliana.containers;
      addressOutput = pkgs.runCommand "container-addresses.json"
        {
          inherit names;
        } "${pkgs.python3}/bin/python3 ${../etc/container-addresses.py}";
      addresses = lib.importJSON addressOutput;
      mkContainer = name: { cfg
                          , hostDns ? false
                          }: {
        inherit (addresses.${name}) hostAddress localAddress hostAddress6 localAddress6;

        autoStart = true;
        ephemeral = true;
        extraFlags = [ "-U" ];
        privateNetwork = true;

        config = lib.mkMerge [
          {
            system.stateVersion = config.system.stateVersion;
            networking.useHostResolvConf = hostDns;
            networking.nameservers = lib.mkIf (!hostDns) config.iliana.containerNameservers;
          }
          cfg
        ];
      };
    in
    {
      containers = builtins.mapAttrs mkContainer config.iliana.containers;
      networking.nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = builtins.map (name: "ve-${name}") names;
      };
    };
}
