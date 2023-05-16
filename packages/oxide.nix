{
  craneLib,
  openssl,
  oxide-cli,
  pkg-config,
  rust-bin,
  stdenv,
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
  cargoArtifacts = craneLib.buildDepsOnly (commonArgs
    // {
      # https://crane.dev/faq/patching-cargo-lock.html
      cargoVendorDir = craneLib.vendorCargoDeps {
        cargoLock = stdenv.mkDerivation {
          name = "Cargo.lock-patched";
          src = oxide-cli;
          patches = [./oxide-progenitor.patch];
          installPhase = ''
            runHook preInstall
            cp Cargo.lock $out
            runHook postInstall
          '';
        };
      };
    });
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
      patches = [./oxide-progenitor.patch ./oxide-git-version.patch];
    })
