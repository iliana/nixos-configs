{ pkgs, craneLib, fetchFromGitHub, ... }: craneLib.buildPackage {
  src = fetchFromGitHub {
    owner = "iliana";
    repo = "emojos.in";
    rev = "92c717d9fd96870d18addd8a3980d6cb72c3c7f4";
    sha256 = "sha256-VcV7kXWzj94GE/6AepVkfpcpAIH7kRTotZOiQu13YBE=";
  };

  buildInputs = [ pkgs.pkg-config pkgs.openssl ];
}
