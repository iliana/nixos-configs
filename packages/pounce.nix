# https://github.com/NixOS/nixpkgs/pull/239854
{
  pounce,
  curl,
  sqlite,
}:
pounce.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [curl sqlite];
  configureFlags = (old.configureFlags or []) ++ ["--enable-notify" "--enable-palaver"];
})
