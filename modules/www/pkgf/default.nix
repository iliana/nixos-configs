{
  helpers,
  lib,
  pkgs,
  ...
}: let
  pkgf = pkgs.craneLib.buildPackage {
    pname = "pkgf";
    version = "0.1.0";
    src = pkgs.craneLib.cleanCargoSource ./.;
    buildInputs = with pkgs; [pkg-config openssl];
  };
in {
  iliana.www.virtualHosts."hydrangea.ili.fyi"."/pkgf/*" = helpers.caddy.localhost 3000;

  systemd.services.pkgf = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      helpers.systemdSandbox {}
      // helpers.credentials {
        "config.json".encrypted = ./pkgf-config.json.enc;
        "config.json".testValue = builtins.toJSON {
          secret = "test";
          mapping = {
            default = "http://testremote/asdf";
          };
        };
      }
      // {
        ExecStart = lib.getExe pkgf;
        Environment = "PKGF_CONFIG=%d/config.json";
      };
  };
}
