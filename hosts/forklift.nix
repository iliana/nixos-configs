{ config, pkgs, lib, ... }: {
  networking.hostName = "forklift";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  # disable nightly nix store garbage collection
  nix.gc.automatic = lib.mkForce false;

  system.stateVersion = "22.11";
}
