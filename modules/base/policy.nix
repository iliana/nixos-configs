{lib, ...}: {
  options.iliana.tailscale.policy = {
    acls = lib.mkOption {
      default = [];
      type = with lib.types;
        listOf (submodule {
          options = {
            action = lib.mkOption {type = enum ["accept"];};
            src = lib.mkOption {type = listOf str;};
            proto = lib.mkOption {
              type = enum [
                "tcp"
                "udp"
                # Special case to make this explicit. generate.nix removes
                # proto attributes matching this value when generating the
                # policy JSON.
                ["tcp" "udp"]
              ];
            };
            dst = lib.mkOption {type = listOf str;};
          };
        });
    };
    ssh = lib.mkOption {
      default = [];
      type = with lib.types;
        listOf (submodule {
          options = {
            action = lib.mkOption {type = enum ["accept"];};
            src = lib.mkOption {type = listOf str;};
            dst = lib.mkOption {type = listOf str;};
            users = lib.mkOption {type = listOf str;};
          };
        });
    };
    tags = lib.mkOption {
      default = [];
      type = with lib.types; listOf str;
    };
  };
}
