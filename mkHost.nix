{
  overlay,
  sources,
}: hostName: cfg:
import (sources.nixpkgs + "/nixos/lib/eval-config.nix") {
  modules = [
    (sources.impermanence + "/nixos.nix")
    ./modules/base
    ({
      config,
      lib,
      pkgs,
      test,
      ...
    }: {
      _module.args = {
        inherit sources;
        helpers = import ./helpers.nix {inherit config lib pkgs test;};
        test = config.virtualisation ? "test";
      };
      networking.hostName = hostName;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      nixpkgs.overlays = [overlay];
    })
    cfg
  ];
}
