{ config, pkgs, ... }: {
  networking.hostName = "forklift";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  system.stateVersion = "22.11";
}
