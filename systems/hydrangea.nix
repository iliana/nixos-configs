{ config, pkgs, ... }: {
  networking.hostName = "hydrangea";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  environment.systemPackages = [ pkgs.openssl ];

  system.stateVersion = "22.11";
}
