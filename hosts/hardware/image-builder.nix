{
  config,
  diskPartitionScript,
  firmwareMountPoint,
  preMountHook ? "",
  closureInfo,
  e2fsprogs,
  lib,
  nix,
  runCommand,
  stdenv,
  util-linux,
  vmTools,
  zstd,
}: let
  binPath = lib.makeBinPath (
    stdenv.initialPath
    ++ [
      config.system.build.nixos-install
      e2fsprogs
      nix
      util-linux
    ]
  );
  closureInfo' = closureInfo {
    rootPaths = [config.system.build.toplevel];
  };
in
  vmTools.runInLinuxVM (runCommand "${config.networking.hostName}-raw-image"
    {
      preVM = ''
        export PATH=${binPath}
        chmod 0755 "$TMPDIR"

        root="$TMPDIR/root"
        mkdir -p "$root" "$out"
        diskImage="$out/nixos.img"
        truncate -s 2G "$diskImage"

        export NIX_STATE_DIR=$TMPDIR/state
        nix-store --load-db <"${closureInfo'}/registration"
        nixos-install --root "$root" --system "${config.system.build.toplevel}" \
          --no-bootloader --no-root-passwd --no-channel-copy --substituters ""
        rm -rf "$root/nix/persist"

        ${diskPartitionScript}
        offsetBytes=$(( $(partx "$diskImage" -n 2 -g -o START) * 512 ))
        sizeKB=$(( ( $(partx "$diskImage" -n 2 -g -o SECTORS) * 512 ) / 1024))K
        mkfs.ext4 -d "$root/nix" -L nixos -T default -i 8192 \
          "$diskImage" -E offset="$offsetBytes" "$sizeKB"
      '';
      memSize = 1024;
      nativeBuildInputs = [
        config.system.build.nixos-enter
        e2fsprogs
        util-linux
      ];
      postVM = ''
        ${zstd}/bin/zstd -T$NIX_BUILD_CORES --rm $out/nixos.img -o $out/"${config.networking.hostName}".img.zst
      '';
    }
    ''
      root="$TMPDIR/root"

      mkdir -p "$root"/{etc,nix,var} "$root/${firmwareMountPoint}"
      touch "$root/etc/NIXOS"
      ${preMountHook}
      mount /dev/vda1 "$root/${firmwareMountPoint}"
      mount /dev/vda2 "$root/nix"

      # fix permissions
      nixos-enter --root "$root" -- chown -R root:root /nix/{store,var}
      # install bootloader
      NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root "$root" -- /nix/var/nix/profiles/system/bin/switch-to-configuration boot

      umount /dev/vda{1,2}
      tune2fs -T now -c 0 -i 0 /dev/vda2
    '')
