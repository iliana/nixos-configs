{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  cfg = config.iliana.hardware;
  configTxt = pkgs.writeText "config.txt" ''
    [pi3]
    kernel=u-boot-rpi3.bin

    [pi4]
    kernel=u-boot-rpi4.bin
    enable_gic=1
    armstub=armstub8-gic.bin

    # Otherwise the resolution will be weird in most cases, compared to
    # what the pi3 firmware does by default.
    disable_overscan=1

    # Supported in newer board revisions
    arm_boost=1

    [all]
    # Boot in 64-bit mode.
    arm_64bit=1

    # U-Boot needs this to work, regardless of whether UART is actually used or not.
    # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
    # a requirement in the future.
    enable_uart=1

    # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
    # when attempting to show low-voltage or overtemperature warnings.
    avoid_warnings=1

    ${cfg.configTxt}
  '';
  firmware = pkgs.runCommandLocal "firmware" {} ''
    mkdir $out
    ln -s ${configTxt} $out/config.txt
    ln -s ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin $out/
    ln -s ${pkgs.raspberrypifw}/share/raspberrypi/boot/{bootcode.bin,fixup*.dat,start*.elf,bcm2711-*.dtb} $out/
    ln -s ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin $out/u-boot-rpi3.bin
    ln -s ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin $out/u-boot-rpi4.bin
  '';

  extlinuxBuilder = import (modulesPath + "/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix") {inherit pkgs;};
  extlinuxBuilderArgs = "-d /nix/boot -g 20 -t 3";
in {
  options.iliana.hardware = {
    configTxt = lib.mkOption {
      default = "";
      type = lib.types.lines;
    };
  };

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
      options = ["defaults"];
      autoResize = true;
      neededForBoot = true;
    };
    fileSystems."/boot/firmware" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "vfat";
      options = ["defaults"];
    };
    iliana.backup.dirs = ["/" "/nix/persist"];

    system.activationScripts.updateFirmwarePartition.text = ''
      ${pkgs.rsync}/bin/rsync \
        --recursive --copy-links --times --checksum --delete \
        ${firmware}/ /boot/firmware/
    '';

    boot.loader.generic-extlinux-compatible.populateCmd = "${extlinuxBuilder} ${extlinuxBuilderArgs}";
    boot.loader.grub.enable = false;
    system.boot.loader.id = "generic-extlinux-compatible";
    system.build.installBootLoader = "${extlinuxBuilder} ${extlinuxBuilderArgs} -c";

    # Adapted from `boot.growPartition`, which only works if the partition you
    # want to grow is `/`.
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.util-linux}/bin/lsblk
      copy_bin_and_libs ${pkgs.util-linux}/bin/sfdisk
    '';
    boot.initrd.postDeviceCommands = ''
      rootDevice=/dev/disk/by-label/nixos
      if waitDevice "$rootDevice"; then
        echo ",+," | sfdisk -N2 --no-reread "/dev/$(lsblk -ndo pkname "$rootDevice")"
        udevadm settle
      fi
    '';

    boot.kernelParams = ["console=tty0"];
    services.fstrim.enable = true;
    zramSwap.enable = true;

    iliana.tailscale.authKeyFile = "/boot/firmware/tailscale.key";

    system.build.image = pkgs.callPackage ./image-builder.nix {
      inherit config;
      diskPartitionScript = ''
        # type=b is 'W95 FAT32', type=83 is 'Linux'.
        # The "bootable" partition is where u-boot will look file for the bootloader
        # information (dtbs, extlinux.conf file).
        ${pkgs.util-linux}/bin/sfdisk "$diskImage" <<EOF
          label: dos
          start=8M, size=64M, type=b
          start=72M, type=83, bootable
        EOF
      '';
      firmwareMountPoint = "/boot/firmware";
      preMountHook = ''
        ${pkgs.dosfstools}/bin/mkfs.vfat -n NIXOS_SD /dev/vda1
      '';
    };
  };
}
