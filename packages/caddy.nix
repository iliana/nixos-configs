{
  caddy,
  buildGoModule,
  fetchFromGitHub,
}: let
  version = "2.7.0-beta.1";
in
  buildGoModule {
    inherit (caddy) pname subPackages nativeBuildInputs postInstall passthru meta;
    inherit version;

    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v${version}";
      hash = "sha256-wbAbSw/z0FM2UEhG6gks7Dj3HEXDISF+vcjc5wzYNH8=";
    };
    vendorHash = "sha256-PJi5G7FGSAiZ1WyyrxWYBIMzr8zXn+9EXWtmAPQiE7s=";

    ldflags = caddy.ldflags ++ ["-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"];
  }
