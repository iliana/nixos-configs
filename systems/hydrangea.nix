{ config, ... }: {
  imports = [
    ../hardware/pancake-v1.nix
    ../profiles/base.nix
    ../profiles/tailscale.nix
  ];

  system.stateVersion = "22.11";
}
