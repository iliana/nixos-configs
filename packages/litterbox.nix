{
  stdenv,
  fetchzip,
  libressl,
  pkg-config,
  sqlite,
}:
stdenv.mkDerivation rec {
  pname = "litterbox";
  version = "1.9";

  src = fetchzip {
    url = "https://git.causal.agency/litterbox/snapshot/litterbox-${version}.tar.gz";
    sha256 = "sha256-w4qW7J5CKm+hXHsNNbl9roBslHD14JOe0Nj5WntETqM=";
  };

  buildInputs = [libressl sqlite];

  nativeBuildInputs = [pkg-config];

  buildFlags = ["all"];

  makeFlags = [
    "PREFIX=$(out)"
  ];
}
