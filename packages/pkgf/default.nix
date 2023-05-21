{
  craneLib,
  openssl,
  pkg-config,
}:
craneLib.buildPackage {
  pname = "pkgf";
  version = "0.1.0";
  src = ./.;
  buildInputs = [pkg-config openssl];
}
