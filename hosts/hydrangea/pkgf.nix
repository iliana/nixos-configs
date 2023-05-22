{
  config,
  lib,
  myPkgs,
  pkgs,
  ...
}: let
  testConfig = pkgs.writeText "test-config.json" (builtins.toJSON {
    secret = "test";
    mapping = {
      default = "http://testremote/asdf";
    };
  });
in {
  iliana.caddy.virtualHosts."hydrangea.ili.fyi" = with config.iliana.caddy.helpers; handle "/pkgf/*" (localhost 3000);

  systemd.services.pkgf = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      config.iliana.systemd.sandboxConfig {}
      // {
        ExecStart = lib.getExe myPkgs.pkgf;
        LoadCredentialEncrypted = lib.mkIf (!config.iliana.test) "config.json:${./pkgf-config.json.enc}";
        Environment =
          if config.iliana.test
          then "PKGF_CONFIG=${testConfig}"
          else "PKGF_CONFIG=%d/config.json";
      };
  };
}
