{ system, inputs, specialArgs }:
let
  hardware = import ../hardware;
  lib = inputs.nixpkgs.lib;
  mkHost = config: system: hw:
    let
      modules = [
        inputs.impermanence.nixosModules.impermanence
        ../lib
        ({ ... }: { networking.hostName = lib.strings.removeSuffix ".nix" (builtins.baseNameOf config); })
        config
      ];
    in
    {
      nixosConfig = lib.nixosSystem {
        inherit system;
        modules = modules ++ [ hw ];
        specialArgs = specialArgs system;
      };
      testNode = { ... }: {
        imports = modules ++ [ hardware.test ];
      };
    };
in
{
  hydrangea = mkHost ./hydrangea.nix system.x86_64-linux hardware.virt-v1;
  megaera = mkHost ./megaera.nix system.x86_64-linux hardware.virt-v1;
}
