{ lib, ... }: {
  iliana.testMode = lib.mkForce true;
  services.tailscale.enable = false;
  system.activationScripts.createPersistentStorageDirs.deps = [ "testHwMakePersistDir" ];
  system.activationScripts.testHwMakePersistDir.text = "mkdir /nix/persist";
  zramSwap.enable = true;
}
