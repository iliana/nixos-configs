{
  craneLib,
  openssl,
  oxide-cli,
  pkg-config,
  rust-bin,
}: let
  commonArgs = {
    pname = "oxide";
    version = "0.1.0";
    src = oxide-cli;
    cargoExtraArgs = "--package oxide";
    doCheck = false;

    buildInputs = [pkg-config openssl];
    nativeBuildInputs = [rust-bin.rust_1_69_0];
  };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
      patches = [./oxide-git-version.patch];
    })
