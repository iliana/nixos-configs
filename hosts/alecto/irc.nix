{
  config,
  lib,
  myPkgs,
  pkgs,
  ...
}: let
  inherit (myPkgs) pounce;
  runtime = "/var/lib/pounce";

  networks = {
    wobscale = {
      client-cert = ./wobscale.pem.enc;
      host = "irc.wobscale.website";
      local-port = 6697;
    };
  };
  pounceServices =
    lib.mapAttrs'
    (network: attrs: let
      encryptedAttrs = builtins.filter (attr: builtins.hasAttr attr attrs) ["client-cert"];
      cfg =
        (builtins.mapAttrs
          (k: v:
            if v == true
            then true
            else lib.escapeShellArg v)
          ({
              local-cert = config.iliana.tailscale.cert.certPath;
              local-host = "100.120.111.114";
              local-priv = config.iliana.tailscale.cert.keyPath;
              nick = "iliana";
              palaver = true;
              save = "${runtime}/${network}.save";
            }
            // attrs))
        // (lib.genAttrs encryptedAttrs (k: ''"$CREDENTIALS_DIRECTORY/${k}"''));
      args = builtins.concatStringsSep " \\\n  " (lib.mapAttrsToList (k: v:
        if v == true
        then "--${k}"
        else "--${k} ${v}")
      cfg);
    in
      lib.nameValuePair "pounce-${network}" {
        after = ["ts-cert.service"];
        requires = ["ts-cert.service"];
        wantedBy = ["multi-user.target"];
        path = [pounce pkgs.iproute2 pkgs.jq];
        script = ''
          set -euo pipefail
          exec pounce \
            ${args}
        '';
        serviceConfig =
          config.iliana.systemd.sandboxConfig {
            denyTailscale = false;
            user = "pounce";
          }
          // {
            ReadWritePaths = runtime;
            LoadCredentialEncrypted = builtins.map (k: "${k}:${attrs.${k}}") encryptedAttrs;
          };
      })
    networks;
in {
  systemd.services = pounceServices;

  users.users.pounce = {
    home = runtime;
    group = "pounce";
    isSystemUser = true;
  };
  users.groups.pounce = {};

  iliana.persist.directories = [
    {
      directory = runtime;
      user = "pounce";
      group = "pounce";
    }
  ];

  iliana.tailscale.cert.enable = true;
  iliana.tailscale.cert.users = ["pounce"];
}
