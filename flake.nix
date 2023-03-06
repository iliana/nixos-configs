{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = profiles: hostname: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = profiles ++ [
          ./systems/${hostname}.nix
          ({ config, ... }: { networking.hostName = hostname; })
        ];
      };
      server = hostname: system [ ./profiles/guest-server.nix ] hostname;
    in
    {
      nixosConfigurations = {
        hydrangea = server "hydrangea";
      };
    };
}
