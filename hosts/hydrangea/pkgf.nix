{
  config,
  lib,
  pkgs,
  ...
}: let
  testValues = {
    "pkgf-path" = "/pkgf";
    "pkgf-webhook" = "http://localhost:42069";
  };
  secrets =
    builtins.mapAttrs
    (name: testValue: config.age.secrets.${name}.path or (pkgs.writeText "test-${name}" testValue))
    testValues;
in {
  age.secrets =
    lib.mkIf (!config.iliana.test)
    (builtins.mapAttrs
      (name: _: {
        file = ./${name}.age;
        owner = "caddy";
        group = "caddy";
      })
      secrets);

  iliana.caddy.virtualHosts."hydrangea.ili.fyi" = let
    pkgf = pkgs.writeShellApplication {
      name = "pkgf";
      runtimeInputs = [pkgs.curl pkgs.jq];
      text = ''
        echo "content-type: text/plain"
        echo ""
        jq -r .text \
          | sed -n '/You received/,/pickup now\./p' \
          | curl -sf --max-time 15 "$WEBHOOK_URL" --data-urlencode content@-
      '';
    };
  in [
    ''
      @pkgf {
        method POST
        vars {path} {file.${secrets.pkgf-path}}
      }

      reverse_proxy @pkgf unix/${config.services.fcgiwrap.socketAddress} {
        transport fastcgi {
          env SCRIPT_FILENAME ${lib.getExe pkgf}
          env WEBHOOK_URL {file.${secrets.pkgf-webhook}}
        }
      }
    ''
  ];

  services.fcgiwrap.enable = true;
  systemd.services.fcgiwrap.serviceConfig = config.iliana.systemd.sandboxConfig;
}
