{ config, pkgs, ... }: {
  networking.hostName = "forklift";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  iliana.persist.directories = [
    {
      directory = "/home/iliana";
      user = "iliana";
      group = "iliana";
    }
  ];

  system.stateVersion = "22.11";
}
