{
  craneLib,
  emojos-dot-in,
  openssl,
  pkg-config,
  rust-bin,
}:
craneLib.buildPackage {
  pname = "emojos-dot-in";
  version = "2.0.0";
  src = emojos-dot-in;

  buildInputs = [pkg-config openssl];
  nativeBuildInputs = [rust-bin.stable."1.69.0".minimal];
}
