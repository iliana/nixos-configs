{ config, lib, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "defaults" "size=50%" "mode=755" ];
    neededForBoot = true;
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "defaults" "discard" ];
    autoResize = true;
    neededForBoot = true;
  };
  fileSystems."/efi" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [ "defaults" ];
  };

  environment.persistence."/nix/persist" = with config.iliana.persist; {
    inherit directories files;
    hideMounts = true;
  };

  boot.loader.grub = {
    efiInstallAsRemovable = true;
    efiSupport = true;
    extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input --append serial
      terminal_output --append serial
    '';
    # We use mirroredBoots with one boot partition so that we can set `path`.
    mirroredBoots = [{
      devices = [ "nodev" ];
      efiSysMountPoint = "/efi";
      path = "/nix/persist/boot";
    }];
  };

  # Adapted from `boot.growPartition`, which only works if the partition you
  # want to grow is `/`.
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.gptfdisk}/bin/sgdisk
    copy_bin_and_libs ${pkgs.util-linux}/bin/lsblk
  '';
  boot.initrd.postDeviceCommands = ''
    rootDevice="${config.fileSystems."/nix".device}"
    if waitDevice "$rootDevice"; then
      sgdisk -e -d 2 -N 2 "/dev/$(lsblk -ndo pkname "$rootDevice")"
      udevadm settle
    fi
  '';

  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  boot.loader.timeout = 0;
  services.fstrim.enable = true;
  zramSwap.enable = true;

  system.build.image =
    let
      closureInfo = pkgs.closureInfo {
        rootPaths = [ config.system.build.toplevel ];
      };
      flakeDotNix = pkgs.writeText "flake.nix" ''
        {
          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
            iliana.url = "github:iliana/nixos-configs";
            iliana.inputs.nixpkgs.follows = "nixpkgs";
          };

          outputs = { iliana, ... }: iliana;
        }
      '';
    in
    pkgs.vmTools.runInLinuxVM (pkgs.runCommand "raw-efi-image"
      {
        preVM = ''
          mkdir "$out"
          diskImage="$out/nixos.img"
          truncate -s 2G "$diskImage"
        '';
        memSize = 1024;
        nativeBuildInputs = with pkgs; [
          config.system.build.nixos-enter
          config.system.build.nixos-install
          dosfstools
          e2fsprogs
          gptfdisk
          nix
          util-linux
        ];
      } ''
      sgdisk -n 1:0:+1M -t 1:ef00 -N 2 /dev/vda -p
      root="$TMPDIR/root"

      mkfs.vfat -F 12 -n ESP /dev/vda1
      mkdir -p "$root/efi"
      mount /dev/vda1 "$root/efi"

      mkfs.ext4 -L nixos -T default -i 8192 /dev/vda2
      mkdir -p "$root/nix"
      mount /dev/vda2 "$root/nix"
      # ensure these get reasonable default permissions
      mkdir -p "$root"/nix/persist/{boot/grub,var/lib}

      export NIX_STATE_DIR=$TMPDIR/state
      nix-store --load-db <"${closureInfo}/registration"
      nixos-install --root "$root" \
        --system "${config.system.build.toplevel}" \
        --no-root-passwd --no-channel-copy --substituters ""
      nixos-enter --root "$root" -- chown -R root:root /nix

      cp ${flakeDotNix} "$root/nix/persist/etc/nixos/flake.nix"

      umount "$root"/{efi,nix}
      tune2fs -T now -c 0 -i 0 /dev/vda2
    '');
}
