{ config, pkgs, ... }: {
  networking.hostName = "forklift";

  imports = [
    ../hardware/virt-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  environment.persistence."/nix/persist".users.iliana.directories = [ "." ];

  system.stateVersion = "22.11";
}
