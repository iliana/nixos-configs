{ config, lib, pkgs, modulesPath, ... }: {
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "discard" ];
    autoResize = true;
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  boot.growPartition = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  system.build.rawEfiImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit lib config pkgs;
    diskSize = 6 * 1024;
    format = "raw";
    partitionTableType = "efi";
  };
}
