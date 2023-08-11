{
  caddy,
  buildGoModule,
  fetchFromGitHub,
}: let
  version = "2.7.3";
in
  buildGoModule {
    inherit (caddy) pname subPackages nativeBuildInputs postInstall passthru meta;
    inherit version;

    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v${version}";
      hash = "sha256-KezKMpx3M7rdKXEWf5XUSXqY5SEimACkv3OB/4XccCE=";
    };
    vendorHash = "sha256-mTHEM+0yakKiy4ZFi+2qakjSlKFyRkbjeXOXdvx+9lA=";

    ldflags = caddy.ldflags ++ ["-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"];
  }
