{
  craneLib,
  openssl,
  pkg-config,
  rust-bin,
}:
craneLib.buildPackage {
  pname = "pkgf";
  version = "0.1.0";
  src = ./.;
  buildInputs = [pkg-config openssl];
  nativeBuildInputs = [rust-bin.stable."1.69.0".minimal];
}
