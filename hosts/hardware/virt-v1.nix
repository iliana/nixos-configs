{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  cfg = config.iliana.hardware;
  enableBiosBoot = cfg.biosBootDevice != null;
in {
  options.iliana.hardware = {
    biosBootDevice = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
    };

    useSerialConsole = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
  };

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  config = {
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
          devices = [
            (
              if enableBiosBoot
              then cfg.biosBootDevice
              else "nodev"
            )
          ];
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

    boot.kernelParams =
      if cfg.useSerialConsole
      then ["console=ttyS0,115200n8"]
      else ["console=tty1"];
    boot.loader.timeout = 0;
    services.fstrim.enable = true;
    zramSwap.enable = true;

    system.build.image = pkgs.callPackage ./image-builder.nix {
      inherit config;
      diskPartitionScript = ''
        ${pkgs.gptfdisk}/bin/sgdisk \
          ${lib.optionalString enableBiosBoot "--new=128:0:+1M --typecode=128:ef02"} \
          --new=1:0:+1M --typecode=1:ef00 \
          --largest-new=2 \
          --print "$diskImage"
      '';
      firmwareMountPoint = "/efi";
      preMountHook = ''
        ${pkgs.dosfstools}/bin/mkfs.vfat -F 12 -n ESP /dev/vda1
      '';
    };
  };
}
