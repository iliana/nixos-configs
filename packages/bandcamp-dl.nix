{
  fetchFromGitHub,
  python3,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "bandcamp-dl";
  version = "unstable-2023-04-09";

  src = fetchFromGitHub {
    owner = "iliana";
    repo = "bandcamp-dl";
    rev = "5b434a8401f51397e4cc7c9bce87f6f137d3ec90";
    hash = "sha256-u+I/D/MNUDTQf+V2R6zJxNbIKPOuO2Qc2ZXw26q2Es8=";
  };

  buildInputs = [python3];

  installPhase = ''
    install -D -m 0755 bandcamp-dl.py $out/bin/bandcamp-dl
  '';
}
