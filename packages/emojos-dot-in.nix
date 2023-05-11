{
  craneLib,
  fetchFromGitHub,
  openssl,
  pkg-config,
}:
craneLib.buildPackage {
  pname = "emojos-dot-in";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "iliana";
    repo = "emojos.in";
    rev = "e0152d4bb55ea59e9d58cccfcdcf51a7b9ce4f86";
    sha256 = "sha256-l+17dLSQM9lI1tJqjP5j957hY9oIDyeDBIYk2pbikFM=";
  };

  buildInputs = [pkg-config openssl];
}
