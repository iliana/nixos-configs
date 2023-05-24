{
  config,
  lib,
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

  system.build.image = let
    binPath = lib.makeBinPath ([
        config.system.build.nixos-install
        pkgs.e2fsprogs
        pkgs.gptfdisk
        pkgs.nix
        pkgs.util-linux
      ]
      ++ pkgs.stdenv.initialPath);
    closureInfo = pkgs.closureInfo {
      rootPaths = [config.system.build.toplevel];
    };
  in
    pkgs.vmTools.runInLinuxVM (pkgs.runCommand "raw-efi-image"
      {
        preVM = ''
          export PATH=${binPath}
          chmod 0755 "$TMPDIR"

          root="$TMPDIR/root"
          mkdir -p "$root" "$out"
          diskImage="$out/nixos.img"
          truncate -s 2G "$diskImage"

          export NIX_STATE_DIR=$TMPDIR/state
          nix-store --load-db <"${closureInfo}/registration"
          nixos-install --root "$root" --system "${config.system.build.toplevel}" \
            --no-bootloader --no-root-passwd --no-channel-copy --substituters ""
          rm -rf "$root/nix/persist"

          sgdisk -n 1:0:+1M -t 1:ef00 -N 2 -p "$diskImage"
          offsetBytes=$(( $(partx "$diskImage" -n 2 -g -o START) * 512 ))
          sizeKB=$(( ( $(partx "$diskImage" -n 2 -g -o SECTORS) * 512 ) / 1024))K
          mkfs.ext4 -d "$root/nix" -L nixos -T default -i 8192 \
            "$diskImage" -E offset="$offsetBytes" "$sizeKB"
        '';
        memSize = 1024;
        nativeBuildInputs = [
          config.system.build.nixos-enter
          pkgs.dosfstools
          pkgs.e2fsprogs
          pkgs.util-linux
        ];
        postVM = ''
          ${pkgs.zstd}/bin/zstd -T$NIX_BUILD_CORES --rm $out/nixos.img
        '';
      }
      ''
        root="$TMPDIR/root"

        mkdir -p "$root"/{etc,efi,nix,var}
        touch "$root/etc/NIXOS"
        mkfs.vfat -F 12 -n ESP /dev/vda1
        mount /dev/vda1 "$root/efi"
        mount /dev/vda2 "$root/nix"

        # fix permissions
        nixos-enter --root "$root" -- chown -R root:root /nix/{store,var}
        # install bootloader
        NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root "$root" -- /nix/var/nix/profiles/system/bin/switch-to-configuration boot

        umount /dev/vda{1,2}
        tune2fs -T now -c 0 -i 0 /dev/vda2
      '');
}
