{ config, pkgs, lib, ... }: {
  networking.hostName = "forklift";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  users.users.builduser = {
    isSystemUser = true;
    group = "builduser";
  };
  users.groups.builduser = { };

  # disable nightly nix store garbage collection
  nix.gc.automatic = lib.mkForce false;

  system.stateVersion = "22.11";
}
