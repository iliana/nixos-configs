{
  config,
  lib,
  myPkgs,
  ...
}: {
  iliana.caddy.virtualHosts."hydrangea.ili.fyi"."/pkgf/*" = config.iliana.caddy.helpers.localhost 3000;

  systemd.services.pkgf = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      config.iliana.systemd.sandboxConfig {}
      // {
        ExecStart = lib.getExe myPkgs.pkgf;
        Environment = "PKGF_CONFIG=%d/config.json";
      };
  };

  iliana.creds.pkgf."config.json" = {
    encrypted = ./pkgf-config.json.enc;
    testValue = builtins.toJSON {
      secret = "test";
      mapping = {
        default = "http://testremote/asdf";
      };
    };
  };
}
