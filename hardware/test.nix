{ lib, ... }: {
  iliana.testMode = lib.mkForce true;
  services.tailscale.enable = false;
  zramSwap.enable = true;

  # Work around /var/lib/nixos and /var/log being "required for boot".
  #
  # These filesystems need to be mounted during the initrd, but in the nixos-
  # lib.runTest environment (aka config.system.build.vm), a blank disk is passed
  # as /dev/vda and formatted as an empty ext4 filesystem prior to mounts, and
  # source devices for mounts must exist or the initrd will fail.
  #
  # This script instead formats /dev/vda as a filesystem with the source devices
  # of the "required for boot" bind mounts. (It technically gets merged into
  # the script _before_ the built-in disk formatter, but that one has a check to
  # ensure there's no disk label present.)
  boot.initrd.postDeviceCommands = ''
    mkdir -p $targetRoot/nix/persist/var/lib/nixos
    mkdir -p $targetRoot/nix/persist/var/log
    mke2fs -t ext4 -d $targetRoot /dev/vda
    rm -rf $targetRoot
  '';
}
