{ pkgs, craneLib, fetchFromGitHub, ... }: craneLib.buildPackage {
  src = fetchFromGitHub {
    owner = "iliana";
    repo = "emojos.in";
    rev = "0005b3bd5608c5c892a96a4ca6e7411c2e114f67";
    sha256 = "sha256-/ILUJ1N0QFsuwnFKZfAyyDoa94rzB2b/N/urmNG6ZAE=";
  };

  buildInputs = [ pkgs.pkg-config pkgs.openssl ];
}
