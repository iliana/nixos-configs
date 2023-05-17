{
  craneLib,
  emojos-dot-in,
  openssl,
  pkg-config,
}:
craneLib.buildPackage {
  pname = "emojos-dot-in";
  version = "2.0.0";
  src = emojos-dot-in;
  buildInputs = [pkg-config openssl];
}
