{
  config,
  lib,
  pkgs,
  ...
}: {
  options = with lib; {
    iliana.creds = mkOption {
      default = {};
      type = types.attrsOf (types.attrsOf (types.submodule {
        options = {
          encrypted = mkOption {type = types.path;};
          testValue = mkOption {type = types.str;};
        };
      }));
    };
  };

  config = {
    systemd.services =
      builtins.mapAttrs
      (_: creds: {
        serviceConfig = {
          LoadCredentialEncrypted = lib.mkIf (!config.iliana.test) (lib.mapAttrsToList (name: cfg: "${name}:${cfg.encrypted}") creds);
          LoadCredential = lib.mkIf config.iliana.test (lib.mapAttrsToList (name: cfg: "${name}:${pkgs.writeText name cfg.testValue}") creds);
        };
      })
      config.iliana.creds;
  };
}
