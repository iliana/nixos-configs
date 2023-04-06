{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";

    dotfiles.url = "github:iliana/dotfiles?dir=.config/dotfiles&submodule=1";
  };

  outputs = { nixpkgs, nixpkgs-unstable, crane, impermanence, ... }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [ "x86_64-linux" ];

      packages = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          craneLib = crane.lib.${system};
        in
        {
          emojos-dot-in = pkgs.callPackage ./packages/emojos-dot-in.nix { inherit craneLib; };
        });

      hosts = system:
        let
          pkgs-unstable = import nixpkgs-unstable { inherit system; };
        in
        hosts: lib.attrsets.genAttrs hosts (host: lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${host}.nix
            impermanence.nixosModules.impermanence
          ];
          specialArgs = {
            inherit inputs pkgs-unstable;
            pkgs-iliana = packages.${system};
          };
        });
    in
    {
      inherit packages;
      nixosConfigurations = hosts "x86_64-linux" [
        "hydrangea"
      ];
    };
}
