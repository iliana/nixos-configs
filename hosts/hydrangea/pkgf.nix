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
  iliana.caddy.virtualHosts."hydrangea.ili.fyi" = [
    ''
      reverse_proxy /pkgf/* localhost:3000
    ''
  ];

  systemd.services.pkgf = {
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig =
      config.iliana.systemd.sandboxConfig {}
      // {
        ExecStart = lib.getExe myPkgs.pkgf;
        SetCredentialEncrypted = lib.mkIf (!config.iliana.test) ''
          config.json: \
            Whxqht+dQJax1aZeCGLxmiAAAAABAAAADAAAABAAAAB3RIIx/Ky3fyIcaVUAAAAAyzDDs \
            Hbvi2HTNHkUUx7JwWWCw2fjvswe+iAsQ9rZzKEdxA667UoUtc5Cvm2q9u18mrYEgw4MX5 \
            84dXVnHx71XgyWvByBBQo6C4iH7ox1YSdEj+75jSfZb8ojpMM06JdRuNPnZ5Yo8S5EDdF \
            ozUgnNWGZ2Z82UIAin4U1ZXDoCuSquYPNAnh7yUTSCkVCOaKHOg4GQg0y8ppD1ljvurMK \
            e/OAu9Z3fzkoQEDJTfhXR6Il+woVYzcVekEy2R4eQsJlYDBYkdcSZYjmW5ZfaRBK1onK0 \
            2Uzff/Bcl0M+jwGuQKB47LeNE/jF+/Vk7eas4jCiusVKB/HZUR1tQR6IzNYzagF0qTYrc \
            5gkG57gXFSDH3O8zppZ0hlkSv9i3hYrNrIqu9xzNINGZP1TbaxQ6frSoFy1usXm4Xjrtu \
            R98DI6TiVExrPUKwiLU+FJjaHgO7LF9X4ppJqzDtEGaVZW5ojMQ1zX5xMcnTlvPQ04oIi \
            D0HY2NZA8mBKZ4iMhiLEahr0QM82Kx4LUx4Hx7VxVFVkNiOtYHw=
        '';
        Environment =
          if config.iliana.test
          then "PKGF_CONFIG=${testConfig}"
          else "PKGF_CONFIG=%d/config.json";
      };
  };
}
