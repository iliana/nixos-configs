{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

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
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.timeout = 0;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  system.build.rawEfiImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit lib config pkgs;
    diskSize = 8 * 1024;
    format = "raw";
    partitionTableType = "efi";
  };
}
