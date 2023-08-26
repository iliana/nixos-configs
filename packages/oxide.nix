{
  craneLib,
  fetchFromGitHub,
  openssl,
  pkg-config,
}:
craneLib.buildPackage {
  pname = "oxide";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "oxidecomputer";
    repo = "oxide.rs";
    rev = "v0.1.0-beta.3";
    hash = "sha256-/HunH3ZVuPyKRHQfzY0g2xok5VfosG7Mg5skgU0oDfg=";
  };

  cargoArtifacts = null;
  cargoExtraArgs = "--package oxide";
  doCheck = false;

  env = {OPENSSL_NO_VENDOR = "";};
  buildInputs = [pkg-config openssl];

  patches = [./oxide-git-version.patch];
}
