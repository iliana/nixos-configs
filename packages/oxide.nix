{
  craneLib,
  openssl,
  oxide-cli,
  pkg-config,
}:
craneLib.buildPackage {
  pname = "oxide";
  version = "0.1.0";
  src = oxide-cli;
  cargoArtifacts = null;
  cargoExtraArgs = "--package oxide";
  doCheck = false;
  buildInputs = [pkg-config openssl];
  patches = [./oxide-git-version.patch];
}
