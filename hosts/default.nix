{ system, specialArgs, nixpkgs, impermanence }:
let
  hardware = import ../hardware;
  mkHost = config: system: hw:
    let
      modules = [
        impermanence.nixosModules.impermanence
        ../lib
        ({ ... }: { networking.hostName = nixpkgs.lib.strings.removeSuffix ".nix" (builtins.baseNameOf config); })
        config
      ];
    in
    {
      inherit system;
      nixosConfig = nixpkgs.lib.nixosSystem {
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
