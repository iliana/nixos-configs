{ pkgs, lib, inputs, ... }: {
  # Ensure e.g. `nix run nixpkgs#hello` uses the same revision as the flake input we already run.
  nix.registry = lib.attrsets.genAttrs
    [ "nixpkgs" "nixpkgs-unstable" ]
    (input: {
      to = {
        inherit (inputs."${input}") lastModified narHash rev;
        owner = "NixOS";
        repo = "nixpkgs";
        type = "github";
      };
    });

  nix.settings.flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON { flakes = [ ]; version = 2; });

  system.systemBuilderCommands = ''
    awk NF <<<"${inputs.self.rev or ""}" >$out/iliana-rev
  '';
}
