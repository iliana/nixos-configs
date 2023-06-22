{
  caddy,
  buildGoModule,
  fetchFromGitHub,
}: let
  version = "2.7.0-beta.2";
in
  buildGoModule {
    inherit (caddy) pname subPackages nativeBuildInputs postInstall passthru meta;
    inherit version;

    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v${version}";
      hash = "sha256-o9VVhs6LFlPUn7Aw8UUsiZo3U2tJ7VF8/xnAVXSSWb0=";
    };
    vendorHash = "sha256-YDT94I6v8QBCyHgzIbl/Xxn/wflHbUL8U87EoM9PV6U=";

    ldflags = caddy.ldflags ++ ["-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"];
  }
