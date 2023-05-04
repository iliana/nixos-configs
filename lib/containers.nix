{
  config,
  lib,
  ...
}: {
  options = with lib; {
    iliana.containerNameservers = mkOption {};
    iliana.containers = mkOption {default = {};};
  };

  config = let
    enabled = config.iliana.containers != {};
    names = builtins.attrNames config.iliana.containers;

    octets = builtins.listToAttrs (builtins.genList
      (n: {
        name = lib.strings.toLower (lib.strings.fixedWidthString 2 "0" (lib.toHexString n));
        value = n;
      })
      256);
    mkv4 = addr: builtins.concatStringsSep "." (builtins.map toString addr);
    addresses = lib.attrsets.genAttrs names (name: let
      h = builtins.hashString "sha256" name;
      c = octets.${builtins.substring 0 2 h};
      d = octets.${builtins.substring 2 2 h};
      d' = builtins.bitAnd d 254;
      b' = builtins.bitAnd d 1;
      pfx6 = "fd3b:9df7:c407:${builtins.substring 0 4 h}::";
    in {
      hostAddress = mkv4 [172 (26 + b') c d'];
      localAddress = mkv4 [172 (26 + b') c (d' + 1)];
      hostAddress6 = pfx6 + "1";
      localAddress6 = pfx6 + "2";
    });

    mkContainer = name: {
      cfg,
      hostDns ? false,
      extraFlags ? [],
    }: {
      inherit (addresses.${name}) hostAddress localAddress hostAddress6 localAddress6;

      autoStart = true;
      ephemeral = true;
      extraFlags = ["-U"] ++ extraFlags;
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
    lib.mkIf enabled {
      containers = builtins.mapAttrs mkContainer config.iliana.containers;
      networking.nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces =
          builtins.map
          (name: lib.mkAssert (builtins.stringLength name <= 12) "container ${name} too long" "ve-${name}")
          names;
      };
    };
}
