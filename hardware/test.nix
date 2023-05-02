{ lib, ... }: {
  iliana.testMode = lib.mkForce true;
  services.tailscale.enable = false;
  zramSwap.enable = true;
}
