{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      hydrangea = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./systems/hydrangea.nix ];
      };
    };
  };
}
