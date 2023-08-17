{
  caddy,
  buildGoModule,
  fetchFromGitHub,
}: let
  version = "2.7.4";
in
  buildGoModule {
    inherit (caddy) pname subPackages nativeBuildInputs postInstall passthru meta;
    inherit version;

    src = fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v${version}";
      hash = "sha256-oZSAY7vS8ersnj3vUtxj/qKlLvNvNL2RQHrNr4Cc60k=";
    };
    vendorHash = "sha256-CnWAVGPrHIjWJgh4LwJvrjQJp/Pz92QHdANXZIcIhg8=";

    ldflags = caddy.ldflags ++ ["-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"];
  }
