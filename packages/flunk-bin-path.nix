{
  nixStatic,
  runCommand,
  writeScript,
}: let
  flunkBin = writeScript "flunk" ''
    #!/usr/bin/env bash
    exec "$(dirname "$(realpath -s "''${BASH_SOURCE[0]}")")"/nix \
      --extra-experimental-features nix-command \
      shell ~/.local/share/nix/root/nix/var/nix/profiles/system --command "$@"
  '';
in
  runCommand "flunk-bin-path" {} ''
    mkdir $out
    cp ${flunkBin} $out/flunk
    cp -a ${nixStatic}/bin/* $out/
  ''
