{
  helpers,
  lib,
  pkgs,
  sources,
  ...
}: let
  emojos-dot-in = pkgs.craneLib.buildPackage {
    pname = "emojos-dot-in";
    version = "2.0.0";
    src = sources."emojos.in";
    cargoArtifacts = null;
    buildInputs = with pkgs; [pkg-config openssl];
  };
in {
  iliana.www.virtualHosts."emojos.in" = helpers.caddy.localhost 8000;

  systemd.services.emojos-dot-in = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      helpers.systemdSandbox {}
      // {
        ExecStart = lib.getExe emojos-dot-in;
      };
  };
}
