{
  config,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["defaults" "size=50%" "mode=755"];
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["defaults" "discard"];
    autoResize = true;
    neededForBoot = true;
  };
  fileSystems."/efi" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = ["defaults"];
  };
  iliana.backup.dirs = ["/" "/nix/persist"];

  boot.loader.grub = {
    efiInstallAsRemovable = true;
    efiSupport = true;
    extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input console serial
      terminal_output console serial
    '';
    # We use mirroredBoots with one boot partition so that we can set `path`.
    mirroredBoots = [
      {
        devices = ["nodev"];
        efiSysMountPoint = "/efi";
        path = "/nix/persist/boot";
      }
    ];
  };

  # Adapted from `boot.growPartition`, which only works if the partition you
  # want to grow is `/`.
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.gptfdisk}/bin/sgdisk
    copy_bin_and_libs ${pkgs.util-linux}/bin/lsblk
  '';
  boot.initrd.postDeviceCommands = ''
    rootDevice=/dev/disk/by-label/nixos
    if waitDevice "$rootDevice"; then
      sgdisk -e -d 2 -N 2 "/dev/$(lsblk -ndo pkname "$rootDevice")"
      udevadm settle
    fi
  '';

  boot.kernelParams = ["console=ttyS0,115200n8"];
  boot.loader.timeout = 0;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  system.build.image = pkgs.callPackage ./image-builder.nix {
    inherit config;
    diskPartitionScript = ''
      ${pkgs.gptfdisk}/bin/sgdisk -n 1:0:+1M -t 1:ef00 -N 2 -p "$diskImage"
    '';
    firmwareMountPoint = "/efi";
    preMountHook = ''
      ${pkgs.dosfstools}/bin/mkfs.vfat -F 12 -n ESP /dev/vda1
    '';
  };
}
